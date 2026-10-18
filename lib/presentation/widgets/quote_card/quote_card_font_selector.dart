import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'quote_card_font.dart';

/// 1) 서체 스타일 선택 세그먼트 (13가지 다채로운 감성 폰트)
class QuoteCardFontSelector extends StatelessWidget {
  final List<QuoteCardFont> fonts;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const QuoteCardFontSelector({
    super.key,
    required this.fonts,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFont = fonts[selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  size: 16,
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '서체 스타일',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '${currentFont.name} · ${currentFont.category}',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final font = fonts[index];
              final isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor)
                        : (isDark
                            ? const Color(0xFF1E2633)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark
                              ? const Color(0xFF2B384D)
                              : const Color(0xFFE2E8F0)),
                      width: 1,
                    ),
                    boxShadow: isSelected
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
                  child: Center(
                    child: Text(
                      font.name,
                      style: font.fontBuilder(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
