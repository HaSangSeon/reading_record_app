import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class CalendarMonthNavigator extends StatelessWidget {
  final DateTime focusedMonth;
  final int completedCount;
  final int notesCount;
  final bool isDark;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onJumpToToday;

  const CalendarMonthNavigator({
    super.key,
    required this.focusedMonth,
    required this.completedCount,
    required this.notesCount,
    required this.isDark,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onJumpToToday,
  });

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat('yyyy년 M월').format(focusedMonth);
    final now = DateTime.now();
    final isCurrentMonth = focusedMonth.year == now.year && focusedMonth.month == now.month;

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
                onPressed: onPreviousMonth,
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
                          onTap: onJumpToToday,
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
                onPressed: onNextMonth,
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
}
