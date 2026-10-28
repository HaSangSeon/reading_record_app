import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/note_model.dart';
import 'calendar_completed_book_tile.dart';
import 'calendar_note_tile.dart';

class CalendarDayDetail extends StatelessWidget {
  final DateTime selectedDay;
  final List<Book> completedBooks;
  final List<Note> notes;
  final List<Book> allBooks;
  final bool isDark;

  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  const CalendarDayDetail({
    super.key,
    required this.selectedDay,
    required this.completedBooks,
    required this.notes,
    required this.allBooks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final weekdayName = _weekdays[selectedDay.weekday % 7];
    final dateFormatted =
        '${selectedDay.month}월 ${selectedDay.day}일 ($weekdayName)';
    final bookMap = {for (final b in allBooks) b.id: b};
    final hasData = completedBooks.isNotEmpty || notes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2749) : const Color(0xFFE2DDF0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF5E46B8).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  size: 17,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$dateFormatted 독서 기록',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '완독 ${completedBooks.length} · 기록 ${notes.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          if (!hasData)
            _buildEmptyDayState(isDark)
          else ...[
            // 1. 완독 도서 섹션
            if (completedBooks.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 15,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '이 날 완독한 책 (${completedBooks.length}권)',
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
              const SizedBox(height: 8),
              ...completedBooks.map(
                (book) => CalendarCompletedBookTile(book: book, isDark: isDark),
              ),
              const SizedBox(height: 12),
            ],

            // 2. 작성한 독서노트/문장 섹션
            if (notes.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    size: 15,
                    color: Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '이 날 수집한 문장 및 메모 (${notes.length}개)',
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
              const SizedBox(height: 8),
              ...notes.map(
                (note) {
                  final relatedBook = bookMap[note.bookId] ??
                      Book(
                        id: note.bookId,
                        title: '삭제되었거나 알 수 없는 도서',
                        author: '',
                        createdAt: note.createdAt,
                      );
                  return CalendarNoteTile(
                    note: note,
                    relatedBook: relatedBook,
                    isDark: isDark,
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// 빈 날짜 상태 안내
  Widget _buildEmptyDayState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 36,
              color: (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary)
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Text(
              '이 날은 아직 등록된 독서 활동이 없습니다.',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '인상 깊었던 책의 한 줄을 기록해보세요.',
              style: TextStyle(
                fontSize: 12,
                color: (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary)
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
