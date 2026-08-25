import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int dailyReminderNotificationId = 100;
  static const int testNotificationId = 999;
  static const String channelId = 'reading_reminder_channel';
  static const String channelName = '독서 리마인더';
  static const String channelDescription = '매일 정기 독서 알림 및 명문장 배달';

  bool _isInitialized = false;

  /// 로컬 알림 플러그인 및 타임존 초기화
  Future<void> init() async {
    if (_isInitialized) return;

    // 타임존 데이터베이스 초기화
    tz.initializeTimeZones();
    try {
      // 한국 표준시(KST) 또는 로컬 시간대 설정
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // 타임존 로드 실패 시 기본 UTC 기반 로컬 유지
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[Notification] 알림 클릭 감지: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  /// 알림 권한 요청 (Android 13+ 및 iOS/macOS)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else if (Platform.isMacOS) {
      final macImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      final granted = await macImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// 안전하고 편안한 저녁 독서 리마인더 메시지 생성 (개인 메모 노출 방지)
  ({String title, String body}) _generateSmartMessage({
    List<Book>? books,
    List<Note>? notes,
  }) {
    final random = Random();

    // 현재 읽고 있는 도서가 있는 경우 -> 책 제목 기반의 편안한 독서 권유
    final readingBooks = (books ?? [])
        .where((b) => !b.isCompleted && b.readPages > 0)
        .toList();

    if (readingBooks.isNotEmpty) {
      final selectedBook = readingBooks[random.nextInt(readingBooks.length)];
      final templates = [
        '오늘 하루도 수고 많으셨어요. 잠들기 전 《${selectedBook.title}》과 함께 편안한 밤 보내세요 🌙',
        '《${selectedBook.title}》 ${selectedBook.progressPercentage}% 진행 중! 잠들기 전 잠깐의 독서로 하루를 채워보세요 📖',
        '바쁜 일상 속 작은 쉼표, 《${selectedBook.title}》과 함께 독서의 여유를 챙겨보세요 ✨',
      ];
      return (
        title: '오늘의 독서 리마인더 📖',
        body: templates[random.nextInt(templates.length)],
      );
    }

    // 기본 정갈한 독서 권유 문구
    final defaultMessages = [
      '오늘 하루도 수고 많으셨어요. 잠들기 전 마음을 채우는 책 한 장 어떠세요? 🌙',
      '바쁜 일상 속 작은 쉼표, 나만의 서재에서 독서의 즐거움을 느껴보세요 ☕',
      '독서는 나를 위한 가장 따뜻한 대화입니다. 오늘 밤 책 한 쪽을 펼쳐보세요 ✨',
    ];

    return (
      title: '편안한 저녁 독서 시간 🌙',
      body: defaultMessages[random.nextInt(defaultMessages.length)],
    );
  }

  /// 매일 지정된 시각에 반복 실행되는 스마트 독서 알림 스케줄링
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    List<Book>? books,
    List<Note>? notes,
  }) async {
    await init();
    await cancelDailyReminder();

    final message = _generateSmartMessage(books: books, notes: notes);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 설정한 시각이 이미 오늘 지났다면 다음 날로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        message.body,
        contentTitle: message.title,
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: dailyReminderNotificationId,
        title: message.title,
        body: message.body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[Notification] 매일 $hour시 $minute분 독서 알림 스케줄 완료');
    } catch (e) {
      debugPrint('[Notification] 스케줄링 오류: $e');
    }
  }

  /// 즉시 테스트 알림 발송
  Future<void> showInstantTestNotification({
    List<Book>? books,
    List<Note>? notes,
  }) async {
    await init();
    await requestPermissions();

    final message = _generateSmartMessage(books: books, notes: notes);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        message.body,
        contentTitle: message.title,
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id: testNotificationId,
      title: message.title,
      body: message.body,
      notificationDetails: notificationDetails,
    );
  }

  /// 알림 취소
  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(id: dailyReminderNotificationId);
  }

  /// 모든 알림 취소
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
