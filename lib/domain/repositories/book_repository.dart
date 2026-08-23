import '../../data/models/book_model.dart';

/// 도서 데이터에 대한 CRUD 및 스트림 조회를 정의하는 추상 인터페이스
abstract class BookRepository {
  /// 모든 저장된 책 목록 조회
  Future<List<Book>> getAllBooks();

  /// 특정 ID의 책 조회
  Future<Book?> getBookById(String id);

  /// 새 책 추가
  Future<void> addBook(Book book);

  /// 기존 책 정보 업데이트
  Future<void> updateBook(Book book);

  /// 특정 책 삭제 (해당 책의 모든 독서 노트도 함께 삭제됨)
  Future<void> deleteBook(String id);

  /// 책 목록 변경사항 실시간 감지 스트림
  Stream<List<Book>> watchAllBooks();
}
