import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

/// 프리미엄 완독 날짜 선택 커스텀 달력 팝업
class BookCompletedDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String title;
  final String confirmText;

  const BookCompletedDatePickerDialog({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.title = '완독 날짜 선택',
    this.confirmText = '완독일로 설정',
  });

  /// 다이얼로그 띄우기 헬퍼 메서드
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = '완독 날짜 선택',
    String confirmText = '완독일로 설정',
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => BookCompletedDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        title: title,
        confirmText: confirmText,
      ),
    );
  }

  @override
  State<BookCompletedDatePickerDialog> createState() =>
      _BookCompletedDatePickerDialogState();
}

class _BookCompletedDatePickerDialogState
    extends State<BookCompletedDatePickerDialog> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  late final DateTime _firstDate;
  late final DateTime _lastDate;

  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _firstDate = widget.firstDate ?? DateTime(2000, 1, 1);
    _lastDate = widget.lastDate ??
        DateTime.now().add(const Duration(days: 365));
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
        1,
      );
    });
  }

  void _selectToday() {
    HapticFeedback.selectionClick();
    final today = DateTime.now();
    final strippedToday = DateTime(today.year, today.month, today.day);
    setState(() {
      _selectedDate = strippedToday;
      _focusedMonth = DateTime(today.year, today.month, 1);
    });
  }

  void _onDaySelected(DateTime day) {
    if (day.isBefore(_firstDate) || day.isAfter(_lastDate)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = day;
      if (day.month != _focusedMonth.month || day.year != _focusedMonth.year) {
        _focusedMonth = DateTime(day.year, day.month, 1);
      }
    });
  }

  String _formatSelectedSubtitle() {
    final weekdayName = _weekdays[_selectedDate.weekday % 7];
    return '${DateFormat('yyyy년 M월 d일').format(_selectedDate)} ($weekdayName)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 날짜 그리드 계산
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    // 일요일(0) ~ 토요일(6)
    final leadingEmptyCount = firstWeekday % 7;
    final daysInPrevMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;

    final totalGridCells = leadingEmptyCount + daysInMonth;
    final trailingEmptyCount = (7 - (totalGridCells % 7)) % 7;
    final totalCells = totalGridCells + trailingEmptyCount;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark ? const Color(0xFF2B384D) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 프리미엄 상단 헤더 배너
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? AppTheme.headerGradientDark
                        : AppTheme.headerGradientLight,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF2E2749)
                          : const Color(0xFFDCD5F0),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // 아이콘 뱃지
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(
                              alpha: isDark ? 0.4 : 0.25,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 타이틀 & 선택된 날짜
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatSelectedSubtitle(),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 닫기 (X) 버튼
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 월간 네비게이션 바 (월 이동 & 오늘 점프 버튼)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 이전달 버튼
                    InkWell(
                      onTap: _previousMonth,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),

                    // 현재 월 표시
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('yyyy년 M월').format(_focusedMonth),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // 다음달 버튼 & 오늘 버튼
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 오늘 퀵 선택 칩 버튼
                        InkWell(
                          onTap: _selectToday,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '오늘',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _nextMonth,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. 요일 헤더 (일 ~ 토)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: List.generate(7, (index) {
                    final isSunday = index == 0;
                    final isSaturday = index == 6;
                    final Color color;
                    if (isSunday) {
                      color = const Color(0xFFEF4444);
                    } else if (isSaturday) {
                      color = const Color(0xFF3B82F6);
                    } else {
                      color = isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary;
                    }

                    return Expanded(
                      child: Center(
                        child: Text(
                          _weekdays[index],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 4. 날짜 그리드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    DateTime cellDate;
                    bool isCurrentMonth = true;

                    if (index < leadingEmptyCount) {
                      final prevDay = daysInPrevMonth -
                          (leadingEmptyCount - index - 1);
                      cellDate = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                        prevDay,
                      );
                      isCurrentMonth = false;
                    } else if (index < leadingEmptyCount + daysInMonth) {
                      final day = index - leadingEmptyCount + 1;
                      cellDate = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month,
                        day,
                      );
                    } else {
                      final nextDay =
                          index - (leadingEmptyCount + daysInMonth) + 1;
                      cellDate = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                        nextDay,
                      );
                      isCurrentMonth = false;
                    }

                    final isSelected = cellDate.year == _selectedDate.year &&
                        cellDate.month == _selectedDate.month &&
                        cellDate.day == _selectedDate.day;
                    final isToday = cellDate.year == today.year &&
                        cellDate.month == today.month &&
                        cellDate.day == today.day;
                    final isSunday = cellDate.weekday % 7 == 0;
                    final isSaturday = cellDate.weekday % 7 == 6;

                    Color textColor;
                    if (isSelected) {
                      textColor = Colors.white;
                    } else if (!isCurrentMonth) {
                      textColor = isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.22);
                    } else if (isSunday) {
                      textColor = const Color(0xFFEF4444);
                    } else if (isSaturday) {
                      textColor = const Color(0xFF3B82F6);
                    } else {
                      textColor = isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary;
                    }

                    return InkWell(
                      onTap: () => _onDaySelected(cellDate),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppTheme.successColor
                              : (isToday && !isSelected
                                  ? (isDark
                                      ? AppTheme.successColor.withValues(alpha: 0.15)
                                      : AppTheme.successColor.withValues(alpha: 0.1))
                                  : Colors.transparent),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: AppTheme.successColor,
                                  width: 1.4,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.successColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${cellDate.day}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              if (isToday && !isSelected)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.successColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // 5. 하단 액션 버튼 영역
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2634)
                      : const Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF263348)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          foregroundColor: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 설정 완료 버튼
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, _selectedDate),
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                        ),
                        label: Text(
                          widget.confirmText,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}
