import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/hive_service.dart';
import '../data/models/book_model.dart';
import '../data/models/note_model.dart';
import '../core/services/firebase_service.dart';
import '../core/services/network_sync_service.dart';
import '../data/repositories/sync_book_repository.dart';
import '../data/repositories/sync_note_repository.dart';
import '../domain/repositories/book_repository.dart';
import '../domain/repositories/note_repository.dart';

/// HiveService 인스턴스 프로바이더
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// FirebaseService 인스턴스 프로바이더
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// NetworkSyncService 인스턴스 프로바이더
final networkSyncServiceProvider = Provider<NetworkSyncService>((ref) {
  return NetworkSyncService();
});

/// BookRepository 프로바이더 (로컬 우선 + Firebase 실시간 자동 클라우드 백업 + 오프라인 알림)
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  final networkSyncService = ref.watch(networkSyncServiceProvider);
  return SyncBookRepository(hiveService, firebaseService, networkSyncService);
});

/// NoteRepository 프로바이더 (로컬 우선 + Firebase 실시간 자동 클라우드 백업 + 오프라인 알림)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  final networkSyncService = ref.watch(networkSyncServiceProvider);
  return SyncNoteRepository(hiveService, firebaseService, networkSyncService);
});

/// 모든 도서 목록 실시간 감지 스트림 프로바이더
final allBooksStreamProvider = StreamProvider<List<Book>>((ref) {
  final bookRepo = ref.watch(bookRepositoryProvider);
  return bookRepo.watchAllBooks();
});

/// 모든 독서 노트 목록 실시간 감지 스트림 프로바이더
final allNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final noteRepo = ref.watch(noteRepositoryProvider);
  return noteRepo.watchAllNotes();
});

/// 특정 도서의 독서 노트 목록 실시간 감지 스트림 프로바이더
final notesByBookStreamProvider = StreamProvider.family<List<Note>, String>((
  ref,
  bookId,
) {
  final noteRepo = ref.watch(noteRepositoryProvider);
  return noteRepo.watchNotesByBookId(bookId);
});
