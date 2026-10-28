import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/note_model.dart';
import '../book_cover_image.dart';

class CalendarDayCell extends StatelessWidget {
  final int day;
  final DateTime dayDate;
  final bool isToday;
  final bool isSelected;
  final bool isSunday;
  final bool isSaturday;
  final bool isDark;
  final List<Book> completedBooks;
  final List<Note> notes;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.dayDate,
    required this.isToday,
    required this.isSelected,
    required this.isSunday,
    required this.isSaturday,
    required this.isDark,
    required this.completedBooks,
    required this.notes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    Color numberColor = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.textPrimary;
    if (isSunday) {
      numberColor = const Color(0xFFEF4444);
    } else if (isSaturday) {
      numberColor = const Color(0xFF3B82F6);
    }

    final hasCompleted = completedBooks.isNotEmpty;
    final hasNotes = notes.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isToday
                  ? (isDark
                      ? const Color(0xFF261F3D)
                      : const Color(0xFFF5F0FF))
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primary
                : (isToday
                    ? primary.withValues(alpha: 0.5)
                    : (isDark
                        ? const Color(0xFF25203A)
                        : const Color(0xFFF0EBF7))),
            width: isSelected ? 1.8 : (isToday ? 1.0 : 0.6),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Column(
          children: [
            // 상단: 날짜 번호 + 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isToday ? primary : numberColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasNotes && hasCompleted)
                      Container(
                        margin: const EdgeInsets.only(right: 2),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(right: 2),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else if (hasNotes && !hasCompleted)
                      Container(
                        margin: const EdgeInsets.only(right: 2),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 2),

            // 중앙/하단: 완독 도서 표지 또는 독서노트 배지
            Expanded(
              child: hasCompleted
                  ? _buildBookCoverThumbnail(
                      completedBooks.first,
                      completedBooks.length,
                      notes.length,
                      isDark,
                    )
                  : (hasNotes
                      ? _buildNoteIndicator(notes.length, isDark)
                      : const SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }

  /// 완독 도서 표지 미니 썸네일
  Widget _buildBookCoverThumbnail(
    Book book,
    int count,
    int noteCount,
    bool isDark,
  ) {
    final hasValidCover =
        book.coverUrl != null && book.coverUrl!.trim().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(1, 0, 1, 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: hasValidCover
                ? _buildImage(book.coverUrl!, book, isDark)
                : _buildCoverFallback(book, isDark),
          ),
        ),

        // 독서 노트도 작성한 날이면 좌측 하단에 미니 따옴표 배지 표시
        if (noteCount > 0)
          Positioned(
            left: 1,
            bottom: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    size: 7,
                    color: Colors.white,
                  ),
                  if (noteCount > 1) ...[
                    const SizedBox(width: 1),
                    Text(
                      '$noteCount',
                      style: const TextStyle(
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // 2권 이상 완독 시 +N 배지 표시
        if (count > 1)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '+${count - 1}',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 웹 이미지 및 초경량 Base64, 로컬 기기 파일 이미지 안전 렌더링
  Widget _buildImage(String url, Book book, bool isDark) {
    return BookCoverImage(
      coverUrl: url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildCoverFallback(book, isDark),
    );
  }

  /// 도서 표지 로드 실패 시 나타나는 세련된 미니 양장본 책 표지
  Widget _buildCoverFallback(Book book, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A3894), Color(0xFF2E2468)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_rounded,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(height: 1),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 6.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 완독 책은 없지만 문장/메모 기록이 있는 날 표시
  Widget _buildNoteIndicator(int count, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.format_quote_rounded,
              size: 10,
              color: Color(0xFF8B5CF6),
            ),
            const SizedBox(width: 2),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
