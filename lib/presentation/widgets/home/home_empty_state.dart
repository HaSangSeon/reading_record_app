import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../book_form_dialog.dart';
import '../book_search_dialog.dart';

class HomeEmptyState extends StatelessWidget {
  final bool isDark;

  const HomeEmptyState({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 72,
              color: (isDark ? AppTheme.darkTextLight : AppTheme.textLight)
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '조건에 맞는 책이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 책을 등록하거나 온라인에서 검색해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => BookSearchDialog.show(context),
                  icon: const Icon(Icons.travel_explore_rounded, size: 18),
                  label: const Text('온라인 검색'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => BookFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('직접 등록'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                    foregroundColor: isDark
                        ? AppTheme.darkBackground
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
