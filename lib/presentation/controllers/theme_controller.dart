import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/hive_service.dart';
import '../../providers/repository_providers.dart';

/// 테마 모드 상태 관리 컨트롤러
class ThemeController extends StateNotifier<ThemeMode> {
  final HiveService _hiveService;

  ThemeController(this._hiveService) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    try {
      final saved = _hiveService.settingsBox.get(
        AppConstants.themeModeKey,
        defaultValue: 'system',
      );
      if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String modeString = 'system';
    if (mode == ThemeMode.light) {
      modeString = 'light';
    } else if (mode == ThemeMode.dark) {
      modeString = 'dark';
    }

    try {
      await _hiveService.settingsBox.put(AppConstants.themeModeKey, modeString);
    } catch (_) {}
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    if (state == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      // system mode -> toggle opposite to current brightness
      if (currentBrightness == Brightness.dark) {
        await setThemeMode(ThemeMode.light);
      } else {
        await setThemeMode(ThemeMode.dark);
      }
    }
  }
}

/// 테마 모드 프로바이더
final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
      final hiveService = ref.watch(hiveServiceProvider);
      return ThemeController(hiveService);
    });
