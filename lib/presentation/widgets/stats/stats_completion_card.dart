import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 3. 완독 진행 상태 카드 (도넛 차트 & 완독/읽는 중 진행 바)
class StatsCompletionStatusCard extends StatelessWidget {
  final int totalBooks;
  final int completedBooks;
  final int readingBooks;
  final int completionRate;
  final Animation<double> barAnim;

  const StatsCompletionStatusCard({
    super.key,
    required this.totalBooks,
    required this.completedBooks,
    required this.readingBooks,
    required this.completionRate,
    required this.barAnim,
  });

  Widget _buildStatusRow({
    required Color color,
    required String label,
    required int count,
    required int total,
    required bool isDark,
  }) {
    final pct = total > 0 ? ((count / total) * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              "$count권 ($pct%)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        AnimatedBuilder(
          animation: barAnim,
          builder: (context, _) {
            final barVal = total > 0 ? (count / total) * barAnim.value : 0.0;
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barVal,
                minHeight: 5,
                backgroundColor: isDark
                    ? const Color(0xFF24293E)
                    : const Color(0xFFF1EEF8),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeText = completionRate >= 80
        ? "🔥 훌륭해요!"
        : completionRate >= 50
            ? "👍 순조로워요"
            : "📖 힘내볼까요?";

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
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.donut_large_rounded,
                    color:
                        isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "완독 진행 현황",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 도넛 차트 및 범례
            Row(
              children: [
                // 도넛 차트
                SizedBox(
                  width: 96,
                  height: 96,
                  child: AnimatedBuilder(
                    animation: barAnim,
                    builder: (context, _) {
                      final fraction = totalBooks > 0
                          ? (completedBooks / totalBooks) * barAnim.value
                          : 0.0;
                      return CustomPaint(
                        painter: DonutChartPainter(
                          completedFraction: fraction,
                          completedColor: const Color(0xFF10B981),
                          readingColor: isDark
                              ? const Color(0xFF818CF8)
                              : AppTheme.primaryColor,
                          bgColor: isDark
                              ? const Color(0xFF24293E)
                              : const Color(0xFFF1EEF8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$completionRate%",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "완독률",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 18),

                // 완독 / 읽는 중 범례
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusRow(
                        color: const Color(0xFF10B981),
                        label: "완독한 도서",
                        count: completedBooks,
                        total: totalBooks,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildStatusRow(
                        color: isDark
                            ? const Color(0xFF818CF8)
                            : AppTheme.primaryColor,
                        label: "읽고 있는 도서",
                        count: readingBooks,
                        total: totalBooks,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 도넛 차트 CustomPainter (오버플로우 방지 & 둥근 캡)
class DonutChartPainter extends CustomPainter {
  final double completedFraction;
  final Color completedColor;
  final Color readingColor;
  final Color bgColor;

  DonutChartPainter({
    required this.completedFraction,
    required this.completedColor,
    required this.readingColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 11.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // 배경 트랙
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);

    // 읽는 중 (남은 부분)
    if (completedFraction < 1.0) {
      final readingPaint = Paint()
        ..color = readingColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2 + (2 * math.pi * completedFraction),
        2 * math.pi * (1.0 - completedFraction),
        false,
        readingPaint,
      );
    }

    // 완독 완료 부분
    if (completedFraction > 0.0) {
      final completedPaint = Paint()
        ..color = completedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * completedFraction,
        false,
        completedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) =>
      oldDelegate.completedFraction != completedFraction;
}
