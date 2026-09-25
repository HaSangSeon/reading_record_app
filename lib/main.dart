import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ads/admob_service.dart';
import 'core/database/hive_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/network_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/theme_controller.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드로 화면 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 1. 로컬 Hive 데이터베이스 초기화 및 Box 오픈
  final hiveService = HiveService();
  await hiveService.init();

  // 2. Firebase 초기화 및 익명 로그인, 오프라인 지속성 설정
  final firebaseService = FirebaseService();
  await firebaseService.init();

  // 3. 네트워크 상태 모니터링 초기화 (오프라인 -> 온라인 복귀 시 자동 클라우드 재동기화)
  final networkSyncService = NetworkSyncService();
  await networkSyncService.init(
    onBackOnlineCallback: () => firebaseService.syncAllLocalToCloud(hiveService),
  );

  // 4. 로컬 Hive와 Firebase 클라우드 초기 양방향 동기화 (기존 데이터 업로드 / 재설치 시 복원)
  firebaseService.initialSyncWithHive(hiveService).catchError((_) {});

  // 5. 로컬 푸시 알림 서비스 초기화 및 활성 알림 스케줄 복구
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.rescheduleIfEnabled();

  // 6. Google AdMob 초기화
  await AdMobService().init();

  runApp(const ProviderScope(child: ReadingRecordApp()));
}

class ReadingRecordApp extends ConsumerWidget {
  const ReadingRecordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: '독서한줄',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: NetworkSyncService().scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainNavigationScreen(),
    );
  }
}
