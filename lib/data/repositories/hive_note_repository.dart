import '../../core/database/hive_service.dart';
import '../../data/models/note_model.dart';
import '../../domain/repositories/note_repository.dart';

/// Hive Box를 이용한 NoteRepository 구현체
class HiveNoteRepository implements NoteRepository {
  final HiveService _hiveService;

  HiveNoteRepository(this._hiveService);

  @override
  Future<List<Note>> getAllNotes() async {
    final notes = _hiveService.noteBox.values.toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  @override
  Future<List<Note>> getNotesByBookId(String bookId) async {
    final notes = _hiveService.noteBox.values
        .where((note) => note.bookId == bookId)
        .toList();

    // 페이지 순 정렬 후, 동일 페이지는 생성일 순 정렬
    notes.sort((a, b) {
      final pageComparison = a.pageNumber.compareTo(b.pageNumber);
      if (pageComparison != 0) return pageComparison;
      return a.createdAt.compareTo(b.createdAt);
    });

    return notes;
  }

  @override
  Future<Note?> getNoteById(String id) async {
    return _hiveService.noteBox.get(id);
  }

  @override
  Future<void> addNote(Note note) async {
    await _hiveService.noteBox.put(note.id, note);
  }

  @override
  Future<void> updateNote(Note note) async {
    await _hiveService.noteBox.put(note.id, note);
  }

  @override
  Future<void> deleteNote(String id) async {
    await _hiveService.noteBox.delete(id);
  }

  @override
  Future<void> deleteNotesByBookId(String bookId) async {
    final keysToDelete = _hiveService.noteBox.values
        .where((note) => note.bookId == bookId)
        .map((note) => note.id)
        .toList();

    await _hiveService.noteBox.deleteAll(keysToDelete);
  }

  @override
  Stream<List<Note>> watchAllNotes() async* {
    yield await getAllNotes();
    await for (final _ in _hiveService.noteBox.watch()) {
      yield await getAllNotes();
    }
  }

  @override
  Stream<List<Note>> watchNotesByBookId(String bookId) async* {
    yield await getNotesByBookId(bookId);
    await for (final _ in _hiveService.noteBox.watch()) {
      yield await getNotesByBookId(bookId);
    }
  }
}
