import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../controllers/note_controller.dart';
import 'action_bottom_sheet.dart';
import 'custom_confirm_dialog.dart';
import 'note_form_dialog.dart';
import 'shareable_quote_card_dialog.dart';

class NoteCard extends ConsumerWidget {
  final Book book;
  final Note note;

  const NoteCard({super.key, required this.book, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final formattedDate = dateFormat.format(note.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 영역
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B28) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2E3B52)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_rounded,
                              size: 14,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note.pageNumber > 0
                                  ? 'p. ${note.pageNumber}'
                                  : '전체 기록',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                    ),
                    tooltip: '더보기',
                    onPressed: () {
                      ActionBottomSheet.showNoteActions(
                        context,
                        book: book,
                        note: note,
                        onShare: () {
                          ShareableQuoteCardDialog.show(
                            context,
                            book: book,
                            note: note,
                          );
                        },
                        onEdit: () {
                          NoteFormDialog.show(context, book: book, note: note);
                        },
                        onDelete: () {
                          _showDeleteConfirm(context, ref);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // 인상 깊은 구절 영역 (큰 따옴표 디자인 적용)
            if (note.quotation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 16, top: 6, bottom: 4),
                child: Stack(
                  children: [
                    Positioned(
                      top: -10,
                      left: -2,
                      child: Icon(
                        Icons.format_quote_rounded,
                        size: 56,
                        color: isDark
                            ? AppTheme.primaryLight.withValues(alpha: 0.1)
                            : AppTheme.primaryColor.withValues(alpha: 0.04),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18, top: 10, bottom: 4),
                      child: Text(
                        note.quotation,
                        style: TextStyle(
                          fontSize: 15.5,
                          color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B),
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 사용자의 생각/메모 영역
            if (note.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 8),
                child: Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569),
                    height: 1.65,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

            // 하단 액션(공유) 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => ShareableQuoteCardDialog.show(
                      context,
                      book: book,
                      note: note,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ios_share_rounded,
                            size: 14,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '카드 공유',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirm(BuildContext context, WidgetRef ref) async {
    final displayText = note.quotation.isNotEmpty
        ? note.quotation
        : (note.content.isNotEmpty ? note.content : '독서 기록');

    final confirmed = await CustomConfirmDialog.show(
      context,
      title: '독서 기록을 삭제하시겠습니까?',
      highlightedTarget: displayText,
      message: '《${book.title}》에 남긴 이 독서 기록이 영구히 삭제됩니다.',
      confirmText: '기록 삭제',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(noteControllerProvider.notifier).deleteNote(note.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('독서 기록이 삭제되었습니다.'),
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
