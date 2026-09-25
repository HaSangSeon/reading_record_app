import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../../firebase_options.dart';
import '../database/hive_service.dart';

/// Firebase 인증 및 Cloud Firestore 데이터 자동 동기화를 전담하는 서비스
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 현재 계정이 구글 등 외부 제공자와 연동된 정식 계정인지 여부
  bool get isLinked => _auth.currentUser != null && !_auth.currentUser!.isAnonymous;
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Firebase 앱 초기화, 오프라인 지속성 설정 및 익명 사용자 로그인
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Firestore 오프라인 캐시 및 동기화 설정 활성화
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // 사용자별 고유 보관함을 위한 익명 로그인 진행 (이미 로그인된 경우 유지)
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }

      _isInitialized = true;
      developer.log(
        'Firebase initialized successfully. User: $currentUserId (isAnonymous: ${_auth.currentUser?.isAnonymous})',
        name: 'FirebaseService',
      );
    } catch (e) {
      developer.log(
        'Firebase initialization error: $e',
        name: 'FirebaseService',
      );
    }
  }

  // --- 구글 계정 연동 및 로그인 ---

  /// 구글 계정으로 로그인하거나, 기존 익명 계정에 구글 계정을 연동합니다.
  Future<void> signInOrLinkWithGoogle(HiveService hiveService) async {
    if (!_isInitialized) return;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        developer.log('Google Sign In cancelled by user', name: 'FirebaseService');
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        // [스마트폰 시나리오] 현재 익명 계정 -> 구글 계정 연동 시도
        try {
          await currentUser.linkWithCredential(credential);
          developer.log('Successfully linked anonymous account with Google', name: 'FirebaseService');
          // 연동 후 기존 로컬 데이터를 클라우드에 확실히 푸시
          await syncAllLocalToCloud(hiveService);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // [태블릿 시나리오] 이미 다른 기기(스마트폰)에서 이 구글 계정을 연동해둔 상태
            developer.log('Credential already in use, signing in instead (Pad scenario)', name: 'FirebaseService');
            // 기존 익명 계정을 버리고 정식 구글 계정으로 로그인
            await _auth.signInWithCredential(credential);
            // 로그인 후 클라우드 데이터를 로컬로 병합 동기화
            await initialSyncWithHive(hiveService);
          } else {
            rethrow;
          }
        }
      } else {
        // 이미 익명이 아니거나(버그), 로그아웃된 상태
        await _auth.signInWithCredential(credential);
        await initialSyncWithHive(hiveService);
      }
    } catch (e) {
      developer.log('Google Sign-In/Link error: $e', name: 'FirebaseService');
      rethrow;
    }
  }

  /// 구글 계정 연동을 해제하고 다시 익명 계정으로 돌아갑니다.
  Future<void> unlinkGoogle(HiveService hiveService) async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
      
      // 로그아웃 하면 로컬 데이터도 비워주는 것이 안전 (다른 사용자 데이터 보호)
      await hiveService.bookBox.clear();
      await hiveService.noteBox.clear();
      
      // 새로운 익명 계정 발급
      await _auth.signInAnonymously();
    } catch (e) {
      developer.log('Google Sign-Out error: $e', name: 'FirebaseService');
      rethrow;
    }
  }

  // --- Firestore 경로 헬퍼 ---

  DocumentReference<Map<String, dynamic>> _userDoc() {
    final uid = currentUserId;
    if (uid == null) throw StateError('Firebase user is not authenticated');
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _booksCollection() {
    return _userDoc().collection('books');
  }

  CollectionReference<Map<String, dynamic>> _notesCollection() {
    return _userDoc().collection('notes');
  }

  // --- 도서 동기화 ---

  Future<void> saveBook(Book book) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      await _booksCollection().doc(book.id).set(
            book.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('Error saving book to Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteBook(String bookId) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      await _booksCollection().doc(bookId).delete();
    } catch (e) {
      developer.log('Error deleting book from Firestore: $e', name: 'FirebaseService');
    }
  }

  // --- 독서 노트 동기화 ---

  Future<void> saveNote(Note note) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      await _notesCollection().doc(note.id).set(
            note.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('Error saving note to Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteNote(String noteId) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      await _notesCollection().doc(noteId).delete();
    } catch (e) {
      developer.log('Error deleting note from Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteNotesByBookId(String bookId) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      final querySnapshot =
          await _notesCollection().where('bookId', isEqualTo: bookId).get();
      
      final docs = querySnapshot.docs;
      for (var i = 0; i < docs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < docs.length) ? i + 500 : docs.length;
        for (var j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }
        await batch.commit();
      }
    } catch (e) {
      developer.log(
        'Error deleting notes by bookId from Firestore: $e',
        name: 'FirebaseService',
      );
    }
  }

  // --- 양방향 초기 동기화 및 자동 복원 ---

  /// 로컬 Hive와 Firestore 간의 초기 동기화를 수행합니다.
  /// 1. 앱 재설치 등으로 로컬이 비어있고 클라우드에 데이터가 있으면 복원
  /// 2. 로컬에 작성된 데이터가 있으면 클라우드에 업로드 백업
  Future<void> initialSyncWithHive(HiveService hiveService) async {
    if (!_isInitialized || currentUserId == null) return;

    try {
      final bookBox = hiveService.bookBox;
      final noteBox = hiveService.noteBox;

      // 1. 클라우드에서 데이터 가져와서 로컬에 병합 (클라우드가 우선)
      final cloudBooksSnapshot = await _booksCollection().get();
      final cloudNotesSnapshot = await _notesCollection().get();

      for (final doc in cloudBooksSnapshot.docs) {
        final book = Book.fromMap(doc.data());
        await bookBox.put(book.id, book);
      }
      for (final doc in cloudNotesSnapshot.docs) {
        final note = Note.fromMap(doc.data());
        await noteBox.put(note.id, note);
      }

      developer.log(
        'Restored/Merged ${cloudBooksSnapshot.docs.length} books and ${cloudNotesSnapshot.docs.length} notes from Cloud.',
        name: 'FirebaseService',
      );

      // 2. 로컬에 있는 모든 데이터(방금 병합된 것 포함)를 다시 클라우드로 일괄 동기화
      // (만약 기기에만 있던 데이터가 있었다면 클라우드로 올라가게 됨)
      final localBooks = bookBox.values.toList();
      final localNotes = noteBox.values.toList();

      if (localBooks.isNotEmpty || localNotes.isNotEmpty) {
        final allOperations = [
          ...localBooks.map((book) => () {
            return (WriteBatch batch) => batch.set(
              _booksCollection().doc(book.id),
              book.toMap(),
              SetOptions(merge: true),
            );
          }),
          ...localNotes.map((note) => () {
            return (WriteBatch batch) => batch.set(
              _notesCollection().doc(note.id),
              note.toMap(),
              SetOptions(merge: true),
            );
          }),
        ];

        for (var i = 0; i < allOperations.length; i += 500) {
          final batch = _firestore.batch();
          final end = (i + 500 < allOperations.length) ? i + 500 : allOperations.length;
          for (var j = i; j < end; j++) {
            allOperations[j]()(batch);
          }
          await batch.commit();
        }
        developer.log(
          'Synced/Pushed ${localBooks.length} books and ${localNotes.length} notes back to Cloud.',
          name: 'FirebaseService',
        );
      }
    } catch (e) {
      developer.log('Initial sync error: $e', name: 'FirebaseService');
    }
  }

  /// 오프라인이었다가 온라인으로 복귀했을 때 로컬 전체를 클라우드로 안전 재동기화
  Future<void> syncAllLocalToCloud(HiveService hiveService) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      final localBooks = hiveService.bookBox.values.toList();
      final localNotes = hiveService.noteBox.values.toList();

      final allOperations = [
        ...localBooks.map((book) => () {
          return (WriteBatch batch) => batch.set(
            _booksCollection().doc(book.id),
            book.toMap(),
            SetOptions(merge: true),
          );
        }),
        ...localNotes.map((note) => () {
          return (WriteBatch batch) => batch.set(
            _notesCollection().doc(note.id),
            note.toMap(),
            SetOptions(merge: true),
          );
        }),
      ];

      for (var i = 0; i < allOperations.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < allOperations.length) ? i + 500 : allOperations.length;
        for (var j = i; j < end; j++) {
          allOperations[j]()(batch);
        }
        await batch.commit();
      }
      developer.log('Batch re-sync completed successfully.', name: 'FirebaseService');
    } catch (e) {
      developer.log('Batch re-sync error: $e', name: 'FirebaseService');
    }
  }
}
