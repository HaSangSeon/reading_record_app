import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'firebase_service.dart';

/// 네트워크 연결 상태 감지 및 오프라인 저장 시 사용자 알림을 전담하는 서비스
class NetworkSyncService {
  static final NetworkSyncService _instance = NetworkSyncService._internal();
  factory NetworkSyncService() => _instance;
  NetworkSyncService._internal();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool _pendingOnlineSync = false;
  bool _shouldNotifyOnSync = false;
  bool _syncing = false;

  // 오프라인 상태 알림의 잦은 중복 방지를 위한 디바운스
  DateTime? _lastOfflineNoticeTime;

  // 오프라인에서 온라인으로 전환 시 실행할 동기화 콜백
  Future<SyncResult> Function()? onBackOnline;

  /// 초기 동기화나 Firebase 초기화 실패 시 재시도 대상으로 표시
  void markPendingSync({bool notifyOnSuccess = false}) {
    _pendingOnlineSync = true;
    if (notifyOnSuccess) {
      _shouldNotifyOnSync = true;
    }
    if (_isOnline) {
      _scheduleRetry();
    }
  }

  /// 서비스 초기화 및 네트워크 상태 리스너 등록
  Future<void> init({Future<SyncResult> Function()? onBackOnlineCallback}) async {
    onBackOnline = onBackOnlineCallback;

    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _checkIsOnline(results);
    } catch (_) {
      _isOnline = false;
    }

    if (!_isOnline) {
      _pendingOnlineSync = true;
      _shouldNotifyOnSync = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final wasOnline = _isOnline;
      _isOnline = _checkIsOnline(results);

      if (!_isOnline) {
        _pendingOnlineSync = true;
        _shouldNotifyOnSync = true;
        _retryTimer?.cancel();
        return;
      }

      // 오프라인 -> 온라인으로 전환되었거나 이전 동기화가 미완료된 경우 실행
      if (!wasOnline || _pendingOnlineSync) {
        if (!wasOnline) {
          _pendingOnlineSync = true;
          _shouldNotifyOnSync = true;
        }
        await _attemptOnlineSync();
      }
    });
  }

  Future<void> _attemptOnlineSync() async {
    if (_syncing || !_isOnline || onBackOnline == null) return;
    _syncing = true;
    _retryTimer?.cancel();
    try {
      final result = await onBackOnline?.call();
      if (_isOnline && result?.success == true) {
        final shouldNotify = _shouldNotifyOnSync;
        _pendingOnlineSync = false;
        _shouldNotifyOnSync = false;
        if (shouldNotify) {
          showOnlineSyncedNotice();
        }
      } else if (_isOnline) {
        _pendingOnlineSync = true;
        _scheduleRetry();
      }
    } catch (_) {
      if (_isOnline) {
        _pendingOnlineSync = true;
        _scheduleRetry();
      }
    } finally {
      _syncing = false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (_isOnline && _pendingOnlineSync) {
        unawaited(_attemptOnlineSync());
      }
    });
  }

  bool _checkIsOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// 오프라인 상태에서 데이터가 저장되었을 때 사용자에게 알림 팝업/스낵바 노출
  void notifyOfflineSaved({String itemType = '기록'}) {
    _pendingOnlineSync = true;
    _shouldNotifyOnSync = true;
    final now = DateTime.now();
    // 3초 이내 중복 알림 방지
    if (_lastOfflineNoticeTime != null &&
        now.difference(_lastOfflineNoticeTime!).inSeconds < 3) {
      return;
    }
    _lastOfflineNoticeTime = now;

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D3748),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오프라인 상태입니다',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '이 기기에 저장했습니다. 인터넷이 연결되면 동기화를 다시 시도합니다.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 온라인 복귀 후 클라우드 동기화 완료 알림
  void showOnlineSyncedNotice() {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_done_rounded,
                color: Colors.lightBlueAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '인터넷이 연결되어 클라우드와 자동 동기화되었습니다. ☁️',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void dispose() {
    _retryTimer?.cancel();
    _subscription?.cancel();
  }
}
