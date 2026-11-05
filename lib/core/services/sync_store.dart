import '../database/hive_service.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';

/// Serializes Hive mutations, while allowing local writes during network waits.
class SyncStore {
  SyncStore(this.hive);
  final HiveService hive;
  static const deletedBooksKey = 'deleted_books_tombstones';
  static const deletedNotesKey = 'deleted_notes_tombstones';
  static const signOutKey = 'pending_account_signout';
  Future<void> _tail = Future.value();
  bool accountChanging = false;

  Future<void> get pendingWrites => _tail;
  bool get signOutPending => hive.settingsBox.get(signOutKey) != null;

  Future<T> serial<T>(Future<T> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<T> edit<T>(Future<T> Function() action) {
    if (accountChanging || signOutPending) {
      return Future.error(StateError('계정 변경 중입니다. 잠시 후 다시 시도해 주세요.'));
    }
    return serial(() async {
      if (accountChanging || signOutPending) {
        throw StateError('계정 변경 중입니다. 잠시 후 다시 시도해 주세요.');
      }
      return await action();
    });
  }

  Map<String, String> deletions(String collection) {
    final raw = hive.settingsBox.get(
      collection == 'books' ? deletedBooksKey : deletedNotesKey,
    );
    return raw is Map ? Map<String, String>.from(raw) : {};
  }

  Future<void> markDeleted(
    String collection,
    Iterable<String> ids,
    String time,
  ) async {
    final map = deletions(collection);
    for (final id in ids) {
      map[id] = time;
    }
    await hive.settingsBox.put(
      collection == 'books' ? deletedBooksKey : deletedNotesKey,
      map,
    );
  }

  Future<void> saveBook(Book book) => edit(() async {
    if (deletions('books').containsKey(book.id)) {
      throw StateError('삭제된 도서입니다. 새 도서로 등록해 주세요.');
    }
    await hive.bookBox.put(book.id, book);
  });

  Future<void> saveNote(Note note) => edit(() async {
    if (deletions('notes').containsKey(note.id) ||
        deletions('books').containsKey(note.bookId) ||
        !hive.bookBox.containsKey(note.bookId)) {
      throw StateError('도서 또는 기록이 삭제되었습니다.');
    }
    await hive.noteBox.put(note.id, note);
  });

  Future<List<String>> deleteBook(String id) => edit(() async {
    // Persist intent before removing anything. Recovery completes the cascade.
    final now = DateTime.now().toUtc().toIso8601String();
    final noteIds = hive.noteBox.values
        .where((n) => n.bookId == id)
        .map((n) => n.id)
        .toList();
    await markDeleted('books', [id], now);
    if (noteIds.isNotEmpty) {
      await markDeleted('notes', noteIds, now);
    }
    await recoverDeletions();
    return noteIds;
  });

  Future<void> deleteNotes(Iterable<String> ids) => edit(() async {
    await markDeleted('notes', ids, DateTime.now().toUtc().toIso8601String());
    await recoverDeletions();
  });

  Future<List<String>> deleteNotesByBookId(String bookId) => edit(() async {
    final noteIds = hive.noteBox.values
        .where((n) => n.bookId == bookId)
        .map((n) => n.id)
        .toList();
    if (noteIds.isNotEmpty) {
      await markDeleted(
        'notes',
        noteIds,
        DateTime.now().toUtc().toIso8601String(),
      );
    }
    await recoverDeletions();
    return noteIds;
  });

  Future<void> recoverDeletions() async {
    final books = deletions('books');
    for (final entry in books.entries) {
      final notes = hive.noteBox.values
          .where((n) => n.bookId == entry.key)
          .map((n) => n.id)
          .toList();
      if (notes.isNotEmpty) await markDeleted('notes', notes, entry.value);
    }
    await hive.noteBox.deleteAll(deletions('notes').keys);
    await hive.bookBox.deleteAll(books.keys);
  }
}
