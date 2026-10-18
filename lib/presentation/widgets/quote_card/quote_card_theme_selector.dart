import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'quote_card_theme.dart';

/// 2) 배경 테마 색상 선택기 (내 사진 앨범 + 12가지 감성 프리셋)
class QuoteCardThemeSelector extends StatelessWidget {
  final List<QuoteCardTheme> themes;
  final int selectedThemeIndex;
  final bool isUsingCustomPhoto;
  final File? customImageFile;
  final ValueChanged<int> onSelectTheme;
  final VoidCallback onPickCustomImage;
  final VoidCallback onSelectExistingPhoto;

  const QuoteCardThemeSelector({
    super.key,
    required this.themes,
    required this.selectedThemeIndex,
    required this.isUsingCustomPhoto,
    this.customImageFile,
    required this.onSelectTheme,
    required this.onPickCustomImage,
    required this.onSelectExistingPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 16,
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '배경 테마',
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
              isUsingCustomPhoto ? '내 사진 앨범' : themes[selectedThemeIndex].name,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
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
            itemCount: 1 + themes.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                // 내 사진 선택 칩
                final isSelected = isUsingCustomPhoto;
                return GestureDetector(
                  onTap: () {
                    if (customImageFile == null) {
                      onPickCustomImage();
                    } else {
                      onSelectExistingPhoto();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF312E81)
                              : const Color(0xFFEEF2FF))
                          : (isDark
                              ? const Color(0xFF1E2633)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? Colors.amberAccent
                                : AppTheme.primaryColor)
                            : (isDark
                                ? const Color(0xFF2B384D)
                                : const Color(0xFFCBD5E1)),
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isSelected ? 0.2 : 0.06,
                          ),
                          blurRadius: isSelected ? 6 : 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (customImageFile != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              customImageFile!,
                              width: 22,
                              height: 22,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ] else ...[
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 17,
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          '내 사진',
                          style: TextStyle(
                            color: isSelected
                                ? (isDark
                                    ? Colors.white
                                    : AppTheme.primaryColor)
                                : (isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary),
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final themeIndex = index - 1;
              final theme = themes[themeIndex];
              final isSelected =
                  !isUsingCustomPhoto && selectedThemeIndex == themeIndex;

              return GestureDetector(
                onTap: () => onSelectTheme(themeIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: theme.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? (isDark
                              ? Colors.amberAccent
                              : AppTheme.primaryColor)
                          : (theme.borderColor ??
                              Colors.black.withValues(alpha: 0.08)),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isSelected ? 0.2 : 0.08,
                        ),
                        blurRadius: isSelected ? 6 : 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      theme.name,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
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
