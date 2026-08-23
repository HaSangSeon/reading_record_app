import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../../domain/repositories/note_repository.dart';
import '../../providers/repository_providers.dart';

/// 특정 도서(bookId)의 상세 실시간 데이터 프로바이더
final singleBookStreamProvider =
    StreamProvider.family<Book?, String>((ref, bookId) {
  final allBooksAsync = ref.watch(allBooksStreamProvider);
  return allBooksAsync.when(
    data: (books) {
      final matches = books.where((b) => b.id == bookId);
      return Stream.value(matches.isNotEmpty ? matches.first : null);
    },
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
});

/// 독서 노트 정렬 기준 (페이지순 / 최신 작성순)
enum NoteSortOrder { byPage, byDate }

final noteSortOrderProvider =
    StateProvider.family<NoteSortOrder, String>((ref, bookId) => NoteSortOrder.byPage);

/// 정렬이 적용된 특정 도서의 독서 노트 목록 프로바이더
final sortedNotesProvider =
    Provider.family<AsyncValue<List<Note>>, String>((ref, bookId) {
  final notesAsync = ref.watch(notesByBookStreamProvider(bookId));
  final sortOrder = ref.watch(noteSortOrderProvider(bookId));

  return notesAsync.whenData((notes) {
    final list = List<Note>.from(notes);
    if (sortOrder == NoteSortOrder.byPage) {
      list.sort((a, b) {
        final pageComp = a.pageNumber.compareTo(b.pageNumber);
        if (pageComp != 0) return pageComp;
        return a.createdAt.compareTo(b.createdAt);
      });
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  });
});

/// 독서 노트 CRUD 컨트롤러
final noteControllerProvider =
    StateNotifierProvider<NoteController, AsyncValue<void>>((ref) {
  final noteRepo = ref.watch(noteRepositoryProvider);
  final bookRepo = ref.watch(bookRepositoryProvider);
  return NoteController(noteRepo, bookRepo);
});

class NoteController extends StateNotifier<AsyncValue<void>> {
  final NoteRepository _noteRepository;
  final dynamic _bookRepository;
  final Uuid _uuid = const Uuid();

  NoteController(this._noteRepository, this._bookRepository)
      : super(const AsyncValue.data(null));

  /// 새 독서 노트 추가
  Future<bool> addNote({
    required String bookId,
    required int pageNumber,
    required String content,
    String quotation = '',
    bool updateBookPageIfHigher = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final newNote = Note(
        id: _uuid.v4(),
        bookId: bookId,
        pageNumber: pageNumber,
        content: content.trim(),
        quotation: quotation.trim(),
        createdAt: now,
      );

      await _noteRepository.addNote(newNote);

      // 노트 기록 시 책의 현재 읽은 페이지 수가 더 적다면 자동 업데이트
      if (updateBookPageIfHigher && pageNumber > 0) {
        final book = await _bookRepository.getBookById(bookId);
        if (book != null && pageNumber > book.readPages) {
          final isCompleted =
              book.totalPages > 0 && pageNumber >= book.totalPages;
          await _bookRepository.updateBook(
            book.copyWith(
              readPages: pageNumber,
              isCompleted: isCompleted || book.isCompleted,
              completedAt: isCompleted ? (book.completedAt ?? now) : null,
            ),
          );
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 기존 독서 노트 수정
  Future<bool> updateNote(Note note) async {
    state = const AsyncValue.loading();
    try {
      final updated = note.copyWith(updatedAt: DateTime.now());
      await _noteRepository.updateNote(updated);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 특정 독서 노트 삭제
  Future<bool> deleteNote(String id) async {
    state = const AsyncValue.loading();
    try {
      await _noteRepository.deleteNote(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
