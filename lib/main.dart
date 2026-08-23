import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 100% 로컬 Hive 데이터베이스 초기화 및 Box 오픈
  final hiveService = HiveService();
  await hiveService.init();

  runApp(
    const ProviderScope(
      child: ReadingRecordApp(),
    ),
  );
}

class ReadingRecordApp extends ConsumerWidget {
  const ReadingRecordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: '초경량 로컬 독서 기록',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainNavigationScreen(),
    );
  }
}
