import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// 0) 카드 포함 내용 선택 토글 (구절만 vs 구절+메모)
class QuoteCardMemoToggle extends StatelessWidget {
  final bool includeMemo;
  final ValueChanged<bool> onToggle;

  const QuoteCardMemoToggle({
    super.key,
    required this.includeMemo,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B384D) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 1. 구절만 공유
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (includeMemo) {
                  HapticFeedback.selectionClick();
                  onToggle(false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !includeMemo
                      ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !includeMemo
                      ? [
                          BoxShadow(
                            color: (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 16,
                      color: !includeMemo
                          ? Colors.white
                          : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '구절 공유',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            !includeMemo ? FontWeight.w700 : FontWeight.w500,
                        color: !includeMemo
                            ? Colors.white
                            : (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 2. 구절+메모 공유
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!includeMemo) {
                  HapticFeedback.selectionClick();
                  onToggle(true);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: includeMemo
                      ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: includeMemo
                      ? [
                          BoxShadow(
                            color: (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 16,
                      color: includeMemo
                          ? Colors.white
                          : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '구절+메모 공유',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            includeMemo ? FontWeight.w700 : FontWeight.w500,
                        color: includeMemo
                            ? Colors.white
                            : (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
