import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
      'appName': '독서한줄',
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

  /// 백업 JSON 파일을 생성하고 카카오톡/구글드라이브/파일 등으로 공유
  Future<({bool success, String? filePath, int books, int notes})>
  exportBackupFileAndShare() async {
    final jsonString = await exportToJson();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '독서한줄_백업_$timestamp.json';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(jsonString, encoding: utf8);

    final booksCount = _hiveService.bookBox.length;
    final notesCount = _hiveService.noteBox.length;

    final xFile = XFile(
      file.path,
      mimeType: 'application/json',
      name: fileName,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: '독서한줄 데이터 백업 ($fileName)',
        text: '독서한줄 앱의 도서 $booksCount권, 기록 $notesCount개의 안전 백업 파일입니다.',
      ),
    );

    return (
      success: true,
      filePath: file.path,
      books: booksCount,
      notes: notesCount,
    );
  }

  /// 파일 선택기로 백업 JSON 파일을 선택하여 데이터 복원
  Future<({bool success, int books, int notes, String? error})>
  pickAndImportBackupFile({bool overwrite = false}) async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);

      if (files.isEmpty || files.first.path == null) {
        return (success: false, books: 0, notes: 0, error: '선택된 파일이 없습니다.');
      }

      final file = File(files.first.path!);
      final content = await file.readAsString(encoding: utf8);

      final restored = await importFromJson(content, overwrite: overwrite);
      return (
        success: true,
        books: restored.booksRestored,
        notes: restored.notesRestored,
        error: null,
      );
    } catch (e) {
      return (
        success: false,
        books: 0,
        notes: 0,
        error: e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('FormatException: ', ''),
      );
    }
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
      throw const FormatException('독서한줄 앱의 유효한 백업 데이터 구조가 아닙니다.');
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
