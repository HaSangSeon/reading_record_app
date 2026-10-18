import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/note_model.dart';
import 'calendar_day_cell.dart';

class CalendarGridCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Map<int, List<Book>> completedBooksByDay;
  final Map<int, List<Note>> notesByDay;
  final int completedCount;
  final int notesCount;
  final bool isDark;
  final ValueChanged<DateTime> onSelectDay;

  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  const CalendarGridCard({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.completedBooksByDay,
    required this.notesByDay,
    required this.completedCount,
    required this.notesCount,
    required this.isDark,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday;
    // 일요일=0, 월요일=1 ... 토요일=6
    final leadingEmptyDays = firstWeekday % 7;
    final totalGridCells = leadingEmptyDays + daysInMonth;
    final trailingEmptyDays = (7 - (totalGridCells % 7)) % 7;
    final totalCells = totalGridCells + trailingEmptyDays;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2749) : const Color(0xFFE2DDF0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF5E46B8).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 타이틀 바 (상단)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('yyyy년 M월').format(focusedMonth)} 독서 캘린더',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '완독 $completedCount권 · 문장 $notesCount개',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // 요일 헤더 (일 ~ 토)
          Row(
            children: List.generate(7, (index) {
              final isSunday = index == 0;
              final isSaturday = index == 6;
              final textColor = isSunday
                  ? const Color(0xFFEF4444)
                  : (isSaturday
                      ? const Color(0xFF3B82F6)
                      : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary));

              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _weekdays[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 6),

          // 날짜 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.63, // 책 표지가 들어갈 수 있는 비율
              crossAxisSpacing: 3,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays ||
                  index >= leadingEmptyDays + daysInMonth) {
                return const SizedBox.shrink();
              }

              final day = index - leadingEmptyDays + 1;
              final dayDate = DateTime(focusedMonth.year, focusedMonth.month, day);
              final now = DateTime.now();
              final isToday = now.year == dayDate.year &&
                  now.month == dayDate.month &&
                  now.day == dayDate.day;
              final isSelected = selectedDay.year == dayDate.year &&
                  selectedDay.month == dayDate.month &&
                  selectedDay.day == dayDate.day;

              final weekdayIndex = index % 7;
              final isSunday = weekdayIndex == 0;
              final isSaturday = weekdayIndex == 6;

              final completedBooks = completedBooksByDay[day] ?? [];
              final notes = notesByDay[day] ?? [];

              return CalendarDayCell(
                day: day,
                dayDate: dayDate,
                isToday: isToday,
                isSelected: isSelected,
                isSunday: isSunday,
                isSaturday: isSaturday,
                isDark: isDark,
                completedBooks: completedBooks,
                notes: notes,
                onTap: () => onSelectDay(dayDate),
              );
            },
          ),

          const SizedBox(height: 10),

          // 워터마크 안내
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 11,
                  color: (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '나만의 독서기록장 · Book Log',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)
                        .withValues(alpha: 0.6),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
