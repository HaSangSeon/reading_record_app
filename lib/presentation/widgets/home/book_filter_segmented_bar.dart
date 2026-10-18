import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import '../../controllers/book_controller.dart';

class BookFilterSegmentedBar extends ConsumerWidget {
  final BookFilterType currentFilter;
  final List<Book> allBooks;
  final bool isDark;

  const BookFilterSegmentedBar({
    super.key,
    required this.currentFilter,
    required this.allBooks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingCount = allBooks.where((b) => b.isCompleted == false).length;
    final completedCount = allBooks.where((b) => b.isCompleted == true).length;
    final totalCount = allBooks.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C28) : const Color(0xFFEDEAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF263246) : const Color(0xFFDCD5EE),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            ref: ref,
            title: '전체',
            icon: Icons.grid_view_rounded,
            count: totalCount,
            type: BookFilterType.all,
            isSelected: currentFilter == BookFilterType.all,
            isDark: isDark,
          ),
          _buildSegmentItem(
            ref: ref,
            title: '읽는 중',
            icon: Icons.menu_book_rounded,
            count: readingCount,
            type: BookFilterType.reading,
            isSelected: currentFilter == BookFilterType.reading,
            isDark: isDark,
          ),
          _buildSegmentItem(
            ref: ref,
            title: '완독',
            icon: Icons.check_circle_rounded,
            count: completedCount,
            type: BookFilterType.completed,
            isSelected: currentFilter == BookFilterType.completed,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required int count,
    required BookFilterType type,
    required bool isSelected,
    required bool isDark,
  }) {
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(bookFilterProvider.notifier).state = type;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF242E42) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF384763)
                        : const Color(0xFFD8D2EC),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.5,
                color: isSelected
                    ? primary
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -0.3,
                  color: isSelected
                      ? (isDark ? Colors.white : AppTheme.textPrimary)
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 4.5),
              // 카운트 뱃지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: isDark ? 0.3 : 0.12)
                      : (isDark
                                ? const Color(0xFF2C384E)
                                : const Color(0xFFDCD5EE))
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? primary
                        : (isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textLight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
