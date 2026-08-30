import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../controllers/book_controller.dart';
import '../controllers/note_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/action_bottom_sheet.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/book_form_dialog.dart';
import '../widgets/custom_confirm_dialog.dart';
import '../widgets/note_card.dart';
import '../widgets/note_form_dialog.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            flexibleSpace: AppTheme.buildAppBarFlexibleSpace(isDark),
            title: Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                  color: isDark ? Colors.amberAccent : AppTheme.textSecondary,
                ),
                tooltip: isDark ? '라이트 모드로 전환' : '다크 모드로 전환',
                onPressed: () => ref
                    .read(themeControllerProvider.notifier)
                    .toggleTheme(context),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: '도서 옵션',
                onPressed: () {
                  ActionBottomSheet.showBookActions(
                    context,
                    book: book,
                    onToggleComplete: () async {
                      await ref
                          .read(bookControllerProvider.notifier)
                          .toggleCompletion(book.id);
                    },
                    onEdit: () {
                      BookFormDialog.show(context, book: book);
                    },
                    onDelete: () {
                      _showDeleteConfirm(context, ref, book);
                    },
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // 도서 기본 정보 & 진행률 헤더
              SliverToBoxAdapter(child: _buildBookHeader(context, ref, book)),

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
                            Icon(
                              Icons.edit_note_rounded,
                              color: isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '독서 기록 (${notes.length})',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary,
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
                          final current = ref.read(
                            noteSortOrderProvider(bookId),
                          );
                          ref
                              .read(noteSortOrderProvider(bookId).notifier)
                              .state = current == NoteSortOrder.byPage
                              ? NoteSortOrder.byDate
                              : NoteSortOrder.byPage;
                        },
                        icon: const Icon(Icons.sort_rounded, size: 16),
                        label: Text(
                          sortOrder == NoteSortOrder.byPage ? '페이지순' : '최신 작성순',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
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
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final note = notes[index];
                        return NoteCard(book: book, note: note);
                      }, childCount: notes.length),
                    ),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                      ),
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
            label: const Text(
              '기록 남기기',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(isSubScreen: true),
        );
      },
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
          ),
        ),
      ),
      error: (err, _) => Scaffold(body: Center(child: Text('오류 발생: $err'))),
    );
  }

  Widget _buildBookHeader(BuildContext context, WidgetRef ref, Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('yyyy.MM.dd');
    final registeredDate = dateFormat.format(book.createdAt);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFEDF0F5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 도서 표지 (양장본 3D 스파인 효과)
              Container(
                width: 92,
                height: 136,
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.4 : 0.12,
                      ),
                      blurRadius: 12,
                      offset: const Offset(2, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    () {
                      final cover = book.coverUrl;
                      if (cover == null || cover.isEmpty) {
                        return _buildFallbackCover(book, context);
                      }
                      if (cover.startsWith('http://') ||
                          cover.startsWith('https://')) {
                        return Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _buildFallbackCover(book, context),
                        );
                      }
                      return Image.file(
                        File(cover),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _buildFallbackCover(book, context),
                      );
                    }(),
                    // 책등(Spine) 음영 효과
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.32),
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 도서 메타데이터
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    if (book.publisher.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.publisher,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textLight,
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
                              size: 17,
                              color: const Color(0xFFF59E0B),
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            book.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '등록일 $registeredDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextLight
                            : AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? AppTheme.darkBorder : const Color(0xFFEDF0F5),
          ),
          const SizedBox(height: 14),

          // 독서 상태 및 완독 전환 바 (균형 잡힌 레이아웃 & 높이 통일)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 독서 상태 뱃지
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: book.isCompleted
                        ? AppTheme.successColor.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          )
                        : (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: isDark ? 0.22 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        book.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.auto_stories_rounded,
                        size: 17,
                        color: book.isCompleted
                            ? AppTheme.successColor
                            : (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        book.isCompleted ? '완독 완료' : '읽는 중',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: book.isCompleted
                              ? AppTheme.successColor
                              : (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                // 완독 / 다시 읽기 전환 버튼 (높이 38dp로 뱃지와 완벽 정렬)
                SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(bookControllerProvider.notifier)
                          .toggleCompletion(book.id);
                    },
                    icon: Icon(
                      book.isCompleted
                          ? Icons.restart_alt_rounded
                          : Icons.task_alt_rounded,
                      size: 16,
                    ),
                    label: Text(
                      book.isCompleted ? '다시 읽기' : '완독으로 완료',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: book.isCompleted
                          ? (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0))
                          : AppTheme.successColor,
                      foregroundColor: book.isCompleted
                          ? (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary)
                          : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 한 줄 메모 서평
          if (book.memo.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F1626)
                    : const Color(0xFFF6F8FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFEDF0F5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.memo,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
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

  Widget _buildFallbackCover(Book book, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              book.isCompleted
                  ? Icons.auto_stories_rounded
                  : Icons.menu_book_rounded,
              color: primary.withValues(alpha: 0.8),
              size: 34,
            ),
            const SizedBox(height: 4),
            Text(
              book.isCompleted ? '완독' : '읽는 중',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: primary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotes(BuildContext context, Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.draw_outlined,
              size: 56,
              color: (isDark ? AppTheme.darkTextLight : AppTheme.textLight)
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              '아직 작성된 독서 기록이 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '책을 읽으며 기억하고 싶은 문장이나 생각을 기록해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => NoteFormDialog.show(context, book: book),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('첫 기록 작성하기'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                ),
                foregroundColor: isDark
                    ? AppTheme.primaryLight
                    : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final confirmed = await CustomConfirmDialog.show(
      context,
      title: '도서를 삭제하시겠습니까?',
      highlightedTarget: book.title,
      message: '이 책과 함께 작성된 모든 독서 기록(${book.readPages}p)이 영구히 삭제됩니다.',
      confirmText: '도서 삭제',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
      await ref.read(bookControllerProvider.notifier).deleteBook(book.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('도서가 삭제되었습니다.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
