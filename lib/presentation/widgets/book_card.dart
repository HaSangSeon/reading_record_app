import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../controllers/book_controller.dart';
import '../screens/book_detail_screen.dart';
import 'book_form_dialog.dart';
import 'reading_progress_dialog.dart';

class BookCard extends ConsumerWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailScreen(bookId: book.id),
                ),
              );
            },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 책 표지 이미지 또는 감성적인 대체 커버
              _buildCoverImage(context),
              const SizedBox(width: 14),
              // 도서 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        // 퀵 메뉴 버튼
                        _buildPopupMenu(context, ref),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.author}${book.publisher.isNotEmpty ? ' · ${book.publisher}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 별점 표시 (등록되어 있는 경우)
                    if (book.rating > 0) ...[
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppTheme.accentColor),
                          const SizedBox(width: 2),
                          Text(
                            book.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    // 독서 진행률 바 및 수치
                    _buildProgressBar(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 72,
      height: 104,
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
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
              errorBuilder: (_, _, _) => _buildFallbackCover(context),
            )
          : _buildFallbackCover(context),
    );
  }

  Widget _buildFallbackCover(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            book.isCompleted
                ? Icons.auto_stories_rounded
                : Icons.menu_book_rounded,
            color: primary.withValues(alpha: 0.7),
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            book.isCompleted ? '완독' : '읽는 중',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: primary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 상태 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: book.isCompleted
                    ? AppTheme.successColor.withValues(alpha: 0.15)
                    : (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                book.isCompleted ? '🎉 완독 완료' : '📖 ${book.progressPercentage}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: book.isCompleted
                      ? AppTheme.successColor
                      : (isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor),
                ),
              ),
            ),
            // 페이지 수 표시
            Text(
              book.totalPages > 0
                  ? '${book.readPages} / ${book.totalPages} p'
                  : '${book.readPages} p',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: book.progress,
            minHeight: 6,
            backgroundColor:
                isDark ? AppTheme.darkBorder : AppTheme.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              book.isCompleted
                  ? AppTheme.successColor
                  : (isDark ? AppTheme.primaryLight : AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        switch (value) {
          case 'progress':
            ReadingProgressDialog.show(context, book);
            break;
          case 'toggle_complete':
            await ref
                .read(bookControllerProvider.notifier)
                .toggleCompletion(book.id);
            break;
          case 'edit':
            BookFormDialog.show(context, book: book);
            break;
          case 'delete':
            _showDeleteConfirmDialog(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'progress',
          child: Row(
            children: [
              Icon(
                Icons.bookmark_add_outlined,
                size: 18,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              const Text('진행 페이지 기록', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_complete',
          child: Row(
            children: [
              Icon(
                book.isCompleted
                    ? Icons.remove_circle_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 10),
              Text(book.isCompleted ? '읽는 중으로 변경' : '완독으로 표시',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              const Text('도서 정보 수정', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('도서 삭제',
                  style: TextStyle(fontSize: 14, color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('도서 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
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
              await ref
                  .read(bookControllerProvider.notifier)
                  .deleteBook(book.id);
              if (context.mounted) {
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
