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
  final List<int> selectedDays; // 1=월, 2=화, 3=수, 4=목, 5=금, 6=토, 7=일

  const NotificationSettingsState({
    required this.isEnabled,
    required this.time,
    required this.selectedDays,
  });

  NotificationSettingsState copyWith({
    bool? isEnabled,
    TimeOfDay? time,
    List<int>? selectedDays,
  }) {
    return NotificationSettingsState(
      isEnabled: isEnabled ?? this.isEnabled,
      time: time ?? this.time,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }

  /// 요일 표시 요약 텍스트
  String get daysSummary {
    if (selectedDays.isEmpty) return '선택된 요일 없음';
    if (selectedDays.length == 7) return '매일';

    final sorted = List<int>.from(selectedDays)..sort();
    if (sorted.length == 5 &&
        sorted[0] == 1 &&
        sorted[1] == 2 &&
        sorted[2] == 3 &&
        sorted[3] == 4 &&
        sorted[4] == 5) {
      return '평일 (월~금)';
    }
    if (sorted.length == 2 && sorted[0] == 6 && sorted[1] == 7) {
      return '주말 (토, 일)';
    }

    const dayLabels = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    return sorted.map((d) => dayLabels[d] ?? '').join(', ');
  }
}

class NotificationController extends StateNotifier<NotificationSettingsState> {
  final NotificationService _notificationService = NotificationService();

  NotificationController()
    : super(
        const NotificationSettingsState(
          isEnabled: false,
          time: TimeOfDay(hour: 21, minute: 30),
          selectedDays: [1, 2, 3, 4, 5, 6, 7],
        ),
      ) {
    _loadSettings();
  }

  void _loadSettings() {
    if (!Hive.isBoxOpen(AppConstants.settingsBoxName)) return;
    final box = Hive.box(AppConstants.settingsBoxName);

    final isEnabled =
        box.get(AppConstants.notificationEnabledKey, defaultValue: false)
            as bool;
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

    state = NotificationSettingsState(
      isEnabled: isEnabled,
      time: TimeOfDay(hour: hour, minute: minute),
      selectedDays: days,
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

      await _notificationService.scheduleReminder(
        hour: state.time.hour,
        minute: state.time.minute,
        days: state.selectedDays,
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
      await _notificationService.scheduleReminder(
        hour: newTime.hour,
        minute: newTime.minute,
        days: state.selectedDays,
        books: books,
        notes: notes,
      );
    }
  }

  /// 특정 요일 토글 (1=월~7=일)
  Future<void> toggleDay(
    int day, {
    List<Book>? books,
    List<Note>? notes,
  }) async {
    final currentDays = List<int>.from(state.selectedDays);
    if (currentDays.contains(day)) {
      // 최소 1개 요일은 유지하도록 처리
      if (currentDays.length > 1) {
        currentDays.remove(day);
      }
    } else {
      currentDays.add(day);
    }
    currentDays.sort();

    await setDays(currentDays, books: books, notes: notes);
  }

  /// 요일 일괄 변경
  Future<void> setDays(
    List<int> days, {
    List<Book>? books,
    List<Note>? notes,
  }) async {
    final sortedDays = List<int>.from(days)..sort();
    state = state.copyWith(selectedDays: sortedDays);

    if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
      final box = Hive.box(AppConstants.settingsBoxName);
      await box.put(AppConstants.notificationDaysKey, sortedDays);
    }

    if (state.isEnabled) {
      await _notificationService.scheduleReminder(
        hour: state.time.hour,
        minute: state.time.minute,
        days: sortedDays,
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

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationSettingsState>((
      ref,
    ) {
      return NotificationController();
    });
