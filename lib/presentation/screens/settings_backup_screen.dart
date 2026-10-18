import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/repository_providers.dart';
import '../controllers/notification_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/settings/settings_widgets.dart';

class SettingsBackupScreen extends ConsumerWidget {
  const SettingsBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeControllerProvider);
    final notificationState = ref.watch(notificationControllerProvider);
    final booksAsync = ref.watch(allBooksStreamProvider);
    final notesAsync = ref.watch(allNotesStreamProvider);

    final books = booksAsync.value ?? [];
    final notes = notesAsync.value ?? [];
    final booksCount = books.length;
    final notesCount = notes.length;

    final cardBgColor = isDark ? const Color(0xFF1E242B) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF2C3540) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: AppTheme.buildAppBarFlexibleSpace(isDark),
        title: const Text(
          '설정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isDark ? Colors.amberAccent : AppTheme.textSecondary,
            ),
            tooltip: isDark ? '라이트 모드로 전환' : '다크 모드로 전환',
            onPressed: () =>
                ref.read(themeControllerProvider.notifier).toggleTheme(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프리미엄 서재 프로필 & 클라우드 동기화 히어로 카드
            SettingsCloudSyncCard(
              isDark: isDark,
              booksCount: booksCount,
              notesCount: notesCount,
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
            ),

            const SizedBox(height: 24),

            // 2. 독서 리마인더 알림 섹션
            SettingsSectionHeader(
              title: '독서 습관 리마인더',
              icon: Icons.notifications_active_outlined,
              isDark: isDark,
            ),
            SettingsNotificationCard(
              notificationState: notificationState,
              books: books,
              notes: notes,
              isDark: isDark,
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
            ),

            const SizedBox(height: 24),

            // 3. 화면 테마 설정 섹션
            SettingsSectionHeader(
              title: '화면 테마',
              icon: Icons.palette_outlined,
              isDark: isDark,
            ),
            SettingsThemeCard(
              themeMode: themeMode,
              isDark: isDark,
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
            ),

            const SizedBox(height: 24),

            // 4. 앱 정보 및 데이터 보호 안내
            SettingsSectionHeader(
              title: '앱 정보',
              icon: Icons.info_outline_rounded,
              isDark: isDark,
            ),
            SettingsAppInfoCard(
              isDark: isDark,
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
