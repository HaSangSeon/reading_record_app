import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/book_search_result.dart';
import '../../data/services/book_search_service.dart';

/// BookSearchService 프로바이더
final bookSearchServiceProvider = Provider<BookSearchService>((ref) {
  return BookSearchService();
});

/// 온라인 도서 검색 상태 컨트롤러 프로바이더
final bookSearchControllerProvider = StateNotifierProvider.autoDispose<
    BookSearchController, AsyncValue<List<BookSearchResult>>>((ref) {
  final service = ref.watch(bookSearchServiceProvider);
  return BookSearchController(service);
});

class BookSearchController
    extends StateNotifier<AsyncValue<List<BookSearchResult>>> {
  final BookSearchService _service;

  BookSearchController(this._service)
      : super(const AsyncValue.data([]));

  /// 온라인 도서 검색 실행
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final results = await _service.searchBooks(trimmed);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 검색 결과 초기화
  void clear() {
    state = const AsyncValue.data([]);
  }
}
