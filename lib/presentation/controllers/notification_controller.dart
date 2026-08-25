import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';

class NotificationSettingsState {
  final bool isEnabled;
  final TimeOfDay time;

  const NotificationSettingsState({
    required this.isEnabled,
    required this.time,
  });

  NotificationSettingsState copyWith({
    bool? isEnabled,
    TimeOfDay? time,
  }) {
    return NotificationSettingsState(
      isEnabled: isEnabled ?? this.isEnabled,
      time: time ?? this.time,
    );
  }
}

class NotificationController extends StateNotifier<NotificationSettingsState> {
  final NotificationService _notificationService = NotificationService();

  NotificationController()
      : super(const NotificationSettingsState(
          isEnabled: false,
          time: TimeOfDay(hour: 21, minute: 30),
        )) {
    _loadSettings();
  }

  void _loadSettings() {
    if (!Hive.isBoxOpen(AppConstants.settingsBoxName)) return;
    final box = Hive.box(AppConstants.settingsBoxName);

    final isEnabled =
        box.get(AppConstants.notificationEnabledKey, defaultValue: false) as bool;
    final hour =
        box.get(AppConstants.notificationHourKey, defaultValue: 21) as int;
    final minute =
        box.get(AppConstants.notificationMinuteKey, defaultValue: 30) as int;

    state = NotificationSettingsState(
      isEnabled: isEnabled,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  /// 알림 활성화/비활성화 토글
  Future<bool> toggleNotification(
    bool enabled, {
    List<Book>? books,
    List<Note>? notes,
  }) async {
    if (enabled) {
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        return false;
      }

      await _notificationService.scheduleDailyReminder(
        hour: state.time.hour,
        minute: state.time.minute,
        books: books,
        notes: notes,
      );
    } else {
      await _notificationService.cancelDailyReminder();
    }

    state = state.copyWith(isEnabled: enabled);

    if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
      final box = Hive.box(AppConstants.settingsBoxName);
      await box.put(AppConstants.notificationEnabledKey, enabled);
    }

    return true;
  }

  /// 알림 시각 설정 (시, 분)
  Future<void> setTime(
    TimeOfDay newTime, {
    List<Book>? books,
    List<Note>? notes,
  }) async {
    state = state.copyWith(time: newTime);

    if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
      final box = Hive.box(AppConstants.settingsBoxName);
      await box.put(AppConstants.notificationHourKey, newTime.hour);
      await box.put(AppConstants.notificationMinuteKey, newTime.minute);
    }

    if (state.isEnabled) {
      await _notificationService.scheduleDailyReminder(
        hour: newTime.hour,
        minute: newTime.minute,
        books: books,
        notes: notes,
      );
    }
  }

  /// 즉시 테스트 알림 전송
  Future<void> sendTestNotification({
    List<Book>? books,
    List<Note>? notes,
  }) async {
    await _notificationService.showInstantTestNotification(
      books: books,
      notes: notes,
    );
  }
}

final notificationControllerProvider = StateNotifierProvider<
    NotificationController, NotificationSettingsState>((ref) {
  return NotificationController();
});
