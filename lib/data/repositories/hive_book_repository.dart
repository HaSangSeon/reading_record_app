import '../../core/database/hive_service.dart';
import '../../domain/repositories/book_repository.dart';
import '../models/book_model.dart';

/// Hive 로컬 데이터베이스를 활용한 BookRepository 구현체
class HiveBookRepository implements BookRepository {
  final HiveService _hiveService;

  HiveBookRepository(this._hiveService);

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
    final box = _hiveService.bookBox;
    await box.put(book.id, book);
  }

  @override
  Future<void> updateBook(Book book) async {
    final box = _hiveService.bookBox;
    await box.put(book.id, book);
  }

  @override
  Future<void> deleteBook(String id) async {
    // 1. 책 본체 삭제
    final bookBox = _hiveService.bookBox;
    await bookBox.delete(id);

    // 2. 데이터 무결성 보장을 위해 해당 책에 종속된 모든 노트도 함께 삭제
    final noteBox = _hiveService.noteBox;
    final keysToDelete = noteBox.values
        .where((note) => note.bookId == id)
        .map((note) => note.id)
        .toList();

    if (keysToDelete.isNotEmpty) {
      await noteBox.deleteAll(keysToDelete);
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

    // 1. 초기 데이터 즉시 방출
    yield getSortedBooks();

    // 2. 박스 변경 이벤트 감지 시 최신 데이터 방출
    await for (final _ in box.watch()) {
      yield getSortedBooks();
    }
  }
}
