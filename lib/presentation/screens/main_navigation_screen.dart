import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/bottom_banner_ad_widget.dart';
import 'home_screen.dart';
import 'quote_feed_screen.dart';
import 'settings_backup_screen.dart';
import 'stats_dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    QuoteFeedScreen(),
    StatsDashboardScreen(),
    SettingsBackupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    final unselected = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 하단 4개 탭 메뉴 바로 위에 배치되는 Google AdMob 배너 광고
            const BottomBannerAdWidget(),
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFEDF0F5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildTabItem(
                    index: 0,
                    label: '내 서재',
                    icon: Icons.auto_stories_outlined,
                    activeIcon: Icons.auto_stories_rounded,
                    primary: primary,
                    unselected: unselected,
                  ),
                  _buildTabItem(
                    index: 1,
                    label: '한줄 피드',
                    icon: Icons.format_quote_outlined,
                    activeIcon: Icons.format_quote_rounded,
                    primary: primary,
                    unselected: unselected,
                  ),
                  _buildTabItem(
                    index: 2,
                    label: '독서 통계',
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    primary: primary,
                    unselected: unselected,
                  ),
                  _buildTabItem(
                    index: 3,
                    label: '설정 & 백업',
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    primary: primary,
                    unselected: unselected,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required Color primary,
    required Color unselected,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
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
