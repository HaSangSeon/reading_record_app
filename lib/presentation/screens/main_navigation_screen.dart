import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'quote_feed_screen.dart';
import 'settings_backup_screen.dart';
import 'stats_dashboard_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  DateTime? _lastBackPressed;

  static const List<Widget> _screens = [
    HomeScreen(),
    QuoteFeedScreen(),
    StatsDashboardScreen(),
    SettingsBackupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainNavigationIndexProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. 서브 탭(피드, 통계, 설정)에서 뒤로가기 시 홈 탭(내 서재)으로 이동
        if (currentIndex != 0) {
          ref.read(mainNavigationIndexProvider.notifier).state = 0;
          return;
        }

        // 2. 홈 탭에서 뒤로가기 시 2회 터치 안전 종료
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '뒤로가기 버튼을 한 번 더 누르면 종료됩니다.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: currentIndex, children: _screens),
        bottomNavigationBar: const AppBottomNavBar(),
      ),
    );
  }
}
