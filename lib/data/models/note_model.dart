import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'note_model.g.dart';

@HiveType(typeId: AppConstants.noteTypeId)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String bookId;

  @HiveField(2)
  final int pageNumber;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  final String quotation;

  Note({
    required this.id,
    required this.bookId,
    this.pageNumber = 0,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.quotation = '',
  });

  /// 불변 객체 복사 생성을 위한 copyWith 메서드
  Note copyWith({
    String? id,
    String? bookId,
    int? pageNumber,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? quotation,
  }) {
    return Note(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      pageNumber: pageNumber ?? this.pageNumber,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quotation: quotation ?? this.quotation,
    );
  }

  /// JSON/Map 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'pageNumber': pageNumber,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'quotation': quotation,
    };
  }

  /// Map으로부터 Note 객체 역직렬화
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      pageNumber: map['pageNumber'] as int? ?? 0,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      quotation: map['quotation'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, bookId: $bookId, page: $pageNumber, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
