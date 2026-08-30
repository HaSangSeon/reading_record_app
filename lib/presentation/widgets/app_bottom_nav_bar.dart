import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'bottom_banner_ad_widget.dart';

/// 전역 메인 네비게이션 탭 인덱스 프로바이더 (0: 내 서재, 1: 한줄 피드, 2: 독서 통계, 3: 설정 & 백업)
final mainNavigationIndexProvider = StateProvider<int>((ref) => 0);

class AppBottomNavBar extends ConsumerWidget {
  /// 상세 화면 등 서브 페이지에서 호출된 경우 true (탭 클릭 시 pop 처리)
  final bool isSubScreen;

  const AppBottomNavBar({super.key, this.isSubScreen = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(mainNavigationIndexProvider);
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    final unselected = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 하단 4개 탭 메뉴 바로 위에 배치되는 Google AdMob 배너 광고
          const BottomBannerAdWidget(),
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [
                        Color(0xFF221A36), // 상단 로얄 미드나잇 바이올렛
                        Color(0xFF181329), // 중간 딥 바이올렛
                        Color(0xFF120E20), // 하단 오닉스 바이올렛
                      ]
                    : const [
                        Color(0xFFFBF9FF), // 상단 맑은 화이트 라벤더
                        Color(0xFFF2ECF9), // 중간 소프트 라벤더
                        Color(0xFFE8E0F6), // 하단 감성 인디고 바이올렛
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E2749)
                      : const Color(0xFFDCD5F0),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFF4C3A93).withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 상단 은은한 엠보싱 하이라이트 광원 라인
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1.0,
                  child: Container(
                    color: isDark
                        ? const Color(0xFF818CF8).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Row(
                  children: [
                    _buildTabItem(
                      context: context,
                      ref: ref,
                      index: 0,
                      currentIndex: currentIndex,
                      label: '내 서재',
                      icon: Icons.auto_stories_outlined,
                      activeIcon: Icons.auto_stories_rounded,
                      primary: primary,
                      unselected: unselected,
                    ),
                    _buildTabItem(
                      context: context,
                      ref: ref,
                      index: 1,
                      currentIndex: currentIndex,
                      label: '한줄 피드',
                      icon: Icons.format_quote_outlined,
                      activeIcon: Icons.format_quote_rounded,
                      primary: primary,
                      unselected: unselected,
                    ),
                    _buildTabItem(
                      context: context,
                      ref: ref,
                      index: 2,
                      currentIndex: currentIndex,
                      label: '독서 통계',
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart_rounded,
                      primary: primary,
                      unselected: unselected,
                    ),
                    _buildTabItem(
                      context: context,
                      ref: ref,
                      index: 3,
                      currentIndex: currentIndex,
                      label: '설정 & 백업',
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings_rounded,
                      primary: primary,
                      unselected: unselected,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required int currentIndex,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required Color primary,
    required Color unselected,
  }) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(mainNavigationIndexProvider.notifier).state = index;
          if (isSubScreen) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        splashColor: primary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: isDark ? 0.2 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 21,
                  color: isSelected ? primary : unselected,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? primary : unselected,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
