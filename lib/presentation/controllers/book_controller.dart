import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/book_model.dart';
import '../../domain/repositories/book_repository.dart';
import '../../providers/repository_providers.dart';

/// 도서 검색 키워드 상태 프로바이더
final bookSearchQueryProvider = StateProvider<String>((ref) => '');

/// 도서 목록 필터 상태 (전체 / 읽는 중 / 완독)
enum BookFilterType { all, reading, completed }

final bookFilterProvider =
    StateProvider<BookFilterType>((ref) => BookFilterType.all);

/// 검색 및 필터가 적용된 정제된 도서 목록 프로바이더
final filteredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(allBooksStreamProvider);
  final query = ref.watch(bookSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(bookFilterProvider);

  return booksAsync.whenData((books) {
    return books.where((book) {
      // 1. 필터 조건
      if (filter == BookFilterType.reading && book.isCompleted) return false;
      if (filter == BookFilterType.completed && !book.isCompleted) return false;

      // 2. 검색 조건
      if (query.isNotEmpty) {
        final matchesTitle = book.title.toLowerCase().contains(query);
        final matchesAuthor = book.author.toLowerCase().contains(query);
        final matchesPublisher = book.publisher.toLowerCase().contains(query);
        return matchesTitle || matchesAuthor || matchesPublisher;
      }

      return true;
    }).toList();
  });
});

/// 도서 CRUD 및 진행률 변경 컨트롤러
final bookControllerProvider =
    StateNotifierProvider<BookController, AsyncValue<void>>((ref) {
  final bookRepo = ref.watch(bookRepositoryProvider);
  return BookController(bookRepo);
});

class BookController extends StateNotifier<AsyncValue<void>> {
  final BookRepository _bookRepository;
  final Uuid _uuid = const Uuid();

  BookController(this._bookRepository) : super(const AsyncValue.data(null));

  /// 새 도서 등록
  Future<bool> addBook({
    required String title,
    required String author,
    String publisher = '',
    String? coverUrl,
    int totalPages = 0,
    int readPages = 0,
    bool isCompleted = false,
    double rating = 0.0,
    String memo = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final newBook = Book(
        id: _uuid.v4(),
        title: title.trim(),
        author: author.trim(),
        publisher: publisher.trim(),
        coverUrl: coverUrl?.trim().isEmpty == true ? null : coverUrl?.trim(),
        totalPages: totalPages,
        readPages: readPages,
        isCompleted: isCompleted || (totalPages > 0 && readPages >= totalPages),
        createdAt: now,
        completedAt: isCompleted ? now : null,
        rating: rating,
        memo: memo.trim(),
      );

      await _bookRepository.addBook(newBook);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 기존 도서 정보 수정
  Future<bool> updateBook(Book book) async {
    state = const AsyncValue.loading();
    try {
      await _bookRepository.updateBook(book);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 도서 삭제 (노트도 함께 삭제됨)
  Future<bool> deleteBook(String id) async {
    state = const AsyncValue.loading();
    try {
      await _bookRepository.deleteBook(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 독서 진행 페이지 수 업데이트
  Future<void> updateProgress(String bookId, int currentReadPages) async {
    final book = await _bookRepository.getBookById(bookId);
    if (book == null) return;

    final isNowCompleted =
        book.totalPages > 0 && currentReadPages >= book.totalPages;
    final updated = book.copyWith(
      readPages: currentReadPages,
      isCompleted: isNowCompleted,
      completedAt: isNowCompleted ? (book.completedAt ?? DateTime.now()) : null,
    );

    await _bookRepository.updateBook(updated);
  }

  /// 완독 여부 토글
  Future<void> toggleCompletion(String bookId) async {
    final book = await _bookRepository.getBookById(bookId);
    if (book == null) return;

    final willBeCompleted = !book.isCompleted;
    final updated = book.copyWith(
      isCompleted: willBeCompleted,
      readPages: willBeCompleted ? book.totalPages : book.readPages,
      completedAt: willBeCompleted ? DateTime.now() : null,
    );

    await _bookRepository.updateBook(updated);
  }
}
