import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../screens/book_detail_screen.dart';
import 'shareable_quote_card_dialog.dart';

/// 독서 캘린더 위젯: 날짜별 완독 도서 표지 썸네일 노출, 독서 기록 조회, 월간 결산 이미지 공유 지원
class ReadingCalendarView extends StatefulWidget {
  final List<Book> books;
  final List<Note> notes;
  final Future<void> Function()? onRefresh;

  const ReadingCalendarView({
    super.key,
    required this.books,
    required this.notes,
    this.onRefresh,
  });

  @override
  State<ReadingCalendarView> createState() => _ReadingCalendarViewState();
}

class _ReadingCalendarViewState extends State<ReadingCalendarView> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. 해당 월에 완독된 책 매핑 (day -> List<Book>)
    final Map<int, List<Book>> completedBooksByDay = {};
    for (final book in widget.books) {
      if (book.isCompleted && book.completedAt != null) {
        final d = book.completedAt!;
        if (d.year == _focusedMonth.year && d.month == _focusedMonth.month) {
          completedBooksByDay.putIfAbsent(d.day, () => []).add(book);
        }
      }
    }

    // 2. 해당 월에 작성된 독서노트 매핑 (day -> List<Note>)
    final Map<int, List<Note>> notesByDay = {};
    for (final note in widget.notes) {
      final d = note.createdAt;
      if (d.year == _focusedMonth.year && d.month == _focusedMonth.month) {
        notesByDay.putIfAbsent(d.day, () => []).add(note);
      }
    }

    // 이번 달 통계 요약
    final completedCount = completedBooksByDay.values.fold<int>(0, (sum, list) => sum + list.length);
    final notesCount = notesByDay.values.fold<int>(0, (sum, list) => sum + list.length);

    // 선택된 날짜의 데이터
    final isSelectedMonth = _selectedDay.year == _focusedMonth.year &&
        _selectedDay.month == _focusedMonth.month;
    final selectedDayCompletedBooks = isSelectedMonth
        ? (completedBooksByDay[_selectedDay.day] ?? [])
        : <Book>[];
    final selectedDayNotes = isSelectedMonth
        ? (notesByDay[_selectedDay.day] ?? [])
        : <Note>[];

    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 월간 네비게이션 & 통계 요약 바
          _buildMonthNavigator(context, isDark, completedCount, notesCount),

          const SizedBox(height: 14),

          // 캘린더 카드
          _buildCalendarCard(
            context: context,
            isDark: isDark,
            completedBooksByDay: completedBooksByDay,
            notesByDay: notesByDay,
            completedCount: completedCount,
            notesCount: notesCount,
          ),

          const SizedBox(height: 18),

          // 선택된 일자의 상세 독서 기록 섹션
          _buildSelectedDayDetail(
            context: context,
            isDark: isDark,
            completedBooks: selectedDayCompletedBooks,
            notes: selectedDayNotes,
          ),
        ],
      ),
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        color: AppTheme.primaryColor,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        onRefresh: widget.onRefresh!,
        child: content,
      );
    }
    return content;
  }

  // ── 월간 상단 네비게이터 ──
  Widget _buildMonthNavigator(
    BuildContext context,
    bool isDark,
    int completedCount,
    int notesCount,
  ) {
    final monthTitle = DateFormat('yyyy년 M월').format(_focusedMonth);
    final isCurrentMonth = _focusedMonth.year == DateTime.now().year &&
        _focusedMonth.month == DateTime.now().month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2749) : const Color(0xFFE2DDF0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF5E46B8).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 24),
                tooltip: '이전 달',
                onPressed: _previousMonth,
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor:
                      isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      monthTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (!isCurrentMonth) ...[
                      const SizedBox(width: 8),
                      Transform.translate(
                        offset: const Offset(0, 1.5),
                        child: InkWell(
                          onTap: _jumpToToday,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '오늘',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 24),
                tooltip: '다음 달',
                onPressed: _nextMonth,
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor:
                      isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2E2749) : const Color(0xFFEDE8F5),
          ),
          const SizedBox(height: 10),

          // 이번 달 요약 리본
          Row(
            children: [
              _buildMiniMetric(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: '완독 도서',
                value: '$completedCount권',
                isDark: isDark,
              ),
              _buildMetricDivider(isDark),
              _buildMiniMetric(
                icon: Icons.format_quote_rounded,
                iconColor: const Color(0xFF8B5CF6),
                label: '문장 수집',
                value: '$notesCount개',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? const Color(0xFF2E2749) : const Color(0xFFEDE8F5),
    );
  }

  // ── 캘린더 본체 카드 (캡처 영역) ──
  Widget _buildCalendarCard({
    required BuildContext context,
    required bool isDark,
    required Map<int, List<Book>> completedBooksByDay,
    required Map<int, List<Note>> notesByDay,
    required int completedCount,
    required int notesCount,
  }) {
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
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
          // 공유 시 노출되는 감성 타이틀 바 (상단)
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
                  '${DateFormat('yyyy년 M월').format(_focusedMonth)} 독서 캘린더',
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
              final dayDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final now = DateTime.now();
              final isToday = now.year == dayDate.year &&
                  now.month == dayDate.month &&
                  now.day == dayDate.day;
              final isSelected = _selectedDay.year == dayDate.year &&
                  _selectedDay.month == dayDate.month &&
                  _selectedDay.day == dayDate.day;

              final weekdayIndex = index % 7;
              final isSunday = weekdayIndex == 0;
              final isSaturday = weekdayIndex == 6;

              final completedBooks = completedBooksByDay[day] ?? [];
              final notes = notesByDay[day] ?? [];

              return _buildCalendarDayCell(
                context: context,
                day: day,
                dayDate: dayDate,
                isToday: isToday,
                isSelected: isSelected,
                isSunday: isSunday,
                isSaturday: isSaturday,
                isDark: isDark,
                completedBooks: completedBooks,
                notes: notes,
              );
            },
          ),

          const SizedBox(height: 10),

          // 캡처 워터마크 안내 (소셜 공유 시 자연스러운 앱 홍보)
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

  // ── 개별 날짜 셀 ──
  Widget _buildCalendarDayCell({
    required BuildContext context,
    required int day,
    required DateTime dayDate,
    required bool isToday,
    required bool isSelected,
    required bool isSunday,
    required bool isSaturday,
    required bool isDark,
    required List<Book> completedBooks,
    required List<Note> notes,
  }) {
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDay = dayDate);
      },
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

            const SizedBox(height: 2),

            // 중앙/하단: 완독 도서 표지 또는 독서노트 배지
            Expanded(
              child: hasCompleted
                  ? _buildBookCoverThumbnail(completedBooks.first, completedBooks.length, isDark)
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
  Widget _buildBookCoverThumbnail(Book book, int count, bool isDark) {
    final hasValidCover = book.coverUrl != null && book.coverUrl!.trim().isNotEmpty;

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
                ? Image.network(
                    book.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildCoverFallback(book, isDark),
                  )
                : _buildCoverFallback(book, isDark),
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

  // ── 선택된 일자의 상세 기록 섹션 ──
  Widget _buildSelectedDayDetail({
    required BuildContext context,
    required bool isDark,
    required List<Book> completedBooks,
    required List<Note> notes,
  }) {
    final weekdayName = _weekdays[_selectedDay.weekday % 7];
    final dateFormatted =
        '${_selectedDay.month}월 ${_selectedDay.day}일 ($weekdayName)';
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
                (book) => _buildCompletedBookTile(context, book, isDark),
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
                (note) => _buildNoteTile(context, note, isDark),
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

  /// 완독 도서 아이템 타일
  Widget _buildCompletedBookTile(BuildContext context, Book book, bool isDark) {
    final hasCover = book.coverUrl != null && book.coverUrl!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B172C) : const Color(0xFFF9F7FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2448) : const Color(0xFFEBE6F5),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(bookId: book.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // 표지
              Container(
                width: 40,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: hasCover
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildCoverFallback(book, isDark),
                        )
                      : _buildCoverFallback(book, isDark),
                ),
              ),
              const SizedBox(width: 12),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    if (book.rating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 3),
                          Text(
                            book.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 완독 배지 + 화살표
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      '완독',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 독서노트/문장 아이템 타일 (서재의 프리미엄 NoteCard 디자인 시스템 완벽 반영)
  Widget _buildNoteTile(BuildContext context, Note note, bool isDark) {
    // 연결된 도서 검색
    final relatedBook = widget.books.firstWhere(
      (b) => b.id == note.bookId,
      orElse: () => Book(
        id: note.bookId,
        title: '도서 정보 없음',
        author: '',
        createdAt: note.createdAt,
      ),
    );

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
