import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../../firebase_options.dart';
import '../database/hive_service.dart';
import 'sync_store.dart';

/// 클라우드 동기화 수행 결과 모델
class SyncResult {
  final bool success;
  final int booksDownloaded;
  final int notesDownloaded;
  final int booksUploaded;
  final int notesUploaded;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    this.booksDownloaded = 0,
    this.notesDownloaded = 0,
    this.booksUploaded = 0,
    this.notesUploaded = 0,
    this.errorMessage,
  });

  bool get hasChanges =>
      booksDownloaded > 0 ||
      notesDownloaded > 0 ||
      booksUploaded > 0 ||
      notesUploaded > 0;
}

/// Firebase 인증 및 Cloud Firestore 데이터 자동 동기화를 전담하는 서비스
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  final SyncStore store = SyncStore(HiveService());
  Timer? _retryTimer;
  bool _linking = false;
  String? _syncUid;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 현재 계정이 구글 등 외부 제공자와 연동된 정식 계정인지 여부
  bool get isLinked =>
      _auth.currentUser != null && !_auth.currentUser!.isAnonymous;
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Firebase 앱 초기화, 오프라인 지속성 설정 및 익명 사용자 로그인
  Future<void>? _initializing;

  Future<void> init() =>
      _initializing ??= _initialize().whenComplete(() => _initializing = null);

  Future<void> _initialize() async {
    if (_isInitialized && currentUserId != null && !store.signOutPending) {
      return;
    }

    try {
      if (store.signOutPending) {
        final hive = HiveService();
        await hive.bookBox.clear();
        await hive.noteBox.clear();
        await hive.settingsBox.deleteAll([_deletedBooksKey, _deletedNotesKey]);
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      if (store.signOutPending) {
        await _finishPendingSignOut(HiveService());
      }
      await store.serial(store.recoverDeletions);

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
  Future<SyncResult?> signInOrLinkWithGoogle(HiveService hiveService) async {
    if (_linking || _signingOut || store.signOutPending) {
      throw StateError('계정 변경이 진행 중입니다.');
    }
    _linking = true;
    store.accountChanging = true;
    try {
      await store.pendingWrites.timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
      await _syncInProgress?.timeout(
        const Duration(seconds: 10),
        onTimeout: () => const SyncResult(success: false),
      );
      stopRealtimeSync();
      await init();
      if (!_isInitialized) {
        return const SyncResult(
          success: false,
          errorMessage: 'Firebase 서비스가 초기화되지 않았습니다.',
        );
      }

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          developer.log(
            'Google Sign In cancelled by user',
            name: 'FirebaseService',
          );
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final currentUser = _auth.currentUser;

        if (currentUser != null && currentUser.isAnonymous) {
          // [스마트폰 시나리오] 현재 익명 계정 -> 구글 계정 연동 시도
          try {
            await currentUser.linkWithCredential(credential);
            developer.log(
              'Successfully linked anonymous account with Google',
              name: 'FirebaseService',
            );
            // 연동 후 로컬과 클라우드 양방향 완전 동기화 진행
            return await _beginSync(hiveService);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'credential-already-in-use' ||
                e.code == 'email-already-in-use' ||
                e.code == 'account-exists-with-different-credential') {
              // [태블릿 시나리오] 이미 다른 기기(스마트폰)에서 이 구글 계정을 연동해둔 상태
              developer.log(
                'Credential already in use, signing in instead (Pad scenario)',
                name: 'FirebaseService',
              );
              // 기존 익명 계정을 버리고 정식 구글 계정으로 로그인
              await _auth.signInWithCredential(credential);
              // 로그인 후 클라우드 데이터를 로컬로 병합 동기화
              return await _beginSync(hiveService);
            } else {
              rethrow;
            }
          }
        } else {
          if (currentUser != null && !currentUser.isAnonymous) {
            throw StateError('현재 계정의 연동을 먼저 해제해 주세요.');
          }
          // 로그아웃된 상태
          await _auth.signInWithCredential(credential);
          return await _beginSync(hiveService);
        }
      } catch (e) {
        developer.log('Google Sign-In/Link error: $e', name: 'FirebaseService');
        rethrow;
      }
    } finally {
      _linking = false;
      store.accountChanging = false;
      if (_isInitialized && !store.signOutPending) {
        startRealtimeSync(hiveService);
      }
    }
  }

  // --- 실시간 다중 기기 동기화 리스너 ---
  StreamSubscription? _booksSubscription;
  StreamSubscription? _notesSubscription;

  /// 다른 기기(태블릿 등)에서 변경/삭제한 사항을 실시간으로 로컬 Hive에 반영
  void startRealtimeSync(HiveService hiveService) {
    if (!_isInitialized || currentUserId == null || !isLinked) return;
    stopRealtimeSync();

    try {
      final bookBox = hiveService.bookBox;
      final noteBox = hiveService.noteBox;

      _booksSubscription = _booksCollection().snapshots().listen(
        (snapshot) {
          if (_linking || _signingOut || store.signOutPending) return;
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;

            final isDeleted = data['isDeleted'] == true;
            final docId = change.doc.id;

            if (isDeleted || change.type == DocumentChangeType.removed) {
              final localBook = bookBox.get(docId);
              final cloudDeletedTime = DateTime.tryParse(
                data['updatedAt']?.toString() ?? '',
              );
              final localTime = localBook != null
                  ? (localBook.updatedAt ?? localBook.createdAt)
                  : null;
              if (localBook == null ||
                  cloudDeletedTime == null ||
                  !localTime!.isAfter(cloudDeletedTime)) {
                if (localBook != null) {
                  bookBox.delete(docId);
                }
                final orphanNoteIds = noteBox.values
                    .where((n) => n.bookId == docId)
                    .map((n) => n.id)
                    .toList();
                if (orphanNoteIds.isNotEmpty) {
                  noteBox.deleteAll(orphanNoteIds);
                }
                developer.log(
                  'Realtime delete book: $docId',
                  name: 'FirebaseService',
                );
              }
            } else {
              try {
                if (store.deletions('books').containsKey(docId)) continue;
                final cloudBook = Book.fromMap(data);
                final localBook = bookBox.get(docId);
                final cloudTime = cloudBook.updatedAt ?? cloudBook.createdAt;
                final localTime = localBook != null
                    ? (localBook.updatedAt ?? localBook.createdAt)
                    : null;

                if (localBook == null || cloudTime.isAfter(localTime!)) {
                  bookBox.put(docId, cloudBook);
                  developer.log(
                    'Realtime sync book: $docId',
                    name: 'FirebaseService',
                  );
                }
              } catch (e) {
                developer.log(
                  'Realtime book parse error: $e',
                  name: 'FirebaseService',
                );
              }
            }
          }
        },
        onError: (e) {
          developer.log(
            'Books realtime sync error: $e',
            name: 'FirebaseService',
          );
        },
      );

      _notesSubscription = _notesCollection().snapshots().listen(
        (snapshot) {
          if (_linking || _signingOut || store.signOutPending) return;
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;

            final isDeleted = data['isDeleted'] == true;
            final docId = change.doc.id;

            if (isDeleted || change.type == DocumentChangeType.removed) {
              final localNote = noteBox.get(docId);
              if (localNote != null) {
                final cloudDeletedTime = DateTime.tryParse(
                  data['updatedAt']?.toString() ?? '',
                );
                final localTime = localNote.updatedAt ?? localNote.createdAt;
                if (cloudDeletedTime == null ||
                    !localTime.isAfter(cloudDeletedTime)) {
                  noteBox.delete(docId);
                  developer.log(
                    'Realtime delete note: $docId',
                    name: 'FirebaseService',
                  );
                }
              }
            } else {
              try {
                if (store.deletions('notes').containsKey(docId) ||
                    store.deletions('books').containsKey(data['bookId'])) {
                  continue;
                }
                final cloudNote = Note.fromMap(data);
                final localNote = noteBox.get(docId);
                final cloudTime = cloudNote.updatedAt ?? cloudNote.createdAt;
                final localTime = localNote != null
                    ? (localNote.updatedAt ?? localNote.createdAt)
                    : null;

                if (localNote == null || cloudTime.isAfter(localTime!)) {
                  noteBox.put(docId, cloudNote);
                  developer.log(
                    'Realtime sync note: $docId',
                    name: 'FirebaseService',
                  );
                }
              } catch (e) {
                developer.log(
                  'Realtime note parse error: $e',
                  name: 'FirebaseService',
                );
              }
            }
          }
        },
        onError: (e) {
          developer.log(
            'Notes realtime sync error: $e',
            name: 'FirebaseService',
          );
        },
      );
      developer.log(
        'Started realtime sync listeners.',
        name: 'FirebaseService',
      );
    } catch (e) {
      developer.log(
        'Failed to start realtime sync: $e',
        name: 'FirebaseService',
      );
    }
  }

  void stopRealtimeSync() {
    _booksSubscription?.cancel();
    _booksSubscription = null;
    _notesSubscription?.cancel();
    _notesSubscription = null;
  }

  /// 구글 계정 연동을 해제하고 다시 익명 계정으로 돌아갑니다.
  Future<void> unlinkGoogle(HiveService hiveService) async {
    if (_signingOut || _linking || store.signOutPending) {
      throw StateError('계정 변경이 진행 중입니다.');
    }
    _signingOut = true;
    store.accountChanging = true;
    try {
      await store.pendingWrites.timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
      await _syncInProgress?.timeout(
        const Duration(seconds: 10),
        onTimeout: () => const SyncResult(success: false),
      );
      stopRealtimeSync();
      final uid = currentUserId;
      if (uid == null) {
        throw StateError('로그인된 계정 정보를 확인할 수 없습니다.');
      }

      // 1. 연동 해제 전 로컬의 모든 최신 변경 사항을 클라우드로 최종 동기화
      final syncResult = await _syncWithHive(
        hiveService,
        uid,
        allowDuringSignOut: true,
      );
      if (!syncResult.success) {
        developer.log(
          'Pre-unlink sync failed: ${syncResult.errorMessage}',
          name: 'FirebaseService',
        );
        throw StateError('클라우드 백업을 확인하지 못했습니다. 기록은 이 기기에 보관됩니다.');
      }

      if (uid != currentUserId) {
        throw StateError('클라우드 백업을 확인하지 못했습니다. 기록은 이 기기에 보관됩니다.');
      }
      await hiveService.settingsBox.put(SyncStore.signOutKey, uid);
      await _finishPendingSignOut(hiveService);

      // 새로운 익명 계정 발급
      _isInitialized = false;
      await init();
    } catch (e, st) {
      if (!store.signOutPending) startRealtimeSync(hiveService);
      developer.log('Google Sign-Out error: $e\n$st', name: 'FirebaseService');
      if (e is TimeoutException) {
        throw StateError('클라우드 백업을 확인하지 못했습니다. 기록은 이 기기에 보관됩니다.');
      }
      rethrow;
    } finally {
      _signingOut = false;
      store.accountChanging = false;
    }
  }

  Future<void> _finishPendingSignOut(HiveService hive) async {
    stopRealtimeSync();
    await hive.bookBox.clear();
    await hive.noteBox.clear();
    await hive.settingsBox.deleteAll([_deletedBooksKey, _deletedNotesKey]);
    try {
      await GoogleSignIn().signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}
    await _auth.signOut();
    await hive.settingsBox.delete(SyncStore.signOutKey);
    _isInitialized = false;
  }

  bool _isSameBookContent(Book a, Book b) {
    return a.id == b.id &&
        a.title == b.title &&
        a.author == b.author &&
        a.publisher == b.publisher &&
        a.coverUrl == b.coverUrl &&
        a.totalPages == b.totalPages &&
        a.readPages == b.readPages &&
        a.isCompleted == b.isCompleted &&
        (a.rating - b.rating).abs() < 0.001 &&
        a.memo == b.memo;
  }

  bool _isSameNoteContent(Note a, Note b) {
    return a.id == b.id &&
        a.bookId == b.bookId &&
        a.pageNumber == b.pageNumber &&
        a.content == b.content &&
        a.quotation == b.quotation;
  }

  // --- Firestore 경로 헬퍼 ---

  DocumentReference<Map<String, dynamic>> _userDoc([String? uid]) {
    final targetUid = uid ?? _syncUid ?? currentUserId;
    if (targetUid == null) {
      throw StateError('Firebase user is not authenticated');
    }
    return _firestore.collection('users').doc(targetUid);
  }

  CollectionReference<Map<String, dynamic>> _booksCollection([String? uid]) {
    return _userDoc(uid).collection('books');
  }

  CollectionReference<Map<String, dynamic>> _notesCollection([String? uid]) {
    return _userDoc(uid).collection('notes');
  }

  // --- 도서 동기화 ---

  Future<void> saveBook(Book book) async {
    if (!_isInitialized ||
        currentUserId == null ||
        _linking ||
        _signingOut ||
        store.signOutPending) {
      return;
    }
    try {
      final map = book.toMap();
      map['isDeleted'] = false;
      await _booksCollection(
        currentUserId,
      ).doc(book.id).set(map, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'Error saving book to Firestore: $e',
        name: 'FirebaseService',
      );
    }
  }

  /// 소프트 딜리트(Soft Delete): 클라우드에 삭제 상태를 기록하여 다른 기기에서도 부활하지 않고 안전하게 삭제되도록 함
  Future<void> deleteBook(String bookId) async {
    if (!_isInitialized ||
        currentUserId == null ||
        _linking ||
        _signingOut ||
        store.signOutPending) {
      return;
    }
    try {
      await _booksCollection(currentUserId).doc(bookId).set({
        'id': bookId,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'Error deleting book from Firestore: $e',
        name: 'FirebaseService',
      );
    }
  }

  // --- 독서 노트 동기화 ---

  Future<void> saveNote(Note note) async {
    if (!_isInitialized ||
        currentUserId == null ||
        _linking ||
        _signingOut ||
        store.signOutPending) {
      return;
    }
    try {
      final map = note.toMap();
      map['isDeleted'] = false;
      await _notesCollection(
        currentUserId,
      ).doc(note.id).set(map, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'Error saving note to Firestore: $e',
        name: 'FirebaseService',
      );
    }
  }

  /// 소프트 딜리트(Soft Delete): 클라우드에 삭제 상태를 기록하여 다른 기기에서도 부활하지 않도록 함
  Future<void> deleteNote(String noteId) async {
    if (!_isInitialized ||
        currentUserId == null ||
        _linking ||
        _signingOut ||
        store.signOutPending) {
      return;
    }
    try {
      await _notesCollection(currentUserId).doc(noteId).set({
        'id': noteId,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log(
        'Error deleting note from Firestore: $e',
        name: 'FirebaseService',
      );
    }
  }

  static const String _deletedBooksKey = 'deleted_books_tombstones';
  static const String _deletedNotesKey = 'deleted_notes_tombstones';

  Future<void> deleteNotesByBookId(
    String bookId, {
    List<String> noteIds = const [],
  }) async {
    final uid = currentUserId;
    if (!_isInitialized ||
        uid == null ||
        _linking ||
        _signingOut ||
        store.signOutPending) {
      return;
    }
    try {
      final nowIso = DateTime.now().toIso8601String();
      final notesCol = _notesCollection(uid);
      final targetRefs = <String, DocumentReference<Map<String, dynamic>>>{
        for (final id in noteIds) id: notesCol.doc(id),
      };

      try {
        final querySnapshot = await notesCol
            .where('bookId', isEqualTo: bookId)
            .get()
            .timeout(const Duration(seconds: 5));
        for (final doc in querySnapshot.docs) {
          targetRefs[doc.id] = doc.reference;
        }
      } catch (_) {
        // 오프라인 등으로 쿼리 실패 시 캐시에서도 추가 조회 시도
        try {
          final cacheSnapshot = await notesCol
              .where('bookId', isEqualTo: bookId)
              .get(const GetOptions(source: Source.cache));
          for (final doc in cacheSnapshot.docs) {
            targetRefs[doc.id] = doc.reference;
          }
        } catch (_) {}
      }

      if (targetRefs.isNotEmpty) {
        await store.serial(
          () => store.markDeleted('notes', targetRefs.keys, nowIso),
        );
      }

      final refs = targetRefs.values.toList();
      for (var i = 0; i < refs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < refs.length) ? i + 500 : refs.length;
        for (var j = i; j < end; j++) {
          batch.set(refs[j], {
            'id': refs[j].id,
            'bookId': bookId,
            'isDeleted': true,
            'updatedAt': nowIso,
          }, SetOptions(merge: true));
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

  /// 로컬 Hive와 Firestore 간의 양방향 완전 무결성 동기화를 수행합니다.
  /// 1. 클라우드에서 삭제(isDeleted: true)된 항목은 로컬에서도 안전 삭제 (좀비 데이터 부활 방지)
  /// 2. 클라우드의 유효 데이터와 로컬 데이터를 타임스탬프(updatedAt) 기준으로 최신본 병합
  /// 3. 로컬의 최신/신규 데이터만 클라우드로 업로드
  Future<SyncResult>? _syncInProgress;
  bool _signingOut = false;

  Future<SyncResult> initialSyncWithHive(HiveService hiveService) {
    if (_signingOut || _linking || store.signOutPending) {
      return Future.value(
        const SyncResult(success: false, errorMessage: '계정 연동 해제 중입니다.'),
      );
    }
    return _beginSync(hiveService);
  }

  Future<SyncResult> _beginSync(HiveService hiveService) {
    _retryTimer ??= Timer.periodic(const Duration(seconds: 60), (_) {
      if (!_linking && !_signingOut && !store.signOutPending) {
        unawaited(syncAllLocalToCloud(hiveService));
      }
    });
    final inProgress = _syncInProgress;
    if (inProgress != null &&
        currentUserId != null &&
        _syncUid == currentUserId) {
      return inProgress;
    }
    late final Future<SyncResult> nextSync;
    nextSync = (() async {
      if (inProgress != null) {
        try {
          await inProgress.timeout(const Duration(seconds: 10));
        } catch (_) {}
      }
      if (!_isInitialized || currentUserId == null) {
        await init();
      }
      final uid = currentUserId;
      _syncUid = uid;
      try {
        return await _syncWithHive(hiveService, uid);
      } finally {
        if (_syncUid == uid) {
          _syncUid = null;
        }
        if (identical(_syncInProgress, nextSync)) {
          _syncInProgress = null;
        }
      }
    })();
    _syncInProgress = nextSync;
    return nextSync;
  }

  Future<SyncResult> _syncWithHive(
    HiveService hiveService,
    String? uid, {
    bool allowDuringSignOut = false,
  }) async {
    if (!_isInitialized ||
        uid == null ||
        currentUserId != uid ||
        (!allowDuringSignOut && _signingOut) ||
        store.signOutPending) {
      return const SyncResult(
        success: false,
        errorMessage: '로그인이 필요하거나 Firebase 서비스가 준비되지 않았습니다.',
      );
    }

    try {
      await store.pendingWrites;
      await store.serial(store.recoverDeletions);
      final bookBox = hiveService.bookBox;
      final noteBox = hiveService.noteBox;

      final localDeletedBooks = store.deletions('books');
      final localDeletedNotes = store.deletions('notes');

      final pendingCloudBookDeletes = <String, String>{};
      final pendingCloudNoteDeletes = <String, String>{};

      // 로컬에 대기 중인 Firestore 쓰기가 있다면 짧게 대기 (이전 세션의 막힌 큐로 인해 타임아웃 예외가 발생하지 않도록 처리)
      await _firestore.waitForPendingWrites().timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );

      // 1. 클라우드 데이터 전체 조회 (동일 계정 uid 고정)
      const server = GetOptions(source: Source.server);
      final cloudBooksSnapshot = await _booksCollection(
        uid,
      ).get(server).timeout(const Duration(seconds: 15));
      final cloudNotesSnapshot = await _notesCollection(
        uid,
      ).get(server).timeout(const Duration(seconds: 15));

      if (currentUserId != uid ||
          (!allowDuringSignOut && _signingOut) ||
          store.signOutPending) {
        return const SyncResult(
          success: false,
          errorMessage: '동기화 도중 계정이 변경되었습니다.',
        );
      }

      final cloudBookDocMap = <String, Map<String, dynamic>>{};
      int booksDownloaded = 0;

      for (final doc in cloudBooksSnapshot.docs) {
        final data = doc.data();
        cloudBookDocMap[doc.id] = data;

        final isDeleted = data['isDeleted'] == true;
        if (isDeleted) {
          // 다른 기기에서 삭제된 항목 -> 로컬이 더 최신이 아닌 경우 로컬 도서 및 하위 노트 함께 삭제
          final localBook = bookBox.get(doc.id);
          final cloudDeletedTime = DateTime.tryParse(
            data['updatedAt']?.toString() ?? '',
          );
          final localTime = localBook != null
              ? (localBook.updatedAt ?? localBook.createdAt)
              : null;
          if (localBook == null ||
              cloudDeletedTime == null ||
              !localTime!.isAfter(cloudDeletedTime)) {
            if (localBook != null) {
              await bookBox.delete(doc.id);
            }
            final orphanNoteIds = noteBox.values
                .where((n) => n.bookId == doc.id)
                .map((n) => n.id)
                .toList();
            if (orphanNoteIds.isNotEmpty) {
              await noteBox.deleteAll(orphanNoteIds);
            }
          }
        } else {
          try {
            // 오프라인 상태에서 로컬에서 삭제했던 도서인지 확인
            final localDeletedIso = localDeletedBooks[doc.id];
            if (localDeletedIso != null) {
              pendingCloudBookDeletes[doc.id] = localDeletedIso;
              continue;
            }

            final cloudBook = Book.fromMap(data);
            final localBook = bookBox.get(cloudBook.id);
            final cloudTime = cloudBook.updatedAt ?? cloudBook.createdAt;
            final localTime = localBook != null
                ? (localBook.updatedAt ?? localBook.createdAt)
                : null;

            if (localBook == null || cloudTime.isAfter(localTime!)) {
              await bookBox.put(cloudBook.id, cloudBook);
              booksDownloaded++;
            }
          } catch (e) {
            developer.log(
              'Error parsing book (${doc.id}): $e',
              name: 'FirebaseService',
            );
          }
        }
      }

      // 로컬 삭제 이력 중 클라우드에 아직 반영되지 않은 도서 삭제 예약
      for (final entry in localDeletedBooks.entries) {
        if (cloudBookDocMap[entry.key]?['isDeleted'] != true) {
          pendingCloudBookDeletes[entry.key] = entry.value;
        }
      }

      final cloudNoteDocMap = <String, Map<String, dynamic>>{};
      final newlyDiscoveredDeletedNotes = <String, String>{};
      int notesDownloaded = 0;

      for (final doc in cloudNotesSnapshot.docs) {
        final data = doc.data();
        cloudNoteDocMap[doc.id] = data;

        final isDeleted = data['isDeleted'] == true;
        final bookId = data['bookId']?.toString();
        final deletedBookIso = bookId != null ? localDeletedBooks[bookId] : null;

        if (deletedBookIso != null) {
          // 부모 도서가 로컬에서 삭제된 경우 해당 노트도 삭제 이력 및 서버 삭제에 포함
          final noteDeleteIso = localDeletedNotes[doc.id] ?? deletedBookIso;
          if (!localDeletedNotes.containsKey(doc.id)) {
            localDeletedNotes[doc.id] = noteDeleteIso;
            newlyDiscoveredDeletedNotes[doc.id] = noteDeleteIso;
          }
          if (!isDeleted) {
            pendingCloudNoteDeletes[doc.id] = noteDeleteIso;
          }
          if (noteBox.containsKey(doc.id)) {
            await noteBox.delete(doc.id);
          }
          continue;
        }

        if (isDeleted ||
            (bookId != null &&
                cloudBookDocMap[bookId]?['isDeleted'] == true &&
                !bookBox.containsKey(bookId))) {
          final localNote = noteBox.get(doc.id);
          if (localNote != null) {
            final cloudDeletedTime = DateTime.tryParse(
              data['updatedAt']?.toString() ?? '',
            );
            final localTime = localNote.updatedAt ?? localNote.createdAt;
            if (cloudDeletedTime == null ||
                !localTime.isAfter(cloudDeletedTime)) {
              await noteBox.delete(doc.id);
            }
          }
        } else {
          try {
            final localDeletedIso = localDeletedNotes[doc.id];
            if (localDeletedIso != null) {
              pendingCloudNoteDeletes[doc.id] = localDeletedIso;
              continue;
            }

            final cloudNote = Note.fromMap(data);
            if (!bookBox.containsKey(cloudNote.bookId)) {
              continue;
            }
            final localNote = noteBox.get(cloudNote.id);
            final cloudTime = cloudNote.updatedAt ?? cloudNote.createdAt;
            final localTime = localNote != null
                ? (localNote.updatedAt ?? localNote.createdAt)
                : null;

            if (localNote == null || cloudTime.isAfter(localTime!)) {
              await noteBox.put(cloudNote.id, cloudNote);
              notesDownloaded++;
            }
          } catch (e) {
            developer.log(
              'Error parsing note (${doc.id}): $e',
              name: 'FirebaseService',
            );
          }
        }
      }

      if (newlyDiscoveredDeletedNotes.isNotEmpty) {
        for (final entry in newlyDiscoveredDeletedNotes.entries) {
          await store.serial(
            () => store.markDeleted('notes', [entry.key], entry.value),
          );
        }
      }

      // 로컬 삭제 이력 중 클라우드에 아직 반영되지 않은 노트 삭제 예약
      for (final entry in localDeletedNotes.entries) {
        if (cloudNoteDocMap[entry.key]?['isDeleted'] != true) {
          pendingCloudNoteDeletes[entry.key] = entry.value;
        }
      }

      developer.log(
        'Synced from Cloud: $booksDownloaded books, $notesDownloaded notes downloaded/updated.',
        name: 'FirebaseService',
      );

      // 2. 로컬 데이터 중 클라우드에 아직 없거나 로컬이 더 최신인 항목(또는 타임스탬프가 같아도 내용이 다른 항목)을 선별하여 업로드
      final booksToUpload = <Book>[];
      for (final book in bookBox.values) {
        if (localDeletedBooks.containsKey(book.id)) continue;
        final cloudData = cloudBookDocMap[book.id];
        if (cloudData == null) {
          booksToUpload.add(book);
        } else if (cloudData['isDeleted'] == true) {
          final cloudDeletedTime = DateTime.tryParse(
            cloudData['updatedAt']?.toString() ?? '',
          );
          final localTime = book.updatedAt ?? book.createdAt;
          if (cloudDeletedTime != null && localTime.isAfter(cloudDeletedTime)) {
            booksToUpload.add(book);
          }
        } else {
          try {
            final cloudBook = Book.fromMap(cloudData);
            final cloudTime = cloudBook.updatedAt ?? cloudBook.createdAt;
            final localTime = book.updatedAt ?? book.createdAt;
            if (localTime.isAfter(cloudTime) ||
                (localTime.isAtSameMomentAs(cloudTime) &&
                    !_isSameBookContent(book, cloudBook))) {
              booksToUpload.add(book);
            }
          } catch (_) {
            booksToUpload.add(book);
          }
        }
      }

      // 부모 도서가 존재하지 않는 로컬 고아 노트 정리
      final orphanLocalNoteIds = noteBox.values
          .where((n) => !bookBox.containsKey(n.bookId))
          .map((n) => n.id)
          .toList();
      if (orphanLocalNoteIds.isNotEmpty) {
        await noteBox.deleteAll(orphanLocalNoteIds);
      }

      final notesToUpload = <Note>[];
      for (final note in noteBox.values) {
        if (localDeletedNotes.containsKey(note.id) ||
            localDeletedBooks.containsKey(note.bookId) ||
            !bookBox.containsKey(note.bookId)) {
          continue;
        }
        final cloudData = cloudNoteDocMap[note.id];
        if (cloudData == null) {
          notesToUpload.add(note);
        } else if (cloudData['isDeleted'] == true) {
          final cloudDeletedTime = DateTime.tryParse(
            cloudData['updatedAt']?.toString() ?? '',
          );
          final localTime = note.updatedAt ?? note.createdAt;
          if (cloudDeletedTime != null && localTime.isAfter(cloudDeletedTime)) {
            notesToUpload.add(note);
          }
        } else {
          try {
            final cloudNote = Note.fromMap(cloudData);
            final cloudTime = cloudNote.updatedAt ?? cloudNote.createdAt;
            final localTime = note.updatedAt ?? note.createdAt;
            if (localTime.isAfter(cloudTime) ||
                (localTime.isAtSameMomentAs(cloudTime) &&
                    !_isSameNoteContent(note, cloudNote))) {
              notesToUpload.add(note);
            }
          } catch (_) {
            notesToUpload.add(note);
          }
        }
      }

      int booksUploaded = 0;
      int notesUploaded = 0;

      if (currentUserId != uid ||
          (!allowDuringSignOut && _signingOut) ||
          store.signOutPending) {
        return const SyncResult(
          success: false,
          errorMessage: '동기화 도중 계정이 변경되었습니다.',
        );
      }

      if (booksToUpload.isNotEmpty ||
          notesToUpload.isNotEmpty ||
          pendingCloudBookDeletes.isNotEmpty ||
          pendingCloudNoteDeletes.isNotEmpty) {
        final booksCol = _booksCollection(uid);
        final notesCol = _notesCollection(uid);
        final allOperations = <void Function(WriteBatch)>[
          ...booksToUpload.map((book) {
            booksUploaded++;
            return (WriteBatch batch) {
              final map = book.toMap();
              map['isDeleted'] = false;
              batch.set(booksCol.doc(book.id), map, SetOptions(merge: true));
            };
          }),
          ...notesToUpload.map((note) {
            notesUploaded++;
            return (WriteBatch batch) {
              final map = note.toMap();
              map['isDeleted'] = false;
              batch.set(notesCol.doc(note.id), map, SetOptions(merge: true));
            };
          }),
          ...pendingCloudBookDeletes.entries.map((entry) {
            return (WriteBatch batch) {
              batch.set(booksCol.doc(entry.key), {
                'id': entry.key,
                'isDeleted': true,
                'updatedAt': entry.value,
              }, SetOptions(merge: true));
            };
          }),
          ...pendingCloudNoteDeletes.entries.map((entry) {
            return (WriteBatch batch) {
              batch.set(notesCol.doc(entry.key), {
                'id': entry.key,
                'isDeleted': true,
                'updatedAt': entry.value,
              }, SetOptions(merge: true));
            };
          }),
        ];

        for (var i = 0; i < allOperations.length; i += 500) {
          final batch = _firestore.batch();
          final end = (i + 500 < allOperations.length)
              ? i + 500
              : allOperations.length;
          for (var j = i; j < end; j++) {
            allOperations[j](batch);
          }
          await batch.commit().timeout(const Duration(seconds: 15));
        }
        await _firestore.waitForPendingWrites().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
        developer.log(
          'Pushed $booksUploaded books, $notesUploaded notes to Cloud.',
          name: 'FirebaseService',
        );
      }

      // 연동된 계정인 경우 백그라운드 실시간 동기화 리스너 활성화
      if (isLinked && !_linking && !_signingOut && !store.signOutPending) {
        startRealtimeSync(hiveService);
      }

      return SyncResult(
        success: true,
        booksDownloaded: booksDownloaded,
        notesDownloaded: notesDownloaded,
        booksUploaded: booksUploaded,
        notesUploaded: notesUploaded,
      );
    } catch (e) {
      developer.log('Initial sync error: $e', name: 'FirebaseService');
      final errStr = e.toString().replaceFirst('Exception: ', '');
      return SyncResult(success: false, errorMessage: errStr);
    }
  }

  /// 클라우드와 로컬 간 수동 동기화 실행 (당겨서 새로고침 / 새로고침 버튼용)
  Future<SyncResult> syncWithCloud(HiveService hiveService) async {
    if (_linking || _signingOut || store.signOutPending) {
      return const SyncResult(success: false, errorMessage: '계정 변경 중입니다.');
    }
    await init();
    if (!_isInitialized || currentUserId == null) {
      return const SyncResult(
        success: false,
        errorMessage: 'Firebase에 연결되지 않았거나 사용자가 인증되지 않았습니다.',
      );
    }
    return await initialSyncWithHive(hiveService);
  }

  /// 오프라인이었다가 온라인으로 복귀했을 때 로컬 전체를 클라우드로 안전 재동기화
  Future<SyncResult> syncAllLocalToCloud(HiveService hiveService) async {
    if (_linking || _signingOut || store.signOutPending) {
      return const SyncResult(success: false, errorMessage: '계정 변경 중입니다.');
    }
    await init();
    return await initialSyncWithHive(hiveService);
  }
}
