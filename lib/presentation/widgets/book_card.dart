import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../controllers/book_controller.dart';
import '../screens/book_detail_screen.dart';
import 'book_form_dialog.dart';

class BookCard extends ConsumerWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF162032), const Color(0xFF101726)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF223048) : const Color(0xFFE8EDF5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF1E293B).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 좌측 풀-하이트 책 표지 (매거진 스타일 양장본 룩)
                _buildCoverImage(context),
                // 우측 도서 상세 정보
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
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
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.textPrimary,
                                      height: 1.25,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                // 퀵 메뉴 버튼
                                _buildPopupMenu(context, ref),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${book.author}${book.publisher.isNotEmpty ? ' · ${book.publisher}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // 한 줄 메모(서평)가 있는 경우 감성 인용구 표시
                            if (book.memo.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '“${book.memo.trim()}”',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 좌측 별점 & 우측 일체형 인터랙티브 상태 뱃지 푸터
                        _buildCardFooter(context, ref, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cover = book.coverUrl;

    Widget imageWidget;
    if (cover != null && cover.isNotEmpty) {
      if (cover.startsWith('http://') || cover.startsWith('https://')) {
        imageWidget = Image.network(
          cover,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackCover(context),
        );
      } else {
        imageWidget = Image.file(
          File(cover),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackCover(context),
        );
      }
    } else {
      imageWidget = _buildFallbackCover(context);
    }

    return SizedBox(
      width: 82,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(19)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            // 양장본 책등(Spine) 느낌의 섬세한 그라데이션 오버레이
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 8,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // 우측 카드 경계선
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 0.8,
              child: Container(
                color: isDark ? const Color(0xFF223048) : const Color(0xFFE8EDF5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover(BuildContext context) {
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
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              book.isCompleted ? '완독' : '읽는 중',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: primary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFooter(BuildContext context, WidgetRef ref, bool isDark) {
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    final statusColor = book.isCompleted ? AppTheme.successColor : primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 좌측: 별점 (있는 경우) 또는 등록일 표시
        if (book.rating > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 3),
                Text(
                  book.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            DateFormat('yyyy.MM.dd').format(book.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),

        // 우측: 원터치 인터랙티브 상태 알약 (단일 뱃지 & 탭하여 상태 전환)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await ref
                  .read(bookControllerProvider.notifier)
                  .toggleCompletion(book.id);
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.22 : 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withValues(alpha: isDark ? 0.35 : 0.22),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    book.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.auto_stories_rounded,
                    size: 13,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4.5),
                  Text(
                    book.isCompleted ? '완독 완료' : '읽는 중',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
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
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              const Text('도서 정보 수정', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                '도서 삭제',
                style: TextStyle(fontSize: 14, color: Colors.redAccent),
              ),
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
