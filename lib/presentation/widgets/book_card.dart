import "dart:io";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "../../core/theme/app_theme.dart";
import "../../data/models/book_model.dart";
import "../controllers/book_controller.dart";
import "../screens/book_detail_screen.dart";
import "action_bottom_sheet.dart";
import "book_form_dialog.dart";
import "custom_confirm_dialog.dart";

class BookCard extends ConsumerWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    final hasPages = book.totalPages > 0;
    final progressFraction = book.progress.clamp(0.0, 1.0);
    final progressPercent = (progressFraction * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A27) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF262B3E) : const Color(0xFFEDEEF5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 독립된 양장본 책 표지 (입체 그림자 & 실물 책 룩)
                _buildBookCover(context, isDark),

                const SizedBox(width: 14),

                // 2. 우측 도서 정보 & 프로그레스 & 푸터
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 & 더보기 메뉴
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary,
                                height: 1.25,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          _buildPopupMenu(context, ref, isDark),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // 저자 및 출판사
                      Text(
                        "${book.author}${book.publisher.isNotEmpty ? " · ${book.publisher}" : ""}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // 한 줄 메모(서평) 감성 인용구
                      if (book.memo.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF202538)
                                : const Color(0xFFF6F4FD),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF323A54)
                                  : const Color(0xFFEAE5F8),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            "“${book.memo.trim()}”",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // 3. 독서 진행률 미니 프로그레스 바 (p.120 / 300p · 40%)
                      if (hasPages) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "p.${book.readPages} / ${book.totalPages}p",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              "$progressPercent%",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: book.isCompleted
                                    ? const Color(0xFF10B981)
                                    : primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            minHeight: 4.5,
                            backgroundColor: isDark
                                ? const Color(0xFF262C40)
                                : const Color(0xFFF1EEF8),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              book.isCompleted
                                  ? const Color(0xFF10B981)
                                  : primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // 4. 카드 푸터 (별점/등록일 & 원터치 완독 토글 뱃지)
                      _buildCardFooter(context, ref, isDark, primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 독립된 실물 책 표지 ──
  Widget _buildBookCover(BuildContext context, bool isDark) {
    final cover = book.coverUrl;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    Widget imageContent;
    if (cover != null && cover.isNotEmpty) {
      if (cover.startsWith("http://") || cover.startsWith("https://")) {
        imageContent = Image.network(
          cover,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackCover(isDark, primary),
        );
      } else {
        imageContent = Image.file(
          File(cover),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackCover(isDark, primary),
        );
      }
    } else {
      imageContent = _buildFallbackCover(isDark, primary);
    }

    return Container(
      width: 68,
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageContent,
            // 양장본 책등(Spine) 느낌의 은은한 그라데이션
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 7,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // 완독 완료 시 표지 우측 상단 미니 체크 리본 뱃지
            if (book.isCompleted)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover(bool isDark, Color primary) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2248), const Color(0xFF1D1832)]
              : [const Color(0xFFEDE9FE), const Color(0xFFDDD6FE)],
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
              size: 24,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                book.title.isNotEmpty ? book.title.substring(0, 1) : "책",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 카드 하단 푸터 (별점/날짜 & 완독 토글 칩) ──
  Widget _buildCardFooter(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color primary,
  ) {
    final statusColor = book.isCompleted ? const Color(0xFF10B981) : primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 좌측: 별점 또는 등록일자
        if (book.rating > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 2.5),
                Text(
                  book.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            DateFormat("yyyy.MM.dd").format(book.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),

        // 우측: 원터치 인터랙티브 상태 전환 칩
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await ref
                  .read(bookControllerProvider.notifier)
                  .toggleCompletion(book.id);
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: statusColor.withValues(alpha: isDark ? 0.35 : 0.2),
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
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    book.isCompleted ? "완독 완료" : "읽는 중",
                    style: TextStyle(
                      fontSize: 11,
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

  Widget _buildPopupMenu(BuildContext context, WidgetRef ref, bool isDark) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
      ),
      tooltip: "더보기",
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
            _showDeleteConfirmDialog(context, ref);
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await CustomConfirmDialog.show(
      context,
      title: "도서를 삭제하시겠습니까?",
      highlightedTarget: book.title,
      message: "이 책과 함께 등록된 모든 독서 기록과 발췌문이 영구히 삭제됩니다.",
      confirmText: "도서 삭제",
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(bookControllerProvider.notifier).deleteBook(book.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("도서가 삭제되었습니다."),
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
