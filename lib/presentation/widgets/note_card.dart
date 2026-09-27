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

    // 독서 진척도 계산 (% 지점)
    final bool hasPage = note.pageNumber > 0;
    final bool hasTotalPages = book.totalPages > 0;
    final int? progressPercent = (hasPage && hasTotalPages)
        ? ((note.pageNumber / book.totalPages) * 100).clamp(1, 100).round()
        : null;

    final hasQuotation = note.quotation.trim().isNotEmpty;
    final hasContent = note.content.trim().isNotEmpty;
    final totalCharCount = (note.quotation.length + note.content.length);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? [
                const BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
        border: Border.all(
          color: isDark ? const Color(0xFF262D40) : const Color(0xFFE8EEF5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. 상단 메타 헤더 ──
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B28) : const Color(0xFFF8FAFD),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF262D40) : const Color(0xFFEDF2F7),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 페이지 배지 (인디고 칩)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: hasPage
                          ? (isDark
                              ? AppTheme.primaryLight.withValues(alpha: 0.2)
                              : AppTheme.primaryColor.withValues(alpha: 0.1))
                          : (isDark
                              ? const Color(0xFF2E3B52)
                              : const Color(0xFFEDF2F7)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasPage
                            ? (isDark
                                ? AppTheme.primaryLight.withValues(alpha: 0.35)
                                : AppTheme.primaryColor.withValues(alpha: 0.2))
                            : Colors.transparent,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasPage ? Icons.auto_stories_rounded : Icons.bookmark_border_rounded,
                          size: 13,
                          color: hasPage
                              ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasPage ? 'p. ${note.pageNumber}' : '전체 감상',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: hasPage
                                ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                                : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 독서 진척도 (% 지점)
                  if (progressPercent != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$progressPercent% 지점',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 8),

                  // 등록 일시
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formattedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 더보기 메뉴 버튼
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
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

            // ── 2. 미니 독서 진척도 바 (헤더 바로 아래) ──
            if (progressPercent != null)
              Container(
                height: 2.5,
                width: double.infinity,
                color: isDark ? const Color(0xFF1E2536) : const Color(0xFFEDF2F7),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (progressPercent / 100.0).clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppTheme.primaryLight, const Color(0xFF93C5FD)]
                            : [AppTheme.primaryColor, const Color(0xFF60A5FA)],
                      ),
                    ),
                  ),
                ),
              ),

            // ── 3. 카드 본문 콘텐츠 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [A] 인상 깊은 문장 (구절 박스 - 에디토리얼 발췌 스타일)
                  if (hasQuotation)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF192030)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF263047)
                              : const Color(0xFFE6EDF5),
                          width: 0.8,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 좌측 악센트 바
                              Container(
                                width: 4,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                              ),
                              // 텍스트 콘텐츠
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 14, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.format_quote_rounded,
                                            size: 15,
                                            color: isDark
                                                ? AppTheme.primaryLight
                                                : AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "인상 깊은 문장",
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.2,
                                              color: isDark
                                                  ? AppTheme.primaryLight
                                                  : AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        note.quotation,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          color: isDark
                                              ? AppTheme.darkTextPrimary
                                              : const Color(0xFF1E293B),
                                          height: 1.65,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // [B] 나의 생각 / 메모 (코멘터리 스타일)
                  if (hasContent) ...[
                    if (hasQuotation) const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: hasQuotation
                          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                          : const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: hasQuotation
                          ? null
                          : BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF192030)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF263047)
                                    : const Color(0xFFE6EDF5),
                                width: 0.8,
                              ),
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 16,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "나의 생각",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : const Color(0xFF334155),
                              height: 1.65,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── 4. 하단 액션 & 부가 정보 바 ──
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좌측: 글자 수 정보
                  Row(
                    children: [
                      Icon(
                        Icons.text_snippet_outlined,
                        size: 13,
                        color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalCharCount자',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                        ),
                      ),
                      if (note.updatedAt != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· 수정됨',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 우측: 소프트 블루 [카드 공유] 버튼
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ShareableQuoteCardDialog.show(
                        context,
                        book: book,
                        note: note,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: isDark ? 0.18 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor)
                                .withValues(alpha: isDark ? 0.35 : 0.22),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.ios_share_rounded,
                              size: 13,
                              color: isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '카드 공유',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
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
