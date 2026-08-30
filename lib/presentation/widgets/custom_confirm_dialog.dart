import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 프리미엄 커스텀 삭제 / 확인 모달 다이얼로그
class CustomConfirmDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? highlightedTarget,
    String confirmText = '삭제하기',
    String cancelText = '취소',
    bool isDestructive = true,
    IconData icon = Icons.delete_outline_rounded,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2230) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2C394E) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 상단 아이콘 뱃지
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? const Color(
                            0xFFEF4444,
                          ).withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDestructive
                          ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                          : (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isDestructive
                        ? const Color(0xFFEF4444)
                        : (isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. 타이틀
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // 3. 타겟 하이라이트 박스 (도서명 등)
                if (highlightedTarget != null &&
                    highlightedTarget.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF101724)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF263345)
                            : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '“$highlightedTarget”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 4. 상세 안내 메시지
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),

                // 5. 하단 버튼 영역 (취소 / 삭제)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive
                              ? const Color(0xFFEF4444)
                              : (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
