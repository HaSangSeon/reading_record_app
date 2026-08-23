import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_search_result.dart';

/// 무료 공개 도서 Open API(Google Books & Open Library)를 활용한 온라인 도서 검색 서비스
class BookSearchService {
  final http.Client _client;

  BookSearchService({http.Client? client}) : _client = client ?? http.Client();

  /// 키워드로 도서 검색 (Google Books 우선 검색 후 실패 시 Open Library 폴백)
  Future<List<BookSearchResult>> searchBooks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      // 1. Google Books API 시도
      final googleResults = await _searchGoogleBooks(trimmed);
      if (googleResults.isNotEmpty) return googleResults;
    } catch (_) {
      // Google Books 실패 시 조용히 폴백 시도
    }

    try {
      // 2. Open Library API 폴백
      return await _searchOpenLibrary(trimmed);
    } catch (e) {
      throw Exception('온라인 도서 검색 중 오류가 발생했습니다. 네트워크 연결을 확인해 주세요.');
    }
  }

  Future<List<BookSearchResult>> _searchGoogleBooks(String query) async {
    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(query)}&maxResults=20&printType=books',
    );

    final response =
        await _client.get(url).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return [];

      return items
          .map((item) =>
              BookSearchResult.fromGoogleBooks(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<BookSearchResult>> _searchOpenLibrary(String query) async {
    final url = Uri.parse(
      'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=20',
    );

    final response =
        await _client.get(url).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>?;
      if (docs == null || docs.isEmpty) return [];

      return docs
          .map((doc) =>
              BookSearchResult.fromOpenLibrary(doc as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
