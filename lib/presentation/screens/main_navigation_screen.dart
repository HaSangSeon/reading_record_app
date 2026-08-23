import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';
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
    StatsDashboardScreen(),
    SettingsBackupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          indicatorColor: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
              .withValues(alpha: 0.2),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(
                Icons.menu_book_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
              label: '내 서재',
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(
                Icons.bar_chart_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
              label: '독서 통계',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: Icon(
                Icons.settings_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
              label: '설정 & 백업',
            ),
          ],
        ),
      ),
    );
  }
}
