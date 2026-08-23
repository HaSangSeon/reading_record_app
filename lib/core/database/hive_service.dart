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
    await Hive.openBox(AppConstants.settingsBoxName);

    // 첫 실행 시 사용자 경험을 위한 샘플 도서 2권 자동 등록
    if (bookBox.isEmpty) {
      final now = DateTime.now();
      final sample1 = Book(
        id: 'sample-book-1',
        title: '불편한 편의점',
        author: '김호연',
        publisher: '나무옆의자',
        coverUrl:
            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=400',
        totalPages: 268,
        readPages: 180,
        isCompleted: false,
        rating: 4.5,
        memo: '지친 일상에 따뜻한 위로와 웃음을 주는 이야기',
        createdAt: now.subtract(const Duration(days: 5)),
      );
      final sample2 = Book(
        id: 'sample-book-2',
        title: '클린 아키텍처',
        author: '로버트 C. 마틴',
        publisher: '인사이트',
        coverUrl:
            'https://images.unsplash.com/photo-1532012164546-f432f2e3edd1?q=80&w=400',
        totalPages: 350,
        readPages: 350,
        isCompleted: true,
        rating: 5.0,
        memo: '소프트웨어 구조와 설계의 정수를 담은 명저',
        createdAt: now.subtract(const Duration(days: 20)),
        completedAt: now.subtract(const Duration(days: 2)),
      );
      await bookBox.put(sample1.id, sample1);
      await bookBox.put(sample2.id, sample2);
    }

    // 첫 실행 시 샘플 독서 노트 3개 등록
    if (noteBox.isEmpty) {
      final now = DateTime.now();
      final sampleNote1 = Note(
        id: 'sample-note-1',
        bookId: 'sample-book-1',
        pageNumber: 56,
        quotation: '결국 삶은 관계였고 관계는 소통이었다. 행복은 멀리 있지 않고 내 옆의 사람들과 마음을 나누는 데 있었다.',
        content: '독고 씨의 따뜻한 시선과 배려가 기억에 남는 문장. 사소한 친절이 사람을 살린다.',
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
      );
      final sampleNote2 = Note(
        id: 'sample-note-2',
        bookId: 'sample-book-1',
        pageNumber: 142,
        quotation:
            '밥 딜런의 외할머니가 어린 밥 딜런에게 했다는 말이 있다. 행복은 문제가 없는 상태가 아니라 문제를 해결해가는 과정이다.',
        content: '인생의 고난을 대하는 태도를 다시 생각해보게 되는 명구절.',
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
      );
      final sampleNote3 = Note(
        id: 'sample-note-3',
        bookId: 'sample-book-2',
        pageNumber: 88,
        quotation: '소프트웨어 아키텍처의 목표는 필요한 시스템을 만들고 유지보수하는 데 투입되는 인력을 최소화하는 데 있다.',
        content: '클린 아키텍처의 핵심 철학. 빠른 개발보다 변경에 유연한 구조를 만드는 것이 장기적으로 훨씬 생산적이다.',
        createdAt: now.subtract(const Duration(days: 10)),
      );
      await noteBox.put(sampleNote1.id, sampleNote1);
      await noteBox.put(sampleNote2.id, sampleNote2);
      await noteBox.put(sampleNote3.id, sampleNote3);
    }

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
