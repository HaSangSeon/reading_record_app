import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/repository_providers.dart';
import '../controllers/backup_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/theme_controller.dart';

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

    final cardBgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final cardBorderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: AppTheme.buildAppBarFlexibleSpace(isDark),
        title: Row(
          children: [
            Icon(
              Icons.settings_suggest_rounded,
              color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text('설정 및 데이터 백업'),
          ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 로컬 앱 안내 카드
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryLight.withValues(alpha: 0.1)
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% 온디바이스 로컬 저장소',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '서버로 전송되지 않으며, 스마트폰 기기 내 Hive 데이터베이스에 안전하게 보관됩니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('독서 리마인더 알림 (100% 온디바이스)', context),
            Card(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cardBorderColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: notificationState.isEnabled,
                    onChanged: (val) async {
                      final success = await ref
                          .read(notificationControllerProvider.notifier)
                          .toggleNotification(val, books: books, notes: notes);
                      if (!success && val && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              '알림 권한이 필요합니다. 기기 설정에서 알림을 허용해주세요.',
                            ),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                      ),
                    ),
                    title: const Text(
                      '감성 독서 리마인더 알림',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      '원하는 요일과 시간에 편안한 독서 습관을 챙겨주는 리마인더를 보냅니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  if (notificationState.isEnabled) ...[
                    Divider(height: 1, indent: 64, color: cardBorderColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      title: const Text(
                        '알림 시간 설정',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${notificationState.daysSummary} ${notificationState.time.format(context)}에 발송됩니다.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          notificationState.time.format(context),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: notificationState.time,
                        );
                        if (picked != null) {
                          await ref
                              .read(notificationControllerProvider.notifier)
                              .setTime(picked, books: books, notes: notes);
                        }
                      },
                    ),
                    Divider(height: 1, indent: 64, color: cardBorderColor),
                    // 요일 선택 섹션
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.event_repeat_rounded,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '반복 요일 선택',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '현재 설정: ${notificationState.daysSummary}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppTheme.primaryLight
                                            : AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 빠른 프리셋 버튼 (매일 / 평일 / 주말)
                          Row(
                            children: [
                              _buildWeekdayPresetChip(
                                label: '매일',
                                isSelected:
                                    notificationState.selectedDays.length == 7,
                                onTap: () => ref
                                    .read(
                                      notificationControllerProvider.notifier,
                                    )
                                    .setDays(
                                      [1, 2, 3, 4, 5, 6, 7],
                                      books: books,
                                      notes: notes,
                                    ),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              _buildWeekdayPresetChip(
                                label: '평일 (월~금)',
                                isSelected:
                                    notificationState.selectedDays.length ==
                                        5 &&
                                    !notificationState.selectedDays.contains(
                                      6,
                                    ) &&
                                    !notificationState.selectedDays.contains(7),
                                onTap: () => ref
                                    .read(
                                      notificationControllerProvider.notifier,
                                    )
                                    .setDays(
                                      [1, 2, 3, 4, 5],
                                      books: books,
                                      notes: notes,
                                    ),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              _buildWeekdayPresetChip(
                                label: '주말 (토·일)',
                                isSelected:
                                    notificationState.selectedDays.length ==
                                        2 &&
                                    notificationState.selectedDays.contains(
                                      6,
                                    ) &&
                                    notificationState.selectedDays.contains(7),
                                onTap: () => ref
                                    .read(
                                      notificationControllerProvider.notifier,
                                    )
                                    .setDays(
                                      [6, 7],
                                      books: books,
                                      notes: notes,
                                    ),
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 월~일 개별 요일 버튼 리스트
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (int d = 1; d <= 7; d++)
                                _buildDayCircleButton(
                                  day: d,
                                  isSelected: notificationState.selectedDays
                                      .contains(d),
                                  onTap: () => ref
                                      .read(
                                        notificationControllerProvider.notifier,
                                      )
                                      .toggleDay(d, books: books, notes: notes),
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, indent: 64, color: cardBorderColor),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: AppTheme.successColor,
                        ),
                      ),
                      title: const Text(
                        '지금 즉시 테스트 알림 받기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        '서재 데이터를 반영한 맞춤 알림이 어떻게 오는지 확인합니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await ref
                            .read(notificationControllerProvider.notifier)
                            .sendTestNotification(books: books, notes: notes);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '테스트 알림이 발송되었습니다! 상단 알림바를 확인해 보세요.',
                              ),
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

            const SizedBox(height: 24),
            _buildSectionHeader('화면 테마 설정 (Dark / Light)', context),
            Card(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cardBorderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('라이트', style: TextStyle(fontSize: 13)),
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('다크', style: TextStyle(fontSize: 13)),
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('시스템', style: TextStyle(fontSize: 13)),
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(newSelection.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('데이터 저장 현황', context),
            Card(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cardBorderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountItem(
                      '등록된 도서',
                      '$booksCount권',
                      Icons.menu_book_rounded,
                      context,
                    ),
                    Container(height: 36, width: 1, color: cardBorderColor),
                    _buildCountItem(
                      '작성된 독서 기록',
                      '$notesCount개',
                      Icons.edit_note_rounded,
                      context,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('안전 백업 및 복원 (스마트폰 교체 대비)', context),
            Card(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cardBorderColor),
              ),
              child: Column(
                children: [
                  // 원클릭 파일 공유
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.share_rounded,
                        color: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                      ),
                    ),
                    title: const Text(
                      '백업 파일 공유하기 (추천)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      '카카오톡(나와의 채팅), 구글 드라이브, 파일 앱으로 백업 파일을 전송합니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _exportAndShare(context, ref),
                  ),
                  Divider(height: 1, indent: 64, color: cardBorderColor),

                  // 파일 선택기 복원
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.folder_open_rounded,
                        color: AppTheme.successColor,
                      ),
                    ),
                    title: const Text(
                      '백업 파일 불러오기 (복원)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      '보관해둔 백업 파일(.json)을 선택해 서재를 복원합니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _importFromFile(context, ref),
                  ),
                  Divider(height: 1, indent: 64, color: cardBorderColor),

                  // 텍스트 복사/붙여넣기 고급 옵션
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.code_rounded, color: Colors.grey),
                    ),
                    title: const Text(
                      '텍스트 직접 복사 / 붙여넣기 (고급)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text(
                                  'JSON 복사',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () => _exportDataText(context, ref),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.paste_rounded, size: 16),
                                label: const Text(
                                  'JSON 붙여넣기',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () =>
                                    _showImportDialog(context, ref),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('데이터 관리', context),
            Card(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cardBorderColor),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                title: const Text(
                  '모든 데이터 초기화',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: const Text(
                  '서재의 모든 도서와 기록을 영구적으로 삭제합니다.',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () => _confirmResetAll(context, ref),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('앱 정보', context),
            Card(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cardBorderColor),
              ),
              child: const Column(
                children: [
                  ListTile(
                    title: Text('앱 버전', style: TextStyle(fontSize: 14)),
                    trailing: Text(
                      '1.0.0 (최신 버전)',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  Divider(height: 1, indent: 16),
                  ListTile(
                    title: Text('개발 및 지원', style: TextStyle(fontSize: 14)),
                    trailing: Text(
                      '독서한줄 팀',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCountItem(
    String label,
    String value,
    IconData icon,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(
          icon,
          color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 원클릭 백업 파일 공유
  Future<void> _exportAndShare(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(backupControllerProvider.notifier)
        .exportAndShareFile();
    if (!context.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '도서 ${result.books}권, 기록 ${result.notes}개의 백업 파일이 생성되었습니다.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('백업 파일 생성 실패: ${result.error}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 파일 선택기로 복원
  Future<void> _importFromFile(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(backupControllerProvider.notifier)
        .importFromFile();
    if (!context.mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('복원 완료! (도서 ${result.books}권, 기록 ${result.notes}개)'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result.error != null && result.error != '선택된 파일이 없습니다.') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('복원 실패: ${result.error}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportDataText(BuildContext context, WidgetRef ref) async {
    final jsonStr = await ref
        .read(backupControllerProvider.notifier)
        .exportData();
    if (!context.mounted || jsonStr == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.code_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('JSON 백업 데이터', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
              ),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                jsonStr,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('클립보드 복사'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonStr));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('백업 JSON이 클립보드에 복사되었습니다!'),
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
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool overwrite = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text(
            '데이터 복원 (JSON 붙여넣기)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '여기에 백업된 JSON 문자열을 붙여넣으세요...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text(
                    '기존 데이터 덮어쓰기 (초기화 후 복원)',
                    style: TextStyle(fontSize: 13, color: Colors.redAccent),
                  ),
                  value: overwrite,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: Colors.redAccent,
                  onChanged: (val) => setState(() => overwrite = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                final result = await ref
                    .read(backupControllerProvider.notifier)
                    .importData(text, overwrite: overwrite);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.success
                            ? '데이터 복원 완료! (도서 ${result.books}권, 노트 ${result.notes}개)'
                            : '복원 실패: ${result.error}',
                      ),
                      backgroundColor: result.success
                          ? AppTheme.successColor
                          : Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('복원 실행'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '모든 데이터 초기화',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '정말로 서재의 모든 책과 작성된 독서 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없으며, 백업 파일이 없다면 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final success = await ref
                  .read(backupControllerProvider.notifier)
                  .clearAllData();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '모든 데이터가 초기화되었습니다.' : '초기화 실패'),
                    backgroundColor: success
                        ? Colors.black87
                        : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('삭제하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayPresetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF1E242B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
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
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

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
              ? (isWeekend
                    ? (isDark
                          ? const Color(0xFFE11D48)
                          : const Color(0xFFE11D48))
                    : activeColor)
              : (isDark ? const Color(0xFF182028) : const Color(0xFFF1F5F9)),
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
                        ? (isDark
                              ? const Color(0xFFF87171)
                              : const Color(0xFFEF4444))
                        : (isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
