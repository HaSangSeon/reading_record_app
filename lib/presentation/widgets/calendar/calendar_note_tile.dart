import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/note_model.dart';
import '../../screens/book_detail_screen.dart';
import '../shareable_quote_card_dialog.dart';

class CalendarNoteTile extends StatelessWidget {
  final Note note;
  final Book relatedBook;
  final bool isDark;

  const CalendarNoteTile({
    super.key,
    required this.note,
    required this.relatedBook,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPage = note.pageNumber > 0;
    final bool hasQuotation = note.quotation.trim().isNotEmpty;
    final bool hasContent = note.content.trim().isNotEmpty;
    final totalCharCount = note.quotation.length + note.content.length;
    final timeStr = DateFormat('HH:mm').format(note.createdAt);
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B28) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262D40) : const Color(0xFFE2E8F0),
          width: 0.9,
        ),
        boxShadow: isDark
            ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. 상단 메타 헤더 (도서 제목 칩 + 페이지 배지 + 작성 시간) ──
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2536) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF262D40) : const Color(0xFFEDF2F7),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 도서 제목 뱃지 (클릭 시 해당 도서 상세 페이지로 이동)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(bookId: relatedBook.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: primary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                relatedBook.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: primary.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 페이지 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasPage
                          ? primary.withValues(alpha: isDark ? 0.2 : 0.1)
                          : (isDark ? const Color(0xFF2E3B52) : const Color(0xFFEDF2F7)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hasPage
                            ? primary.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      hasPage ? 'p.${note.pageNumber}' : '전체 감상',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: hasPage
                            ? primary
                            : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 작성 시간
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. 본문 영역 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [A] 인상 깊은 문장 (에디토리얼 발췌 구절 박스)
                  if (hasQuotation)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF28354F) : const Color(0xFFE6EDF5),
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
                                color: primary,
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
                                            size: 14,
                                            color: primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "인상 깊은 문장",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: primary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        note.quotation,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? AppTheme.darkTextPrimary
                                              : const Color(0xFF1E293B),
                                          height: 1.6,
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
                    if (hasQuotation) const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: hasQuotation
                          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                          : const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: hasQuotation
                          ? null
                          : BoxDecoration(
                              color: isDark ? const Color(0xFF1A2234) : const Color(0xFFF8FAFD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF28354F) : const Color(0xFFE6EDF5),
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
                                size: 15,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "나의 생각",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            note.content,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : const Color(0xFF334155),
                              height: 1.55,
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

            // ── 3. 하단 액션 & 부가 정보 바 ──
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
                    ],
                  ),

                  // 우측: 세련된 [카드 공유] 칩 버튼
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ShareableQuoteCardDialog.show(
                          context,
                          book: relatedBook,
                          note: note,
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primary.withValues(alpha: isDark ? 0.35 : 0.22),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.ios_share_rounded,
                              size: 13,
                              color: primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '카드 공유',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: primary,
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
}
