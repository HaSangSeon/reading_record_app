import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 2. 빠른 지표 행 (완독 도서, 독서 기록, 평균 평점 3개 카드)
class StatsQuickMetricsRow extends StatelessWidget {
  final int completedBooks;
  final int totalNotes;
  final double avgRating;

  const StatsQuickMetricsRow({
    super.key,
    required this.completedBooks,
    required this.totalNotes,
    required this.avgRating,
  });

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String unit,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B28) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.task_alt_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFF10B981).withValues(alpha: 0.12),
            value: "$completedBooks",
            unit: "권",
            label: "완독 도서",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.format_quote_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
            value: "$totalNotes",
            unit: "개",
            label: "독서 기록",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            value: avgRating > 0 ? avgRating.toStringAsFixed(1) : "-",
            unit: avgRating > 0 ? "점" : "",
            label: "평균 평점",
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}
