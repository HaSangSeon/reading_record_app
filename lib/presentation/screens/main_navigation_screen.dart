import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'quote_feed_screen.dart';
import 'settings_backup_screen.dart';
import 'stats_dashboard_screen.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    QuoteFeedScreen(),
    StatsDashboardScreen(),
    SettingsBackupScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavigationIndexProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
