import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/repository_providers.dart';
import '../controllers/backup_controller.dart';
import '../controllers/theme_controller.dart';

class SettingsBackupScreen extends ConsumerWidget {
  const SettingsBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeControllerProvider);
    final booksAsync = ref.watch(allBooksStreamProvider);
    final notesAsync = ref.watch(allNotesStreamProvider);

    final booksCount = booksAsync.value?.length ?? 0;
    final notesCount = notesAsync.value?.length ?? 0;

    final cardBgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final cardBorderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    return Scaffold(
      appBar: AppBar(
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
                    color:
                        isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
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
                          '서버로 전송되지 않으며, 기기 내 Hive 데이터베이스에 안전하게 보관됩니다.',
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
                          borderRadius: BorderRadius.circular(12)),
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
                    _buildCountItem('등록된 도서', '$booksCount권',
                        Icons.menu_book_rounded, context),
                    Container(height: 36, width: 1, color: cardBorderColor),
                    _buildCountItem('작성된 독서 노트', '$notesCount개',
                        Icons.edit_note_rounded, context),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('백업 및 복원 (JSON)', context),
            Card(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cardBorderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.file_upload_outlined,
                        color: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                      ),
                    ),
                    title: const Text(
                      '데이터 내보내기 (백업)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      '모든 도서와 독서 기록을 JSON 형식으로 복사/저장합니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _exportData(context, ref),
                  ),
                  Divider(height: 1, indent: 64, color: cardBorderColor),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.file_download_outlined,
                          color: AppTheme.successColor),
                    ),
                    title: const Text(
                      '데이터 가져오기 (복원)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      '백업된 JSON 데이터를 붙여넣어 서재를 복원합니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showImportDialog(context, ref),
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
                  child: const Icon(Icons.delete_forever_rounded,
                      color: Colors.redAccent),
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
      String label, String value, IconData icon, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon,
            color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
            size: 24),
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

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final jsonStr =
        await ref.read(backupControllerProvider.notifier).exportData();
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
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
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
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
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
                        borderRadius: BorderRadius.circular(10)),
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
          title: const Text('데이터 복원 (JSON 붙여넣기)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      content: Text(result.success
                          ? '데이터 복원 완료! (도서 ${result.books}권, 노트 ${result.notes}개)'
                          : '복원 실패: ${result.error}'),
                      backgroundColor:
                          result.success ? AppTheme.successColor : Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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
        title: const Text('⚠️ 모든 데이터 초기화',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: const Text(
          '정말로 모든 도서와 독서 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(fontSize: 14),
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
              Navigator.pop(ctx);
              await ref.read(backupControllerProvider.notifier).clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('모든 데이터가 초기화되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('영구 삭제'),
          ),
        ],
      ),
    );
  }
}
