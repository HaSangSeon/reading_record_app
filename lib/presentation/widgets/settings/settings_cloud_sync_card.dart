import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/repository_providers.dart';

class SettingsCloudSyncCard extends ConsumerWidget {
  final bool isDark;
  final int booksCount;
  final int notesCount;
  final Color cardBgColor;
  final Color cardBorderColor;

  const SettingsCloudSyncCard({
    super.key,
    required this.isDark,
    required this.booksCount,
    required this.notesCount,
    required this.cardBgColor,
    required this.cardBorderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
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
                          Expanded(
                            child: Text(
                              isLinked ? '클라우드 동기화 켜짐' : '현재 스마트폰에만 저장 중',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isLinked
                                    ? AppTheme.successColor
                                    : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                              ),
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
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: isLinked
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _handleManualSync(context, ref),
                                    icon: const Icon(Icons.sync_rounded, size: 14),
                                    label: const Text(
                                      '지금 동기화',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton(
                                    onPressed: () => _handleUnlink(context, ref),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(
                                        color: Color(0xFFFCA5A5),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      '연동 해제',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
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
        ),
      );
      },
    );
  }

  /// 수동 클라우드 동기화 처리
  Future<void> _handleManualSync(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final hiveService = ref.read(hiveServiceProvider);
      final firebaseService = ref.read(firebaseServiceProvider);
      final success = await firebaseService.syncWithCloud(hiveService);

      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    success
                        ? '클라우드와 최신 데이터로 동기화되었습니다.'
                        : '동기화 중 오류가 발생했습니다.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor:
                success ? const Color(0xFF10B981) : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('동기화 실패: $e')),
        );
      }
    }
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
