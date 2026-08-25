import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../../domain/repositories/book_repository.dart';
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

/// 도서 정보가 포함된 독서 노트 DTO
class NoteWithBook {
  final Note note;
  final Book book;

  const NoteWithBook({
    required this.note,
    required this.book,
  });
}

/// 모든 도서의 노트를 도서 정보와 결합하여 최신 작성순으로 제공하는 프로바이더
final allNotesWithBookProvider = Provider<AsyncValue<List<NoteWithBook>>>((ref) {
  final notesAsync = ref.watch(allNotesStreamProvider);
  final booksAsync = ref.watch(allBooksStreamProvider);

  if (notesAsync.isLoading || booksAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (notesAsync.hasError) {
    return AsyncValue.error(notesAsync.error!, notesAsync.stackTrace!);
  }
  if (booksAsync.hasError) {
    return AsyncValue.error(booksAsync.error!, booksAsync.stackTrace!);
  }

  final notes = notesAsync.value ?? [];
  final books = booksAsync.value ?? [];
  final bookMap = {for (final b in books) b.id: b};

  final list = <NoteWithBook>[];
  for (final note in notes) {
    final book = bookMap[note.bookId];
    if (book != null) {
      list.add(NoteWithBook(note: note, book: book));
    }
  }

  // 최신 작성순 정렬
  list.sort((a, b) => b.note.createdAt.compareTo(a.note.createdAt));
  return AsyncValue.data(list);
});

/// 한줄 피드 검색어 프로바이더
final quoteFeedSearchQueryProvider = StateProvider<String>((ref) => '');

/// 한줄 피드 선택된 도서 필터 프로바이더 (null이면 전체)
final quoteFeedSelectedBookIdProvider = StateProvider<String?>((ref) => null);

/// 검색 및 도서 필터가 적용된 한줄 피드 목록 프로바이더
final filteredQuoteFeedProvider = Provider<AsyncValue<List<NoteWithBook>>>((ref) {
  final allNotesWithBookAsync = ref.watch(allNotesWithBookProvider);
  final query = ref.watch(quoteFeedSearchQueryProvider).trim().toLowerCase();
  final selectedBookId = ref.watch(quoteFeedSelectedBookIdProvider);

  return allNotesWithBookAsync.whenData((items) {
    return items.where((item) {
      // 1. 도서 필터
      if (selectedBookId != null && item.book.id != selectedBookId) {
        return false;
      }
      // 2. 검색어 필터 (발췌문, 메모 내용, 도서 제목, 저자 모두 검색)
      if (query.isNotEmpty) {
        final matchQuote = item.note.quotation.toLowerCase().contains(query);
        final matchContent = item.note.content.toLowerCase().contains(query);
        final matchTitle = item.book.title.toLowerCase().contains(query);
        final matchAuthor = item.book.author.toLowerCase().contains(query);
        return matchQuote || matchContent || matchTitle || matchAuthor;
      }
      return true;
    }).toList();
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
  final BookRepository _bookRepository;
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

  /// 독서 노트 수정
  Future<bool> updateNote(Note updatedNote) async {
    state = const AsyncValue.loading();
    try {
      await _noteRepository.updateNote(updatedNote);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// 독서 노트 삭제
  Future<bool> deleteNote(String noteId) async {
    state = const AsyncValue.loading();
    try {
      await _noteRepository.deleteNote(noteId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
