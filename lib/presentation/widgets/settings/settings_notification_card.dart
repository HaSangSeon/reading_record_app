import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/notification_controller.dart';
import '../time_picker_select_dialog.dart';

class SettingsNotificationCard extends ConsumerWidget {
  final NotificationSettingsState notificationState;
  final List<dynamic> books;
  final List<dynamic> notes;
  final bool isDark;
  final Color cardBgColor;
  final Color cardBorderColor;

  const SettingsNotificationCard({
    super.key,
    required this.notificationState,
    required this.books,
    required this.notes,
    required this.isDark,
    required this.cardBgColor,
    required this.cardBorderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
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
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(
                          Icons.notifications_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '알림 권한이 비활성화되어 있습니다. 기기 설정에서 알림을 허용해주세요.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    duration: const Duration(seconds: 3),
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

                  // 개별 요일 원형 토글 버튼 (월~일) - 태블릿 대화면에서 과도하게 벌어지지 않도록 최적 너비로 제한
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final rowWidth = constraints.maxWidth.clamp(0.0, 390.0);
                      return SizedBox(
                        width: rowWidth,
                        child: Row(
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
                      );
                    },
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
}
