import '../../core/database/hive_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/network_sync_service.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

/// 로컬 Hive 초고속 반응 + Firebase 실시간 자동 클라우드 백업 + 오프라인 알림을 통합한 NoteRepository
class SyncNoteRepository implements NoteRepository {
  final HiveService _hiveService;
  final FirebaseService _firebaseService;
  final NetworkSyncService _networkSyncService;

  SyncNoteRepository(
    this._hiveService,
    this._firebaseService,
    this._networkSyncService,
  );

  @override
  Future<List<Note>> getAllNotes() async {
    final box = _hiveService.noteBox;
    final notes = box.values.toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  @override
  Future<List<Note>> getNotesByBookId(String bookId) async {
    final box = _hiveService.noteBox;
    final notes = box.values.where((n) => n.bookId == bookId).toList();
    notes.sort((a, b) {
      final pageCompare = a.pageNumber.compareTo(b.pageNumber);
      if (pageCompare != 0) return pageCompare;
      return b.createdAt.compareTo(a.createdAt);
    });
    return notes;
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final box = _hiveService.noteBox;
    return box.get(id);
  }

  @override
  Future<void> addNote(Note note) async {
    // 1. 로컬에 즉시 저장
    await _hiveService.noteBox.put(note.id, note);

    // 2. 클라우드에 비동기 자동 저장
    _firebaseService.saveNote(note);

    // 3. 오프라인 시 안내 알림
    if (!_networkSyncService.isOnline) {
      _networkSyncService.notifyOfflineSaved(itemType: '독서 메모');
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    // 1. 로컬에 즉시 저장
    await _hiveService.noteBox.put(note.id, note);

    // 2. 클라우드 비동기 업데이트
    _firebaseService.saveNote(note);

    // 3. 오프라인 시 안내 알림
    if (!_networkSyncService.isOnline) {
      _networkSyncService.notifyOfflineSaved(itemType: '독서 메모');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    // 1. 로컬 삭제
    await _hiveService.noteBox.delete(id);

    // 2. 클라우드 삭제
    _firebaseService.deleteNote(id);

    // 3. 오프라인 시 안내 알림
    if (!_networkSyncService.isOnline) {
      _networkSyncService.notifyOfflineSaved(itemType: '독서 메모');
    }
  }

  @override
  Future<void> deleteNotesByBookId(String bookId) async {
    final box = _hiveService.noteBox;
    final keysToDelete = box.values
        .where((n) => n.bookId == bookId)
        .map((n) => n.id)
        .toList();

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }

    _firebaseService.deleteNotesByBookId(bookId);

    if (!_networkSyncService.isOnline) {
      _networkSyncService.notifyOfflineSaved(itemType: '독서 메모');
    }
  }

  @override
  Stream<List<Note>> watchAllNotes() async* {
    final box = _hiveService.noteBox;

    List<Note> getSortedNotes() {
      final notes = box.values.toList();
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    }

    yield getSortedNotes();

    await for (final _ in box.watch()) {
      yield getSortedNotes();
    }
  }

  @override
  Stream<List<Note>> watchNotesByBookId(String bookId) async* {
    final box = _hiveService.noteBox;

    List<Note> getSortedNotesForBook() {
      final notes = box.values.where((n) => n.bookId == bookId).toList();
      notes.sort((a, b) {
        final pageCompare = a.pageNumber.compareTo(b.pageNumber);
        if (pageCompare != 0) return pageCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      return notes;
    }

    yield getSortedNotesForBook();

    await for (final _ in box.watch()) {
      yield getSortedNotesForBook();
    }
  }
}
