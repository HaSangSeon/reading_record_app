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
  Future<SyncResult?> signInOrLinkWithGoogle(HiveService hiveService) async {
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
        developer.log('Google Sign In cancelled by user', name: 'FirebaseService');
        return null;
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
          // 연동 후 로컬과 클라우드 양방향 완전 동기화 진행
          return await initialSyncWithHive(hiveService);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // [태블릿 시나리오] 이미 다른 기기(스마트폰)에서 이 구글 계정을 연동해둔 상태
            developer.log('Credential already in use, signing in instead (Pad scenario)', name: 'FirebaseService');
            // 기존 익명 계정을 버리고 정식 구글 계정으로 로그인
            await _auth.signInWithCredential(credential);
            // 로그인 후 클라우드 데이터를 로컬로 병합 동기화
            return await initialSyncWithHive(hiveService);
          } else {
            rethrow;
          }
        }
      } else {
        // 이미 익명이 아니거나(버그), 로그아웃된 상태
        await _auth.signInWithCredential(credential);
        return await initialSyncWithHive(hiveService);
      }
    } catch (e) {
      developer.log('Google Sign-In/Link error: $e', name: 'FirebaseService');
      rethrow;
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
          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;

            final isDeleted = data['isDeleted'] == true;
            final docId = change.doc.id;

            if (isDeleted || change.type == DocumentChangeType.removed) {
              final localBook = bookBox.get(docId);
              if (localBook != null) {
                final cloudDeletedTime = DateTime.tryParse(
                  data['updatedAt']?.toString() ?? '',
                );
                final localTime = localBook.updatedAt ?? localBook.createdAt;
                if (cloudDeletedTime == null ||
                    !localTime.isAfter(cloudDeletedTime)) {
                  bookBox.delete(docId);
                  developer.log('Realtime delete book: $docId', name: 'FirebaseService');
                }
              }
            } else {
              try {
                final cloudBook = Book.fromMap(data);
                final localBook = bookBox.get(docId);
                final cloudTime = cloudBook.updatedAt ?? cloudBook.createdAt;
                final localTime = localBook != null
                    ? (localBook.updatedAt ?? localBook.createdAt)
                    : null;

                if (localBook == null || cloudTime.isAfter(localTime!)) {
                  bookBox.put(docId, cloudBook);
                  developer.log('Realtime sync book: $docId', name: 'FirebaseService');
                }
              } catch (e) {
                developer.log('Realtime book parse error: $e', name: 'FirebaseService');
              }
            }
          }
        },
        onError: (e) {
          developer.log('Books realtime sync error: $e', name: 'FirebaseService');
        },
      );

      _notesSubscription = _notesCollection().snapshots().listen(
        (snapshot) {
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
                  developer.log('Realtime delete note: $docId', name: 'FirebaseService');
                }
              }
            } else {
              try {
                final cloudNote = Note.fromMap(data);
                final localNote = noteBox.get(docId);
                final cloudTime = cloudNote.updatedAt ?? cloudNote.createdAt;
                final localTime = localNote != null
                    ? (localNote.updatedAt ?? localNote.createdAt)
                    : null;

                if (localNote == null || cloudTime.isAfter(localTime!)) {
                  noteBox.put(docId, cloudNote);
                  developer.log('Realtime sync note: $docId', name: 'FirebaseService');
                }
              } catch (e) {
                developer.log('Realtime note parse error: $e', name: 'FirebaseService');
              }
            }
          }
        },
        onError: (e) {
          developer.log('Notes realtime sync error: $e', name: 'FirebaseService');
        },
      );
      developer.log('Started realtime sync listeners.', name: 'FirebaseService');
    } catch (e) {
      developer.log('Failed to start realtime sync: $e', name: 'FirebaseService');
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
    try {
      stopRealtimeSync();
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
      final map = book.toMap();
      map['isDeleted'] = false;
      await _booksCollection().doc(book.id).set(
            map,
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('Error saving book to Firestore: $e', name: 'FirebaseService');
    }
  }

  /// 소프트 딜리트(Soft Delete): 클라우드에 삭제 상태를 기록하여 다른 기기에서도 부활하지 않고 안전하게 삭제되도록 함
  Future<void> deleteBook(String bookId) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      await _booksCollection().doc(bookId).set({
        'id': bookId,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('Error deleting book from Firestore: $e', name: 'FirebaseService');
    }
  }

  // --- 독서 노트 동기화 ---

  Future<void> saveNote(Note note) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      final map = note.toMap();
      map['isDeleted'] = false;
      await _notesCollection().doc(note.id).set(
            map,
            SetOptions(merge: true),
          );
    } catch (e) {
      developer.log('Error saving note to Firestore: $e', name: 'FirebaseService');
    }
  }

  /// 소프트 딜리트(Soft Delete): 클라우드에 삭제 상태를 기록하여 다른 기기에서도 부활하지 않도록 함
  Future<void> deleteNote(String noteId) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      await _notesCollection().doc(noteId).set({
        'id': noteId,
        'isDeleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('Error deleting note from Firestore: $e', name: 'FirebaseService');
    }
  }

  static const String _deletedBooksKey = 'deleted_books_tombstones';
  static const String _deletedNotesKey = 'deleted_notes_tombstones';

  /// 로컬에서 삭제된 항목의 타임스탬프를 기록 (오프라인 상태 삭제 후 재접속 시 부활 방지)
  Future<void> recordLocalBookDeletion(HiveService hiveService, String bookId) async {
    try {
      final box = hiveService.settingsBox;
      final raw = box.get(_deletedBooksKey);
      final map = raw is Map ? Map<String, String>.from(raw) : <String, String>{};
      map[bookId] = DateTime.now().toIso8601String();
      await box.put(_deletedBooksKey, map);
    } catch (_) {}
  }

  Future<void> clearLocalBookDeletion(HiveService hiveService, String bookId) async {
    try {
      final box = hiveService.settingsBox;
      final raw = box.get(_deletedBooksKey);
      if (raw is Map && raw.containsKey(bookId)) {
        final map = Map<String, String>.from(raw)..remove(bookId);
        await box.put(_deletedBooksKey, map);
      }
    } catch (_) {}
  }

  Future<void> recordLocalNoteDeletion(HiveService hiveService, List<String> noteIds) async {
    if (noteIds.isEmpty) return;
    try {
      final box = hiveService.settingsBox;
      final raw = box.get(_deletedNotesKey);
      final map = raw is Map ? Map<String, String>.from(raw) : <String, String>{};
      final now = DateTime.now().toIso8601String();
      for (final id in noteIds) {
        map[id] = now;
      }
      await box.put(_deletedNotesKey, map);
    } catch (_) {}
  }

  Future<void> clearLocalNoteDeletion(HiveService hiveService, String noteId) async {
    try {
      final box = hiveService.settingsBox;
      final raw = box.get(_deletedNotesKey);
      if (raw is Map && raw.containsKey(noteId)) {
        final map = Map<String, String>.from(raw)..remove(noteId);
        await box.put(_deletedNotesKey, map);
      }
    } catch (_) {}
  }

  Future<void> deleteNotesByBookId(
    String bookId, {
    List<String> noteIds = const [],
  }) async {
    if (!_isInitialized || currentUserId == null) return;
    try {
      final nowIso = DateTime.now().toIso8601String();
      final targetRefs = <String, DocumentReference<Map<String, dynamic>>>{
        for (final id in noteIds) id: _notesCollection().doc(id),
      };

      try {
        final querySnapshot =
            await _notesCollection().where('bookId', isEqualTo: bookId).get();
        for (final doc in querySnapshot.docs) {
          targetRefs[doc.id] = doc.reference;
        }
      } catch (_) {
        // 오프라인 등으로 쿼리 실패 시에도 전달받은 noteIds로 삭제 보장
      }

      final refs = targetRefs.values.toList();
      for (var i = 0; i < refs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < refs.length) ? i + 500 : refs.length;
        for (var j = i; j < end; j++) {
          batch.set(refs[j], {
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
  Future<SyncResult> initialSyncWithHive(HiveService hiveService) async {
    if (!_isInitialized || currentUserId == null) {
      return const SyncResult(
        success: false,
        errorMessage: '로그인이 필요하거나 Firebase 서비스가 준비되지 않았습니다.',
      );
    }

    try {
      final bookBox = hiveService.bookBox;
      final noteBox = hiveService.noteBox;
      final settingsBox = hiveService.settingsBox;

      final rawDeletedBooks = settingsBox.get(_deletedBooksKey);
      final localDeletedBooks = rawDeletedBooks is Map
          ? Map<String, String>.from(rawDeletedBooks)
          : <String, String>{};

      final rawDeletedNotes = settingsBox.get(_deletedNotesKey);
      final localDeletedNotes = rawDeletedNotes is Map
          ? Map<String, String>.from(rawDeletedNotes)
          : <String, String>{};

      final pendingCloudBookDeletes = <String, String>{};
      final pendingCloudNoteDeletes = <String, String>{};

      // 1. 클라우드 데이터 전체 조회
      final cloudBooksSnapshot = await _booksCollection().get();
      final cloudNotesSnapshot = await _notesCollection().get();

      final cloudBookDocMap = <String, Map<String, dynamic>>{};
      int booksDownloaded = 0;

      for (final doc in cloudBooksSnapshot.docs) {
        final data = doc.data();
        cloudBookDocMap[doc.id] = data;

        final isDeleted = data['isDeleted'] == true;
        if (isDeleted) {
          // 다른 기기에서 삭제된 항목 -> 로컬이 더 최신(백업 복원 등)이 아닌 경우에만 로컬에서 삭제
          final localBook = bookBox.get(doc.id);
          if (localBook != null) {
            final cloudDeletedTime = DateTime.tryParse(
              data['updatedAt']?.toString() ?? '',
            );
            final localTime = localBook.updatedAt ?? localBook.createdAt;
            if (cloudDeletedTime == null ||
                !localTime.isAfter(cloudDeletedTime)) {
              await bookBox.delete(doc.id);
            }
          }
        } else {
          try {
            final cloudBook = Book.fromMap(data);
            final localBook = bookBox.get(cloudBook.id);
            final cloudTime = cloudBook.updatedAt ?? cloudBook.createdAt;

            // 오프라인 상태에서 로컬에서 삭제했던 도서인지 확인
            final localDeletedIso = localDeletedBooks[cloudBook.id];
            final localDeletedTime = localDeletedIso != null
                ? DateTime.tryParse(localDeletedIso)
                : null;

            if (localBook == null &&
                localDeletedTime != null &&
                localDeletedTime.isAfter(cloudTime)) {
              // 로컬에서 더 최근에 삭제된 항목 -> 클라우드에서 부활시키지 않고 클라우드도 삭제 마킹 예약
              pendingCloudBookDeletes[cloudBook.id] = localDeletedIso!;
            } else {
              final localTime = localBook != null
                  ? (localBook.updatedAt ?? localBook.createdAt)
                  : null;

              if (localBook == null || cloudTime.isAfter(localTime!)) {
                await bookBox.put(cloudBook.id, cloudBook);
                booksDownloaded++;
              }
            }
          } catch (e) {
            developer.log('Error parsing book (${doc.id}): $e', name: 'FirebaseService');
          }
        }
      }

      final cloudNoteDocMap = <String, Map<String, dynamic>>{};
      int notesDownloaded = 0;

      for (final doc in cloudNotesSnapshot.docs) {
        final data = doc.data();
        cloudNoteDocMap[doc.id] = data;

        final isDeleted = data['isDeleted'] == true;
        if (isDeleted) {
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
            final cloudNote = Note.fromMap(data);
            final localNote = noteBox.get(cloudNote.id);
            final cloudTime = cloudNote.updatedAt ?? cloudNote.createdAt;

            final localDeletedIso = localDeletedNotes[cloudNote.id];
            final localDeletedTime = localDeletedIso != null
                ? DateTime.tryParse(localDeletedIso)
                : null;

            if (localNote == null &&
                localDeletedTime != null &&
                localDeletedTime.isAfter(cloudTime)) {
              pendingCloudNoteDeletes[cloudNote.id] = localDeletedIso!;
            } else {
              final localTime = localNote != null
                  ? (localNote.updatedAt ?? localNote.createdAt)
                  : null;

              if (localNote == null || cloudTime.isAfter(localTime!)) {
                await noteBox.put(cloudNote.id, cloudNote);
                notesDownloaded++;
              }
            }
          } catch (e) {
            developer.log('Error parsing note (${doc.id}): $e', name: 'FirebaseService');
          }
        }
      }

      developer.log(
        'Synced from Cloud: $booksDownloaded books, $notesDownloaded notes downloaded/updated.',
        name: 'FirebaseService',
      );

      // 2. 로컬 데이터 중 클라우드에 아직 없거나 로컬이 더 최신인 항목만 선별하여 클라우드로 업로드
      final booksToUpload = <Book>[];
      for (final book in bookBox.values) {
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
            if (localTime.isAfter(cloudTime)) {
              booksToUpload.add(book);
            }
          } catch (_) {
            booksToUpload.add(book);
          }
        }
      }

      final notesToUpload = <Note>[];
      for (final note in noteBox.values) {
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
            if (localTime.isAfter(cloudTime)) {
              notesToUpload.add(note);
            }
          } catch (_) {
            notesToUpload.add(note);
          }
        }
      }

      int booksUploaded = 0;
      int notesUploaded = 0;

      if (booksToUpload.isNotEmpty ||
          notesToUpload.isNotEmpty ||
          pendingCloudBookDeletes.isNotEmpty ||
          pendingCloudNoteDeletes.isNotEmpty) {
        final allOperations = <void Function(WriteBatch)>[
          ...booksToUpload.map((book) {
            booksUploaded++;
            return (WriteBatch batch) {
              final map = book.toMap();
              map['isDeleted'] = false;
              batch.set(
                _booksCollection().doc(book.id),
                map,
                SetOptions(merge: true),
              );
            };
          }),
          ...notesToUpload.map((note) {
            notesUploaded++;
            return (WriteBatch batch) {
              final map = note.toMap();
              map['isDeleted'] = false;
              batch.set(
                _notesCollection().doc(note.id),
                map,
                SetOptions(merge: true),
              );
            };
          }),
          ...pendingCloudBookDeletes.entries.map((entry) {
            return (WriteBatch batch) {
              batch.set(
                _booksCollection().doc(entry.key),
                {
                  'id': entry.key,
                  'isDeleted': true,
                  'updatedAt': entry.value,
                },
                SetOptions(merge: true),
              );
            };
          }),
          ...pendingCloudNoteDeletes.entries.map((entry) {
            return (WriteBatch batch) {
              batch.set(
                _notesCollection().doc(entry.key),
                {
                  'id': entry.key,
                  'isDeleted': true,
                  'updatedAt': entry.value,
                },
                SetOptions(merge: true),
              );
            };
          }),
        ];

        for (var i = 0; i < allOperations.length; i += 500) {
          final batch = _firestore.batch();
          final end = (i + 500 < allOperations.length) ? i + 500 : allOperations.length;
          for (var j = i; j < end; j++) {
            allOperations[j](batch);
          }
          await batch.commit();
        }
        developer.log(
          'Pushed $booksUploaded books, $notesUploaded notes to Cloud.',
          name: 'FirebaseService',
        );
      }

      // 연동된 계정인 경우 백그라운드 실시간 동기화 리스너 활성화
      if (isLinked) {
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
      return SyncResult(
        success: false,
        errorMessage: errStr,
      );
    }
  }

  /// 클라우드와 로컬 간 수동 동기화 실행 (당겨서 새로고침 / 새로고침 버튼용)
  Future<SyncResult> syncWithCloud(HiveService hiveService) async {
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
    if (!_isInitialized || currentUserId == null) {
      return const SyncResult(
        success: false,
        errorMessage: 'Firebase에 연결되지 않았습니다.',
      );
    }
    return await initialSyncWithHive(hiveService);
  }
}
