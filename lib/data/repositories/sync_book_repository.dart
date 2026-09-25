import '../../core/database/hive_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/network_sync_service.dart';
import '../../domain/repositories/book_repository.dart';
import '../models/book_model.dart';

/// 로컬 Hive 초고속 반응 + Firebase 실시간 자동 클라우드 백업 + 오프라인 알림을 통합한 BookRepository
class SyncBookRepository implements BookRepository {
  final HiveService _hiveService;
  final FirebaseService _firebaseService;
  final NetworkSyncService _networkSyncService;

  SyncBookRepository(
    this._hiveService,
    this._firebaseService,
    this._networkSyncService,
  );

  @override
  Future<List<Book>> getAllBooks() async {
    final box = _hiveService.bookBox;
    final books = box.values.toList();
    books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return books;
  }

  @override
  Future<Book?> getBookById(String id) async {
    final box = _hiveService.bookBox;
    return box.get(id);
  }

  @override
  Future<void> addBook(Book book) async {
    // 1. 로컬에 즉시 저장 (0ms 지연없는 사용자 반응)
    await _hiveService.bookBox.put(book.id, book);

    // 2. 클라우드에 비동기 자동 저장
    _firebaseService.saveBook(book);

    // 3. 오프라인 상태일 경우 사용자에게 친절한 안내 팝업/스낵바 노출
    if (!_networkSyncService.isOnline) {
      _networkSyncService.notifyOfflineSaved(itemType: '도서');
    }
  }

  @override
  Future<void> updateBook(Book book) async {
    // 1. 로컬에 즉시 저장
    await _hiveService.bookBox.put(book.id, book);

    // 2. 클라우드 비동기 업데이트
    _firebaseService.saveBook(book);

    // 3. 오프라인 시 안내 알림
    if (!_networkSyncService.isOnline) {
      _networkSyncService.notifyOfflineSaved(itemType: '도서');
    }
  }

  @override
  Future<void> deleteBook(String id) async {
    // 1. 로컬 책 및 연관 노트 삭제
    final bookBox = _hiveService.bookBox;
    await bookBox.delete(id);

    final noteBox = _hiveService.noteBox;
    final keysToDelete = noteBox.values
        .where((note) => note.bookId == id)
        .map((note) => note.id)
        .toList();

    if (keysToDelete.isNotEmpty) {
      await noteBox.deleteAll(keysToDelete);
    }

    // 2. 클라우드에서도 책 및 연관 노트 삭제
    _firebaseService.deleteBook(id);
    _firebaseService.deleteNotesByBookId(id);

    // 3. 오프라인 시 안내 알림
    if (!_networkSyncService.isOnline) {
      _networkSyncService.notifyOfflineSaved(itemType: '도서');
    }
  }

  @override
  Stream<List<Book>> watchAllBooks() async* {
    final box = _hiveService.bookBox;

    List<Book> getSortedBooks() {
      final books = box.values.toList();
      books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return books;
    }

    yield getSortedBooks();

    await for (final _ in box.watch()) {
      yield getSortedBooks();
    }
  }
}
