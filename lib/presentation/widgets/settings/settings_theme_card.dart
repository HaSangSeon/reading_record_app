import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/theme_controller.dart';

class SettingsThemeCard extends ConsumerWidget {
  final ThemeMode themeMode;
  final bool isDark;
  final Color cardBgColor;
  final Color cardBorderColor;

  const SettingsThemeCard({
    super.key,
    required this.themeMode,
    required this.isDark,
    required this.cardBgColor,
    required this.cardBorderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.brightness_4_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '테마 모드 선택',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '취향에 따라 라이트, 다크, 시스템 모드를 적용합니다.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('라이트', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  icon: Icon(Icons.light_mode_rounded, size: 17),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('다크', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  icon: Icon(Icons.dark_mode_rounded, size: 17),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('시스템', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  icon: Icon(Icons.brightness_auto_rounded, size: 17),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                ref
                    .read(themeControllerProvider.notifier)
                    .setThemeMode(newSelection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.standard,
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
