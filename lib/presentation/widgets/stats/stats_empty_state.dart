import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 도서가 없을 때 노출되는 빈 상태 위젯
class StatsEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const StatsEmptyState({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 52,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "등록된 도서가 아직 없습니다",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "책을 등록하고 독서 노트를 남기면\n다양한 분석 리포트가 완성됩니다.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
