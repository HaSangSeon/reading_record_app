import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import 'calendar/calendar_widgets.dart';

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

  void _onSelectDay(DateTime dayDate) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDay = dayDate);
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
          CalendarMonthNavigator(
            focusedMonth: _focusedMonth,
            completedCount: completedCount,
            notesCount: notesCount,
            isDark: isDark,
            onPreviousMonth: _previousMonth,
            onNextMonth: _nextMonth,
            onJumpToToday: _jumpToToday,
          ),

          const SizedBox(height: 14),

          // 캘린더 그리드 카드
          CalendarGridCard(
            focusedMonth: _focusedMonth,
            selectedDay: _selectedDay,
            completedBooksByDay: completedBooksByDay,
            notesByDay: notesByDay,
            completedCount: completedCount,
            notesCount: notesCount,
            isDark: isDark,
            onSelectDay: _onSelectDay,
          ),

          const SizedBox(height: 18),

          // 선택된 일자의 상세 독서 기록 섹션
          CalendarDayDetail(
            selectedDay: _selectedDay,
            completedBooks: selectedDayCompletedBooks,
            notes: selectedDayNotes,
            allBooks: widget.books,
            isDark: isDark,
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
}
