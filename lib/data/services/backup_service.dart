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
      // 1. JSON 파일 우선 필터링 선택 (실패 시 any로 폴백)
      List<PlatformFile> files = [];
      try {
        files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } catch (_) {
        files = await FilePicker.pickFiles(type: FileType.any);
      }

      if (files.isEmpty) {
        return (success: false, books: 0, notes: 0, error: '선택된 파일이 없습니다.');
      }

      final file = files.first;
      String content;

      // 2. 로컬 경로 직접 읽기 또는 클라우드(Google Drive, SAF) 바이트 디코딩 지원
      if (file.path != null && file.path!.isNotEmpty) {
        content = await File(file.path!).readAsString(encoding: utf8);
      } else {
        final bytes = await file.readAsBytes();
        content = utf8.decode(bytes);
      }

      if (content.trim().isEmpty) {
        return (success: false, books: 0, notes: 0, error: '백업 파일의 내용이 비어있습니다.');
      }

      // 3. JSON 파싱 및 데이터베이스 복원
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

    if (decoded is! Map ||
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
      if (rawBook is Map) {
        try {
          final bookMap = Map<String, dynamic>.from(rawBook);
          final book = Book.fromMap(bookMap);
          await _hiveService.bookBox.put(book.id, book);
          booksCount++;
        } catch (e) {
          // 특정 도서 변환 실패 시 전체 복원을 중단하지 않고 로그 남김
        }
      }
    }

    int notesCount = 0;
    for (final rawNote in notesList) {
      if (rawNote is Map) {
        try {
          final noteMap = Map<String, dynamic>.from(rawNote);
          final note = Note.fromMap(noteMap);
          await _hiveService.noteBox.put(note.id, note);
          notesCount++;
        } catch (e) {
          // 특정 노트 변환 실패 시 전체 복원을 중단하지 않고 로그 남김
        }
      }
    }

    return (booksRestored: booksCount, notesRestored: notesCount);
  }
}
