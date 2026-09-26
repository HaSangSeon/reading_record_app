import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../constants/app_constants.dart';

/// 로컬 Hive 데이터베이스의 초기화 및 Box 관리를 전담하는 서비스 클래스
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _isInitialized = false;

  /// Hive 초기화 및 어댑터 등록, 필수 Box들을 오픈합니다.
  Future<void> init() async {
    if (_isInitialized) return;

    // Flutter 환경에 맞는 로컬 스토리지 디렉토리로 Hive 초기화
    await Hive.initFlutter();

    // TypeAdapter 등록 (중복 등록 방지)
    if (!Hive.isAdapterRegistered(AppConstants.bookTypeId)) {
      Hive.registerAdapter(BookAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.noteTypeId)) {
      Hive.registerAdapter(NoteAdapter());
    }

    // Book, Note 및 설정 저장을 위한 Box 오픈
    final bookBox = await Hive.openBox<Book>(AppConstants.bookBoxName);
    final noteBox = await Hive.openBox<Note>(AppConstants.noteBoxName);
    final settingsBox = await Hive.openBox(AppConstants.settingsBoxName);



    _isInitialized = true;
  }

  /// Book 전용 Box 반환
  Box<Book> get bookBox {
    _ensureInitialized();
    return Hive.box<Book>(AppConstants.bookBoxName);
  }

  /// Note 전용 Box 반환
  Box<Note> get noteBox {
    _ensureInitialized();
    return Hive.box<Note>(AppConstants.noteBoxName);
  }

  /// 설정 전용 Box 반환
  Box get settingsBox {
    _ensureInitialized();
    return Hive.box(AppConstants.settingsBoxName);
  }

  /// 모든 로컬 데이터 삭제 (초기화 기능용)
  Future<void> clearAllData() async {
    _ensureInitialized();
    await bookBox.clear();
    await noteBox.clear();
  }

  /// 데이터베이스 리소스 해제
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'HiveService is not initialized. Call HiveService.init() first.',
      );
    }
  }
}
