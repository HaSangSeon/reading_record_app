import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// 3) 내 사진 연출 효과 상세 컨트롤 박스 (사진 변경, 해제, 글자 색상 세그먼트, 어둡기/화이트톤 슬라이더)
class QuoteCardPhotoEffectControls extends StatelessWidget {
  final double imageDimOpacity;
  final bool isDarkTextColor;
  final VoidCallback onPickCustomImage;
  final VoidCallback onResetCustomImage;
  final ValueChanged<bool> onTextColorChanged;
  final ValueChanged<double> onDimOpacityChanged;

  const QuoteCardPhotoEffectControls({
    super.key,
    required this.imageDimOpacity,
    required this.isDarkTextColor,
    required this.onPickCustomImage,
    required this.onResetCustomImage,
    required this.onTextColorChanged,
    required this.onDimOpacityChanged,
  });

  Widget _buildTextColorSegment({
    required String title,
    required bool isSelected,
    required Color dotColor,
    required Color dotBorder,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2B384D) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: dotBorder, width: 0.8),
              ),
            ),
            const SizedBox(width: 5),
            Transform.translate(
              offset: const Offset(0, -0.5),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.0,
                  color: isSelected
                      ? (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)
                      : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B384D) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1) 상단 행: 타이틀 & 사진 변경 / 해제 버튼 (광학적 수직 중앙 정렬)
          SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Transform.translate(
                      offset: const Offset(0, -0.5),
                      child: Text(
                        '사진 연출 효과',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.0,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onPickCustomImage();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.primaryLight.withValues(alpha: 0.16)
                                : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.primaryLight.withValues(alpha: 0.35)
                                  : const Color(0xFFC7D2FE),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 12,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : const Color(0xFF4338CA),
                              ),
                              const SizedBox(width: 4),
                              Transform.translate(
                                offset: const Offset(0, -0.5),
                                child: Text(
                                  '사진 변경',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    height: 1.0,
                                    color: isDark
                                        ? AppTheme.primaryLight
                                        : const Color(0xFF4338CA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onResetCustomImage();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Transform.translate(
                                offset: const Offset(0, -0.5),
                                child: Text(
                                  '해제',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                    height: 1.0,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),
          Container(
            height: 1,
            color: isDark ? const Color(0xFF2B384D) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 9),

          // 2) 글자 색상 선택 (Option A: ⚪ 화이트 vs ⚫ 차콜 블랙)
          SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_color_text_rounded,
                      size: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Transform.translate(
                      offset: const Offset(0, -0.5),
                      child: Text(
                        '글자 색상',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 29,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131821)
                        : const Color(0xFFE9EEF4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTextColorSegment(
                        title: '화이트',
                        isSelected: !isDarkTextColor,
                        dotColor: Colors.white,
                        dotBorder: const Color(0xFFCBD5E1),
                        isDark: isDark,
                        onTap: () {
                          if (isDarkTextColor) {
                            HapticFeedback.selectionClick();
                            onTextColorChanged(false);
                          }
                        },
                      ),
                      const SizedBox(width: 2.5),
                      _buildTextColorSegment(
                        title: '차콜 블랙',
                        isSelected: isDarkTextColor,
                        dotColor: const Color(0xFF1E293B),
                        dotBorder: Colors.transparent,
                        isDark: isDark,
                        onTap: () {
                          if (!isDarkTextColor) {
                            HapticFeedback.selectionClick();
                            onTextColorChanged(true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 3) 배경 톤(어둡기/화이트 톤) 조절 슬라이더 행
          // 화이트 ↔ 차콜블랙 전환 시 슬라이더 시작 위치가 전혀 흔들리지 않도록 좌측 라벨 그룹 폭을 116px로 고정
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 116,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 좌측 아이콘 (16x16 고정 컨테이너 내 부드러운 페이드 전환)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Icon(
                              isDarkTextColor
                                  ? Icons.wb_sunny_rounded
                                  : Icons.tonality_rounded,
                              key: ValueKey(isDarkTextColor),
                              size: 14,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      // 라벨 텍스트: 고정 폭 54px 내에서 '어둡기' ↔ '화이트 톤' 크로스페이드
                      SizedBox(
                        width: 54,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            key: ValueKey(isDarkTextColor),
                            child: Transform.translate(
                              offset: const Offset(0, -0.5),
                              child: Text(
                                isDarkTextColor ? '화이트 톤' : '어둡기',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      // 퍼센트 뱃지: 고정 폭 36px으로 숫자 변경 시 레이아웃 요동 방지
                      Container(
                        width: 36,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Transform.translate(
                          offset: const Offset(0, -0.5),
                          child: Text(
                            '${(imageDimOpacity * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                              color: isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 슬라이더 바
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.5,
                        elevation: 1.5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 13,
                      ),
                      activeTrackColor: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                      inactiveTrackColor: isDark
                          ? Colors.white12
                          : const Color(0xFFCBD5E1),
                      thumbColor: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                      overlayColor: (isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor)
                          .withValues(alpha: 0.16),
                    ),
                    child: Slider(
                      value: imageDimOpacity,
                      min: 0.15,
                      max: 0.85,
                      divisions: 14,
                      onChanged: onDimOpacityChanged,
                    ),
                  ),
                ),
                // 우측 끝 아이콘 (16x16 고정 컨테이너 내 부드러운 페이드 전환)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Icon(
                        isDarkTextColor
                            ? Icons.wb_sunny_outlined
                            : Icons.brightness_2_rounded,
                        key: ValueKey(isDarkTextColor),
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


