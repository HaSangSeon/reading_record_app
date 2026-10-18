import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';

/// 4. 최근 6개월 완독 추이 바 차트 카드
class StatsMonthlyChartCard extends StatelessWidget {
  final List<Book> books;
  final Animation<double> barAnim;

  const StatsMonthlyChartCard({
    super.key,
    required this.books,
    required this.barAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    final counts = months.map((month) {
      return books.where((b) {
        if (!b.isCompleted) return false;
        final targetDate = b.completedAt ?? b.createdAt;
        return targetDate.year == month.year &&
            targetDate.month == month.month;
      }).length;
    }).toList();

    final totalCount = counts.fold<int>(0, (a, b) => a + b);
    final maxCount =
        counts.fold<int>(1, (max, c) => c > max ? c : max).clamp(1, 999);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B28) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF3B82F6),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "최근 6개월 완독 추이",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF24293E)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "총 $totalCount권",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 차트 바 영역 (오버플로우 방지 및 여유로운 패딩)
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) {
                  final month = months[index];
                  final count = counts[index];
                  final monthLabel = DateFormat("M월").format(month);
                  final isCurrentMonth = index == 5;
                  final ratio = count / maxCount;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 권수 레이블
                          SizedBox(
                            height: 16,
                            child: count > 0
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "$count",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isCurrentMonth
                                            ? (isDark
                                                ? const Color(0xFF93C5FD)
                                                : const Color(0xFF2563EB))
                                            : (isDark
                                                ? AppTheme.darkTextSecondary
                                                : AppTheme.textSecondary),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 4),

                          // 바 그래프 본체 (최대 높이 80px)
                          AnimatedBuilder(
                            animation: barAnim,
                            builder: (context, _) {
                              final barHeight = count > 0
                                  ? (80 * ratio * barAnim.value)
                                      .clamp(8.0, 80.0)
                                  : 4.0;

                              return Container(
                                width: double.infinity,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  gradient: count > 0
                                      ? LinearGradient(
                                          colors: isCurrentMonth
                                              ? [
                                                  const Color(0xFF60A5FA),
                                                  const Color(0xFF2563EB),
                                                ]
                                              : [
                                                  isDark
                                                      ? const Color(0xFF818CF8)
                                                      : const Color(0xFF6366F1),
                                                  isDark
                                                      ? const Color(0xFF4F46E5)
                                                      : const Color(0xFF4338CA),
                                                ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: count == 0
                                      ? (isDark
                                          ? const Color(0xFF24293E)
                                          : const Color(0xFFE2E8F0))
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: count > 0 && isCurrentMonth
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          // 월 텍스트 레이블
                          Text(
                            monthLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrentMonth
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isCurrentMonth
                                  ? (isDark
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFF2563EB))
                                  : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
