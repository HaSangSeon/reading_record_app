import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../book_form_dialog.dart';
import '../book_search_dialog.dart';

class AddBookOptionsSheet {
  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width > 600;

    Widget buildContent(BuildContext ctx, {bool isDialog = false}) {
      final mq = MediaQuery.of(ctx);
      final bottomInset = math.max(mq.viewPadding.bottom, mq.padding.bottom);
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1E1B2E),
                    AppTheme.darkSurface,
                    AppTheme.darkBackground,
                  ]
                : [
                    const Color(0xFFFAF8FE),
                    Colors.white,
                    const Color(0xFFF6F4FA),
                  ],
          ),
          borderRadius: isDialog
              ? BorderRadius.circular(28)
              : const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2D9F3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 드래그 핸들 바
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // 프리미엄 헤더 (아이콘 + 타이틀/서브타이틀 + 닫기 버튼)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  AppTheme.primaryLight,
                                  const Color(0xFF4F46E5),
                                ]
                              : [
                                  const Color(0xFF6366F1),
                                  AppTheme.primaryColor,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '새 도서 등록',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '나만의 서재에 소중한 책을 담아보세요',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 은은한 그라데이션 구분선
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.02),
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.02),
                            ]
                          : [
                              Colors.black.withValues(alpha: 0.02),
                              const Color(0xFFE2D9F3),
                              Colors.black.withValues(alpha: 0.02),
                            ],
                    ),
                  ),
                ),

                // 1. 온라인 도서 검색 카드 (추천)
                _buildBookAddOptionCard(
                  isDark: isDark,
                  badgeText: '추천 • 빠른 검색',
                  badgeColor: primary,
                  gradientColors: const [
                    Color(0xFF6366F1),
                    Color(0xFF0284C7),
                  ],
                  icon: Icons.travel_explore_rounded,
                  title: '온라인 도서 검색',
                  description: '국립중앙도서관·카카오 공식 DB를 통해\n표지와 도서 정보를 1초 만에 자동 완성해요.',
                  borderColor: isDark
                      ? primary.withValues(alpha: 0.25)
                      : const Color(0xFFDDD6FE),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final success = await BookSearchDialog.show(context);
                    if (success == true && context.mounted) {
                      AppTheme.showPremiumSnackBar(context, '도서가 등록되었습니다.');
                    }
                  },
                ),

                const SizedBox(height: 12),

                // 2. 직접 입력하여 등록 카드
                _buildBookAddOptionCard(
                  isDark: isDark,
                  badgeText: '자유로운 수기 작성',
                  badgeColor: AppTheme.accentColor,
                  gradientColors: const [
                    Color(0xFFF59E0B),
                    Color(0xFFEA580C),
                  ],
                  icon: Icons.edit_note_rounded,
                  title: '직접 입력하여 등록',
                  description: '소장 중인 책의 실물 표지를 직접 촬영하고\n원하는 세부 정보와 메모를 자유롭게 기록해요.',
                  borderColor: isDark
                      ? AppTheme.accentColor.withValues(alpha: 0.25)
                      : const Color(0xFFFED7AA),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final success = await BookFormDialog.show(context);
                    if (success == true && context.mounted) {
                      AppTheme.showPremiumSnackBar(context, '도서가 등록되었습니다.');
                    }
                  },
                ),

                const SizedBox(height: 14),

                // 하단 부드러운 팁 문구
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 14,
                        color: isDark
                            ? AppTheme.darkTextLight
                            : AppTheme.textLight,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '검색되지 않는 독립출판물이나 고서는 직접 등록을 추천해요.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isWide) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: 500,
            child: buildContent(ctx, isDialog: true),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => buildContent(ctx),
      );
    }
  }

  static Widget _buildBookAddOptionCard({
    required bool isDark,
    required String badgeText,
    required Color badgeColor,
    required List<Color> gradientColors,
    required IconData icon,
    required String title,
    required String description,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측 입체 그라데이션 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 15),

                // 중앙 텍스트 그룹
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 캡슐 태그 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(
                            alpha: isDark ? 0.18 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? (badgeColor == AppTheme.primaryColor
                                    ? AppTheme.primaryLight
                                    : badgeColor)
                                : badgeColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // 타이틀
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // 설명
                      Text(
                        description,
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

                const SizedBox(width: 8),

                // 우측 진입 버튼 아이콘
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDark
                        ? AppTheme.darkTextLight
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
