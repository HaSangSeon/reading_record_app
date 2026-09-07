import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
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

  /// 로컬 알림 플러그인 및 기기 동적 타임존 초기화
  Future<void> init() async {
    if (_isInitialized) return;

    // 타임존 데이터베이스 초기화
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final currentTimeZone = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      debugPrint('[Notification] 기기 로컬 타임존 설정: $currentTimeZone');
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      } catch (_) {
        // 타임존 로드 실패 시 기본 UTC 기반 로컬 유지
      }
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
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

    // Android 8.0+ 필수: 시스템 알림 채널 사전 등록 (소리, 진동, 헤드업 배너 보장)
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      debugPrint('[Notification] Android 알림 채널 등록 완료: $channelId');
    }

    _isInitialized = true;
  }

  /// 알림 권한 요청 (Android 13+ 및 iOS/macOS)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidImplementation
          ?.requestNotificationsPermission();
      // Android 12 이하는 null 반환 가능하므로 true 폴백
      return granted ?? true;
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else if (Platform.isMacOS) {
      final macImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final granted = await macImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// 요일별 특색과 현재 읽고 있는 도서 상태를 반영한 스마트 알림 메시지 생성
  ({String title, String body}) _generateSmartMessage({
    List<Book>? books,
    List<Note>? notes,
    int? dayOfWeek, // 1=월 ~ 7=일
  }) {
    final random = Random();

    // 현재 읽고 있는 도서 (미완독 && 페이지 > 0)
    final readingBooks = (books ?? [])
        .where((b) => !b.isCompleted && b.readPages > 0)
        .toList();

    const weekdayNames = {
      1: '월요일',
      2: '화요일',
      3: '수요일',
      4: '목요일',
      5: '금요일',
      6: '토요일',
      7: '일요일',
    };
    final dayLabel = dayOfWeek != null ? weekdayNames[dayOfWeek] : null;

    if (readingBooks.isNotEmpty) {
      // 요일 인덱스로 책을 분배하여 여러 권을 골고루 리마인드
      final bookIndex = dayOfWeek != null
          ? (dayOfWeek - 1) % readingBooks.length
          : random.nextInt(readingBooks.length);
      final selectedBook = readingBooks[bookIndex];

      final templates = <String>[
        if (dayOfWeek == 1) ...[
          '새로운 한 주의 시작, 잠들기 전 《${selectedBook.title}》 한 장으로 마음을 차분히 정돈해 보세요 🌙',
          '《${selectedBook.title}》 ${selectedBook.progressPercentage}% 진행 중! 활기찬 한 주의 독서 습관을 시작해 보세요 📖',
        ] else if (dayOfWeek == 5) ...[
          '한 주 동안 고생 많으셨어요! 불금의 밤, 《${selectedBook.title}》과 함께 포근한 쉼을 누려보세요 ✨',
          '《${selectedBook.title}》 ${selectedBook.progressPercentage}% 달성! 주말을 앞두고 잠시 책 속으로 여행을 떠나볼까요? 📚',
        ] else if (dayOfWeek == 6 || dayOfWeek == 7) ...[
          '여유로운 주말 저녁, 따뜻한 차 한 잔과 함께 《${selectedBook.title}》을 펼쳐보세요 ☕',
          '주말 독서 힐링 타임! 《${selectedBook.title}》의 다음 이야기가 기다리고 있어요 📖',
        ] else ...[
          '오늘 하루도 수고 많으셨어요. 잠들기 전 《${selectedBook.title}》과 함께 편안한 밤 보내세요 🌙',
          '《${selectedBook.title}》 ${selectedBook.progressPercentage}% 진행 중! 잠들기 전 잠깐의 독서로 하루를 채워보세요 📖',
          '바쁜 일상 속 작은 쉼표, 《${selectedBook.title}》과 함께 독서의 여유를 챙겨보세요 ✨',
        ],
      ];

      return (
        title: dayLabel != null ? '$dayLabel 저녁 독서 리마인더 📖' : '오늘의 독서 리마인더 📖',
        body: templates[random.nextInt(templates.length)],
      );
    }

    // 등록된 읽고 있는 책이 없을 때 기본 문구
    final defaultTemplates = <String>[
      if (dayOfWeek == 5 || dayOfWeek == 6 || dayOfWeek == 7) ...[
        '여유로운 주말, 마음을 채우는 책 한 장과 함께 편안한 쉼을 누려보세요 ☕',
        '나를 위한 가장 따뜻한 주말의 대화, 나만의 서재에서 독서의 즐거움을 느껴보세요 ✨',
      ] else ...[
        '오늘 하루도 수고 많으셨어요. 잠들기 전 마음을 채우는 책 한 장 어떠세요? 🌙',
        '바쁜 일상 속 작은 쉼표, 나만의 서재에서 독서의 즐거움을 느껴보세요 ☕',
        '독서는 나를 위한 가장 따뜻한 대화입니다. 오늘 밤 책 한 쪽을 펼쳐보세요 ✨',
      ],
    ];

    return (
      title: dayLabel != null ? '$dayLabel 저녁 독서 시간 🌙' : '편안한 저녁 독서 시간 🌙',
      body: defaultTemplates[random.nextInt(defaultTemplates.length)],
    );
  }

  /// 지정된 요일(1=월~7=일) 및 시각에 반복 실행되는 스마트 독서 알림 스케줄링
  Future<void> scheduleReminder({
    required int hour,
    required int minute,
    required List<int> days,
    List<Book>? books,
    List<Note>? notes,
  }) async {
    await init();
    // 선택에서 빠진 요일만 개별 취소하여 안드로이드 시스템 NotificationManager rate limit 방지
    for (int day = 1; day <= 7; day++) {
      if (!days.contains(day)) {
        await _notificationsPlugin.cancel(
          id: dailyReminderNotificationId + day,
        );
      }
    }
    await _notificationsPlugin.cancel(id: dailyReminderNotificationId);

    if (days.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);

    for (final day in days) {
      if (day < 1 || day > 7) continue;

      // 요일마다 개별화된 문구 생성 (요일별 특색 및 여러 책 고루 분배)
      final message = _generateSmartMessage(
        books: books,
        notes: notes,
        dayOfWeek: day,
      );

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
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

      var daysUntil = (day - now.weekday) % 7;
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysUntil,
        hour,
        minute,
      );

      // 오늘인데 이미 시간이 지났으면 7일 후로 스케줄링
      if (daysUntil == 0 && scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      try {
        await _notificationsPlugin.zonedSchedule(
          id: dailyReminderNotificationId + day,
          title: message.title,
          body: message.body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        debugPrint(
          '[Notification] 요일($day) $hour시 $minute분 독서 알림 스케줄 완료 (id: ${dailyReminderNotificationId + day})',
        );
      } catch (e) {
        debugPrint('[Notification] 요일($day) 스케줄링 오류: $e');
      }
    }
  }

  /// 앱 시작 시 또는 독서 데이터 변경 시 활성화된 알림 스케줄 자동 동기화/재등록
  Future<void> rescheduleIfEnabled({
    List<Book>? books,
    List<Note>? notes,
  }) async {
    if (!Hive.isBoxOpen(AppConstants.settingsBoxName)) return;
    final box = Hive.box(AppConstants.settingsBoxName);
    final isEnabled =
        box.get(AppConstants.notificationEnabledKey, defaultValue: false) as bool;

    if (!isEnabled) return;

    final hour =
        box.get(AppConstants.notificationHourKey, defaultValue: 21) as int;
    final minute =
        box.get(AppConstants.notificationMinuteKey, defaultValue: 30) as int;
    final rawDays = box.get(AppConstants.notificationDaysKey);

    List<int> days = [1, 2, 3, 4, 5, 6, 7];
    if (rawDays is List) {
      days = rawDays.map((e) => (e as num).toInt()).toList();
      if (days.isEmpty) days = [1, 2, 3, 4, 5, 6, 7];
    }

    // books가 전달되지 않은 경우 Hive에서 직접 가져옴
    List<Book>? targetBooks = books;
    if (targetBooks == null && Hive.isBoxOpen(AppConstants.bookBoxName)) {
      final booksBox = Hive.box<Book>(AppConstants.bookBoxName);
      targetBooks = booksBox.values.toList();
    }

    await scheduleReminder(
      hour: hour,
      minute: minute,
      days: days,
      books: targetBooks,
      notes: notes,
    );
  }

  /// 기존 메서드 호환성 유지 (매일 알림)
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    List<Book>? books,
    List<Note>? notes,
  }) async {
    await scheduleReminder(
      hour: hour,
      minute: minute,
      days: const [1, 2, 3, 4, 5, 6, 7],
      books: books,
      notes: notes,
    );
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
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
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

  /// 알림 취소 (기존 단일 ID 및 요일별 101~107 ID 모두 취소)
  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(id: dailyReminderNotificationId);
    for (int day = 1; day <= 7; day++) {
      await _notificationsPlugin.cancel(id: dailyReminderNotificationId + day);
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
