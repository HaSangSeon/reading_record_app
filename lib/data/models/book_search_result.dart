import 'package:uuid/uuid.dart';
import 'book_model.dart';

/// 외부 Open API를 통해 검색된 도서 결과 DTO
class BookSearchResult {
  final String title;
  final String author;
  final String publisher;
  final String? coverUrl;
  final int totalPages;
  final String description;
  final String isbn;

  const BookSearchResult({
    required this.title,
    required this.author,
    this.publisher = '',
    this.coverUrl,
    this.totalPages = 0,
    this.description = '',
    this.isbn = '',
  });

  /// 검색 결과를 로컬 Book 엔티티로 변환
  Book toBook({
    int readPages = 0,
    bool isCompleted = false,
    double rating = 0.0,
    String memo = '',
  }) {
    return Book(
      id: const Uuid().v4(),
      title: title,
      author: author,
      publisher: publisher,
      coverUrl: coverUrl,
      totalPages: totalPages,
      readPages: readPages,
      isCompleted: isCompleted,
      createdAt: DateTime.now(),
      rating: rating,
      memo: memo.isNotEmpty ? memo : description,
    );
  }

  factory BookSearchResult.fromGoogleBooks(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>? ?? {};

    // 표지 이미지 URL 추출 (HTTPS 보안 프로토콜 강제 변환)
    String? coverUrl;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    if (imageLinks != null) {
      final rawUrl = imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'];
      if (rawUrl is String && rawUrl.isNotEmpty) {
        coverUrl = rawUrl.replaceFirst('http://', 'https://');
      }
    }

    // 저자 목록 파싱
    final authorsList = volumeInfo['authors'] as List<dynamic>?;
    final author = authorsList != null && authorsList.isNotEmpty
        ? authorsList.join(', ')
        : '저자 미상';

    // ISBN 파싱
    String isbn = '';
    final identifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
    if (identifiers != null && identifiers.isNotEmpty) {
      final first = identifiers.first as Map<String, dynamic>?;
      isbn = first?['identifier']?.toString() ?? '';
    }

    return BookSearchResult(
      title: volumeInfo['title']?.toString() ?? '제목 없음',
      author: author,
      publisher: volumeInfo['publisher']?.toString() ?? '',
      coverUrl: coverUrl,
      totalPages: (volumeInfo['pageCount'] as num?)?.toInt() ?? 0,
      description: volumeInfo['description']?.toString() ?? '',
      isbn: isbn,
    );
  }

  factory BookSearchResult.fromOpenLibrary(Map<String, dynamic> doc) {
    // 저자 파싱
    final authors = doc['author_name'] as List<dynamic>?;
    final author = authors != null && authors.isNotEmpty
        ? authors.join(', ')
        : '저자 미상';

    // 출판사 파싱
    final publishers = doc['publisher'] as List<dynamic>?;
    final publisher = publishers != null && publishers.isNotEmpty
        ? publishers.first.toString()
        : '';

    // 표지 이미지
    String? coverUrl;
    final coverId = doc['cover_i'];
    if (coverId != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    }

    // 페이지 수
    final pageCount = (doc['number_of_pages_median'] as num?)?.toInt() ?? 0;

    return BookSearchResult(
      title: doc['title']?.toString() ?? '제목 없음',
      author: author,
      publisher: publisher,
      coverUrl: coverUrl,
      totalPages: pageCount,
      description: '',
      isbn: (doc['isbn'] as List<dynamic>?)?.firstOrNull?.toString() ?? '',
    );
  }
}
