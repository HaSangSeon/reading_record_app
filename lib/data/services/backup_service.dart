import 'dart:convert';
import '../../core/database/hive_service.dart';
import '../models/book_model.dart';
import '../models/note_model.dart';

/// 100% 로컬 환경을 위한 JSON 백업 및 복원 서비스
class BackupService {
  final HiveService _hiveService;

  BackupService({HiveService? hiveService})
      : _hiveService = hiveService ?? HiveService();

  /// 모든 도서 및 독서 기록을 JSON 문자열로 내보내기
  Future<String> exportToJson() async {
    final books = _hiveService.bookBox.values.map((b) => b.toMap()).toList();
    final notes = _hiveService.noteBox.values.map((n) => n.toMap()).toList();

    final backupData = {
      'app': 'ReadingRecordApp',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'booksCount': books.length,
      'notesCount': notes.length,
      'books': books,
      'notes': notes,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }

  /// JSON 문자열로부터 도서 및 독서 기록 복원
  Future<({int booksRestored, int notesRestored})> importFromJson(
    String jsonString, {
    bool overwrite = false,
  }) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString.trim());
    } catch (e) {
      throw const FormatException('올바른 JSON 형식의 백업 데이터가 아닙니다.');
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['books'] is! List ||
        decoded['notes'] is! List) {
      throw const FormatException('독서 기록 앱의 유효한 백업 구조가 아닙니다.');
    }

    final booksList = decoded['books'] as List<dynamic>;
    final notesList = decoded['notes'] as List<dynamic>;

    // 덮어쓰기 모드인 경우 기존 데이터 초기화
    if (overwrite) {
      await _hiveService.bookBox.clear();
      await _hiveService.noteBox.clear();
    }

    int booksCount = 0;
    for (final rawBook in booksList) {
      if (rawBook is Map<String, dynamic>) {
        final book = Book.fromMap(rawBook);
        await _hiveService.bookBox.put(book.id, book);
        booksCount++;
      }
    }

    int notesCount = 0;
    for (final rawNote in notesList) {
      if (rawNote is Map<String, dynamic>) {
        final note = Note.fromMap(rawNote);
        await _hiveService.noteBox.put(note.id, note);
        notesCount++;
      }
    }

    return (booksRestored: booksCount, notesRestored: notesCount);
  }
}
