import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'book_model.g.dart';

@HiveType(typeId: AppConstants.bookTypeId)
class Book extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String publisher;

  @HiveField(4)
  final String? coverUrl;

  @HiveField(5)
  final int totalPages;

  @HiveField(6)
  final int readPages;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
  final double rating;

  @HiveField(11)
  final String memo;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.publisher = '',
    this.coverUrl,
    this.totalPages = 0,
    this.readPages = 0,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.rating = 0.0,
    this.memo = '',
  });

  /// 독서 진행률 (0.0 ~ 1.0)
  double get progress {
    if (totalPages <= 0) return 0.0;
    return (readPages / totalPages).clamp(0.0, 1.0);
  }

  /// 독서 진행률 퍼센트 (0 ~ 100%)
  int get progressPercentage => (progress * 100).toInt();

  /// 불변 객체 복사 생성을 위한 copyWith 메서드
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? publisher,
    String? coverUrl,
    int? totalPages,
    int? readPages,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    double? rating,
    String? memo,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      coverUrl: coverUrl ?? this.coverUrl,
      totalPages: totalPages ?? this.totalPages,
      readPages: readPages ?? this.readPages,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      memo: memo ?? this.memo,
    );
  }

  /// JSON/Map 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publisher': publisher,
      'coverUrl': coverUrl,
      'totalPages': totalPages,
      'readPages': readPages,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rating': rating,
      'memo': memo,
    };
  }

  /// Map으로부터 Book 객체 역직렬화
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      publisher: map['publisher'] as String? ?? '',
      coverUrl: map['coverUrl'] as String?,
      totalPages: map['totalPages'] as int? ?? 0,
      readPages: map['readPages'] as int? ?? 0,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      memo: map['memo'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, progress: $progressPercentage%, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
