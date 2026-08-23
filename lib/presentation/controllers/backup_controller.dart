import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/hive_service.dart';
import '../../data/services/backup_service.dart';
import '../../providers/repository_providers.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final hive = ref.watch(hiveServiceProvider);
  return BackupService(hiveService: hive);
});

final backupControllerProvider =
    StateNotifierProvider<BackupController, AsyncValue<void>>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  final hiveService = ref.watch(hiveServiceProvider);
  return BackupController(backupService, hiveService);
});

class BackupController extends StateNotifier<AsyncValue<void>> {
  final BackupService _backupService;
  final HiveService _hiveService;

  BackupController(this._backupService, this._hiveService)
      : super(const AsyncValue.data(null));

  Future<String?> exportData() async {
    state = const AsyncValue.loading();
    try {
      final json = await _backupService.exportToJson();
      state = const AsyncValue.data(null);
      return json;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<({bool success, int books, int notes, String? error})> importData(
    String jsonString, {
    bool overwrite = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _backupService.importFromJson(
        jsonString,
        overwrite: overwrite,
      );
      state = const AsyncValue.data(null);
      return (
        success: true,
        books: result.booksRestored,
        notes: result.notesRestored,
        error: null
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return (
        success: false,
        books: 0,
        notes: 0,
        error: e.toString().replaceFirst('Exception: ', '').replaceFirst('FormatException: ', '')
      );
    }
  }

  Future<bool> clearAllData() async {
    state = const AsyncValue.loading();
    try {
      await _hiveService.clearAllData();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
