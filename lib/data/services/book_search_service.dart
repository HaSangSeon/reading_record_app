import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_search_result.dart';

/// 카카오(최우선) / Google Books / Open Library 다중 소스 도서 검색 서비스
class BookSearchService {
  final http.Client _client;

  // 카카오 REST API 키 (국내 모든 도서 고화질 표지 완벽 지원)
  static const String _kakaoApiKey = 'da75a215c214be21979350a996e37fc6';

  BookSearchService({http.Client? client}) : _client = client ?? http.Client();

  /// 키워드로 도서 검색 (카카오 검색 우선 -> 실패 시 Google Books -> Open Library 폴백)
  Future<List<BookSearchResult>> searchBooks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // 1. 카카오 도서 검색 API 시도 (가장 정확하고 고화질 표지 100% 제공)
    try {
      final kakaoResults = await _searchKakaoBooks(trimmed);
      if (kakaoResults.isNotEmpty) return kakaoResults;
    } catch (_) {
      // 카카오 실패 시 폴백 진행
    }

    // 2. Google Books API 폴백 시도
    try {
      final googleResults = await _searchGoogleBooks(trimmed);
      if (googleResults.isNotEmpty) return googleResults;
    } catch (_) {
      // Google Books 실패 시 폴백 진행
    }

    // 3. Open Library API 폴백 시도
    try {
      return await _searchOpenLibrary(trimmed);
    } catch (e) {
      throw Exception('온라인 도서 검색 중 오류가 발생했습니다. 네트워크 연결을 확인해 주세요.');
    }
  }

  /// 카카오 도서 검색 API
  Future<List<BookSearchResult>> _searchKakaoBooks(String query) async {
    final url = Uri.parse(
      'https://dapi.kakao.com/v3/search/book?query=${Uri.encodeComponent(query)}&size=25',
    );

    final response = await _client
        .get(url, headers: {'Authorization': 'KakaoAK $_kakaoApiKey'})
        .timeout(const Duration(seconds: 7));

    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final documents = data['documents'] as List<dynamic>?;
      if (documents == null || documents.isEmpty) return [];

      return documents
          .map((doc) => BookSearchResult.fromKakao(doc as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Google Books API
  Future<List<BookSearchResult>> _searchGoogleBooks(String query) async {
    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=20&printType=books',
    );

    final response = await _client.get(url).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return [];

      return items
          .map(
            (item) =>
                BookSearchResult.fromGoogleBooks(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  /// Open Library API
  Future<List<BookSearchResult>> _searchOpenLibrary(String query) async {
    final url = Uri.parse(
      'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=20',
    );

    final response = await _client.get(url).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>?;
      if (docs == null || docs.isEmpty) return [];

      return docs
          .map(
            (doc) =>
                BookSearchResult.fromOpenLibrary(doc as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }
}
