import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/repository_providers.dart';
import '../controllers/notification_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/time_picker_select_dialog.dart';

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
            _buildHeroProfileCard(
              context: context,
              ref: ref,
              isDark: isDark,
              booksCount: booksCount,
              notesCount: notesCount,
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
            ),

            const SizedBox(height: 24),

            // 2. 독서 리마인더 알림 섹션
            _buildSectionHeader('독서 습관 리마인더', Icons.notifications_active_outlined, isDark),
            _buildNotificationCard(
              context: context,
              ref: ref,
              notificationState: notificationState,
              books: books,
              notes: notes,
              isDark: isDark,
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
            ),

            const SizedBox(height: 24),

            // 3. 화면 테마 설정 섹션
            _buildSectionHeader('화면 테마', Icons.palette_outlined, isDark),
            _buildThemeCard(
              ref: ref,
              themeMode: themeMode,
              isDark: isDark,
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
            ),

            const SizedBox(height: 24),

            // 4. 앱 정보 및 데이터 보호 안내
            _buildSectionHeader('앱 정보', Icons.info_outline_rounded, isDark),
            _buildAppInfoCard(
              context: context,
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

  /// 섹션 타이틀 헤더
  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 1. 프리미엄 서재 프로필 및 클라우드 동기화 히어로 카드
  Widget _buildHeroProfileCard({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required int booksCount,
    required int notesCount,
    required Color cardBgColor,
    required Color cardBorderColor,
  }) {
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLinked = user != null && !user.isAnonymous;
        final email = user?.email ?? '';

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
          child: Column(
            children: [
              // 상단: 타이틀 + 도움말 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: (isLinked ? const Color(0xFF10B981) : primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isLinked
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_sync_rounded,
                        color: isLinked ? const Color(0xFF10B981) : primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isLinked ? 'Google 클라우드 동기화' : '클라우드 백업 & 복원',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // 도움말 안내 칩 버튼
                    InkWell(
                      onTap: () => _showCloudSyncHelpDialog(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.help_outline_rounded, size: 14, color: primary),
                            const SizedBox(width: 4),
                            Text(
                              '안내',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 중단: 상세 상태 안내 + 로그인/연동 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF161B22)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF26303B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isLinked
                                        ? AppTheme.successColor
                                        : (isDark ? Colors.grey[500] : Colors.grey[600]),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isLinked ? '클라우드 동기화 켜짐' : '현재 스마트폰에만 저장 중',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isLinked
                                        ? AppTheme.successColor
                                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLinked
                                  ? '$email\n다른 기기(태블릿 등)와 실시간 자동 동기화됩니다.'
                                  : '기기 변경이나 앱 삭제 시 데이터 복원을 위해 Google 계정을 연결해 보세요.',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isLinked)
                        OutlinedButton(
                          onPressed: () => _handleUnlink(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('연동 해제', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _handleGoogleLink(context, ref),
                          icon: const Icon(Icons.account_circle_outlined, size: 16),
                          label: const Text(
                            'Google 로그인',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, thickness: 0.8, color: cardBorderColor),

              // 하단: 내 서재 독서 데이터 현황 카운터
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 19,
                            color: primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '보관 도서',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$booksCount권',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 18,
                      width: 1,
                      color: cardBorderColor,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 21,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '독서 기록',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$notesCount개',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 2. 독서 리마인더 알림 설정 카드
  Widget _buildNotificationCard({
    required BuildContext context,
    required WidgetRef ref,
    required NotificationSettingsState notificationState,
    required List<dynamic> books,
    required List<dynamic> notes,
    required bool isDark,
    required Color cardBgColor,
    required Color cardBorderColor,
  }) {
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

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
      child: Column(
        children: [
          // 스위치 타일
          SwitchListTile(
            value: notificationState.isEnabled,
            activeThumbColor: primary,
            activeTrackColor: primary.withValues(alpha: 0.4),
            onChanged: (val) async {
              final success = await ref
                  .read(notificationControllerProvider.notifier)
                  .toggleNotification(val);
              if (!success && val && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('알림 권한이 필요합니다. 기기 설정에서 알림을 허용해주세요.'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            secondary: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notificationState.isEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: primary,
                size: 22,
              ),
            ),
            title: const Text(
              '독서 습관 리마인더',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
            subtitle: Text(
              notificationState.isEnabled
                  ? '${notificationState.daysSummary} ${notificationState.time.format(context)}에 발송'
                  : '정해진 시간에 나만의 맞춤 독서 알림을 받습니다.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
          ),

          // 알림 활성화 시 확장 세부 패널
          if (notificationState.isEnabled) ...[
            Divider(height: 1, indent: 64, color: cardBorderColor),

            // 알림 시간 설정 타일
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              title: const Text(
                '알림 시간',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '기기 배터리 최적화 정책에 따라 몇 분 정도 유연하게 도착합니다.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notificationState.time.format(context),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_calendar_rounded, size: 14, color: primary),
                  ],
                ),
              ),
              onTap: () async {
                final picked = await TimePickerSelectDialog.show(
                  context: context,
                  initialTime: notificationState.time,
                  title: '독서 알림 시간 설정',
                );
                if (picked != null) {
                  await ref
                      .read(notificationControllerProvider.notifier)
                      .setTime(picked);
                }
              },
            ),

            Divider(height: 1, indent: 64, color: cardBorderColor),

            // 반복 요일 선택 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.event_repeat_rounded,
                              color: Color(0xFF6366F1),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '반복 요일',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        notificationState.daysSummary,
                        style: TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 요일 빠른 프리셋 버튼 (매일 / 평일 / 주말)
                  Row(
                    children: [
                      _buildWeekdayPresetChip(
                        label: '매일',
                        isSelected: notificationState.selectedDays.length == 7,
                        onTap: () => ref
                            .read(notificationControllerProvider.notifier)
                            .setDays([1, 2, 3, 4, 5, 6, 7]),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildWeekdayPresetChip(
                        label: '평일 (월~금)',
                        isSelected: notificationState.selectedDays.length == 5 &&
                            !notificationState.selectedDays.contains(6) &&
                            !notificationState.selectedDays.contains(7),
                        onTap: () => ref
                            .read(notificationControllerProvider.notifier)
                            .setDays([1, 2, 3, 4, 5]),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildWeekdayPresetChip(
                        label: '주말 (토·일)',
                        isSelected: notificationState.selectedDays.length == 2 &&
                            notificationState.selectedDays.contains(6) &&
                            notificationState.selectedDays.contains(7),
                        onTap: () => ref
                            .read(notificationControllerProvider.notifier)
                            .setDays([6, 7]),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 개별 요일 원형 토글 버튼 (월~일)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int d = 1; d <= 7; d++)
                        _buildDayCircleButton(
                          day: d,
                          isSelected: notificationState.selectedDays.contains(d),
                          onTap: () async {
                            final ok = await ref
                                .read(notificationControllerProvider.notifier)
                                .toggleDay(d);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('최소 1개 이상의 요일을 선택해야 합니다.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1, indent: 64, color: cardBorderColor),

            // 즉시 테스트 알림 전송 타일
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppTheme.successColor,
                  size: 19,
                ),
              ),
              title: const Text(
                '지금 즉시 테스트 알림 받기',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              subtitle: const Text(
                '현재 내 서재 데이터를 반영한 스마트 알림을 확인합니다.',
                style: TextStyle(fontSize: 11.5),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () async {
                await ref
                    .read(notificationControllerProvider.notifier)
                    .sendTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('테스트 알림이 발송되었습니다! 상단 알림바를 확인해 보세요.'),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 3. 화면 테마 설정 카드
  Widget _buildThemeCard({
    required WidgetRef ref,
    required ThemeMode themeMode,
    required bool isDark,
    required Color cardBgColor,
    required Color cardBorderColor,
  }) {
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
              Column(
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

  /// 4. 앱 정보 및 데이터 보호 안내 카드
  Widget _buildAppInfoCard({
    required BuildContext context,
    required bool isDark,
    required Color cardBgColor,
    required Color cardBorderColor,
  }) {
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
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            title: const Text('앱 버전', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppConstants.versionDisplay,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '최신',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 64, thickness: 0.8, color: cardBorderColor),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.teal,
                size: 20,
              ),
            ),
            title: const Text(
              '데이터 보호 및 개인정보 안내',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              '안전한 로컬 저장 및 클라우드 동기화 정책을 안내합니다.',
              style: TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => _showPrivacyDialog(context),
          ),
        ],
      ),
    );
  }

  /// 요일 프리셋 칩
  Widget _buildWeekdayPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF26303B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  /// 개별 요일 원형 버튼 (월~일)
  Widget _buildDayCircleButton({
    required int day,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    const dayNames = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    final isWeekend = day == 6 || day == 7;
    final activeColor = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected
              ? (isWeekend ? const Color(0xFFE11D48) : activeColor)
              : (isDark ? const Color(0xFF26303B) : const Color(0xFFF1F5F9)),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isWeekend ? const Color(0xFFE11D48) : activeColor)
                        .withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            dayNames[day] ?? '',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isWeekend
                      ? (isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444))
                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }

  /// 구글 계정 연동 처리
  Future<void> _handleGoogleLink(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final hiveService = ref.read(hiveServiceProvider);
      await FirebaseService().signInOrLinkWithGoogle(hiveService);

      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구글 계정이 성공적으로 연동되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연동 실패: $e')),
        );
      }
    }
  }

  /// 구글 계정 연동 해제 처리
  Future<void> _handleUnlink(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('연동 해제'),
        content: const Text(
          '정말 계정 연동을 해제하시겠습니까?\n이 기기의 데이터가 초기화되고 새로운 익명 계정으로 시작합니다.\n(클라우드의 기존 데이터는 안전하게 보존됩니다)',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('해제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final hiveService = ref.read(hiveServiceProvider);
      await FirebaseService().unlinkGoogle(hiveService);

      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연동이 해제되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해제 실패: $e')),
        );
      }
    }
  }

  /// 개인정보 및 보안 안내 다이얼로그
  void _showPrivacyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E242B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '데이터 보호 및 개인정보',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrivacyPoint(
                icon: Icons.phonelink_lock_rounded,
                color: Colors.green,
                title: '빠른 로컬 저장 및 안전한 클라우드 동기화',
                desc: '모든 독서 데이터는 기기(Hive)에 초고속으로 저장되며, 기기 변경이나 분실 시 복구를 위해 파이어베이스 클라우드에 암호화되어 안전하게 동기화됩니다.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                icon: Icons.search_rounded,
                color: Colors.blue,
                title: '온라인 도서 검색',
                desc: '도서 검색 시 카카오 및 구글 공식 검색 API를 통해 암호화된(HTTPS) 통신으로 책 제목과 표지 정보만을 안전하게 조회합니다.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                icon: Icons.ads_click_rounded,
                color: Colors.amber,
                title: '구글 AdMob 광고 연동',
                desc: '무료 앱 운영을 위해 구글 모바일 광고 SDK가 포함되어 있으며, 구글 플레이 스토어 정책을 철저히 준수합니다.',
                isDark: isDark,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 클라우드 동기화 및 백업 상세 안내 팝업 다이얼로그
  void _showCloudSyncHelpDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E242B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '클라우드 동기화 안내',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                question: 'Google 로그인은 꼭 해야 하나요?',
                answer: '아닙니다! 로그인하지 않아도 스마트폰 자체에 안전하게 저장되어 모든 독서 기록 기능을 100% 무료로 자유롭게 사용하실 수 있습니다.',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildHelpItem(
                question: 'Google 계정을 연결하면 무엇이 좋나요?',
                answer: '• 스마트폰을 분실하거나 교체해도 기존 책과 기록이 1초 만에 그대로 복원됩니다.\n• 태블릿 등 다른 기기에서도 동일한 계정으로 접속하면 실시간으로 함께 볼 수 있습니다.',
                icon: Icons.cloud_sync_rounded,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              const SizedBox(height: 14),
              _buildHelpItem(
                question: '지금까지 작성해 둔 내 기록이 사라지나요?',
                answer: '절대 사라지지 않습니다! 로그인하는 즉시 현재 스마트폰에 저장된 모든 도서와 기록이 Google 클라우드로 안전하게 자동 업로드됩니다.',
                icon: Icons.security_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required String question,
    required String answer,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                question,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 23),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
