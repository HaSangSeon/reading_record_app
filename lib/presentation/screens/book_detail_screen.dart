import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../controllers/book_controller.dart';
import '../controllers/note_controller.dart';
import '../widgets/book_form_dialog.dart';
import '../widgets/note_card.dart';
import '../widgets/note_form_dialog.dart';
import '../widgets/reading_progress_dialog.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(singleBookStreamProvider(bookId));
    final notesAsync = ref.watch(sortedNotesProvider(bookId));
    final sortOrder = ref.watch(noteSortOrderProvider(bookId));

    return bookAsync.when(
      data: (book) {
        if (book == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('도서를 찾을 수 없습니다.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('돌아가기'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  book.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  color: book.isCompleted
                      ? AppTheme.successColor
                      : AppTheme.textSecondary,
                ),
                tooltip: book.isCompleted ? '읽는 중으로 변경' : '완독으로 표시',
                onPressed: () => ref
                    .read(bookControllerProvider.notifier)
                    .toggleCompletion(book.id),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) async {
                  if (value == 'edit') {
                    BookFormDialog.show(context, book: book);
                  } else if (value == 'delete') {
                    _showDeleteConfirm(context, ref, book);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('도서 정보 수정'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('도서 삭제', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // 도서 기본 정보 & 진행률 헤더
              SliverToBoxAdapter(
                child: _buildBookHeader(context, ref, book),
              ),

              // 독서 노트 섹션 타이틀 및 정렬 토글
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      notesAsync.when(
                        data: (notes) => Row(
                          children: [
                            const Icon(Icons.edit_note_rounded,
                                color: AppTheme.primaryColor, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              '독서 기록 (${notes.length})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const Text('독서 기록 불러오는 중...'),
                        error: (err, stack) => const Text('독서 기록'),
                      ),
                      // 정렬 전환 버튼
                      TextButton.icon(
                        onPressed: () {
                          final current =
                              ref.read(noteSortOrderProvider(bookId));
                          ref
                              .read(noteSortOrderProvider(bookId).notifier)
                              .state = current == NoteSortOrder.byPage
                              ? NoteSortOrder.byDate
                              : NoteSortOrder.byPage;
                        },
                        icon: const Icon(Icons.sort_rounded, size: 16),
                        label: Text(
                          sortOrder == NoteSortOrder.byPage
                              ? '페이지순'
                              : '최신 작성순',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 독서 노트 목록
              notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyNotes(context, book),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 90),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = notes[index];
                          return NoteCard(book: book, note: note);
                        },
                        childCount: notes.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Center(child: Text('노트를 불러오지 못했습니다: $err')),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => NoteFormDialog.show(context, book: book),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('기록 남기기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('오류 발생: $err')),
      ),
    );
  }

  Widget _buildBookHeader(BuildContext context, WidgetRef ref, Book book) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final registeredDate = dateFormat.format(book.createdAt);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 도서 표지
              Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildFallbackCover(book),
                      )
                    : _buildFallbackCover(book),
              ),
              const SizedBox(width: 16),
              // 도서 메타데이터
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (book.publisher.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.publisher,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // 별점
                    if (book.rating > 0)
                      Row(
                        children: [
                          ...List.generate(5, (idx) {
                            return Icon(
                              idx < book.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                              color: AppTheme.accentColor,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            book.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '등록일: $registeredDate',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 14),

          // 독서 진행률 바 및 퀵 기록 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: book.isCompleted
                          ? AppTheme.successColor.withValues(alpha: 0.12)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      book.isCompleted
                          ? '🎉 완독 완료'
                          : '📖 ${book.progressPercentage}% 진행 중',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: book.isCompleted
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    book.totalPages > 0
                        ? '${book.readPages} / ${book.totalPages} p'
                        : '${book.readPages} p',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => ReadingProgressDialog.show(context, book),
                icon: const Icon(Icons.bookmark_added_outlined, size: 16),
                label: const Text('페이지 수정', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: book.progress,
              minHeight: 8,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                book.isCompleted
                    ? AppTheme.successColor
                    : AppTheme.primaryColor,
              ),
            ),
          ),

          // 한 줄 평 / 책 메모가 있는 경우 표시
          if (book.memo.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt_rounded,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.memo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackCover(Book book) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            book.isCompleted
                ? Icons.auto_stories_rounded
                : Icons.menu_book_rounded,
            color: AppTheme.primaryColor.withValues(alpha: 0.6),
            size: 36,
          ),
          const SizedBox(height: 4),
          Text(
            book.isCompleted ? '완독' : '읽는 중',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotes(BuildContext context, Book book) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 작성된 독서 노트가 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '기억하고 싶은 문장이나 느낀 점을\n자유롭게 기록해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => NoteFormDialog.show(context, book: book),
              icon: const Icon(Icons.add_rounded),
              label: const Text('첫 기록 남기기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('도서 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '\'${book.title}\' 도서와 작성된 모든 독서 기록이 함께 삭제됩니다. 정말 삭제하시겠습니까?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(bookControllerProvider.notifier).deleteBook(book.id);
              if (context.mounted) {
                Navigator.pop(context); // 도서 상세 화면에서 나가기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('도서가 삭제되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
