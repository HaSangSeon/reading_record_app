import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// 네트워크 연결 상태 감지 및 오프라인 저장 시 사용자 알림을 전담하는 서비스
class NetworkSyncService {
  static final NetworkSyncService _instance = NetworkSyncService._internal();
  factory NetworkSyncService() => _instance;
  NetworkSyncService._internal();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // 오프라인 상태 알림의 잦은 중복 방지를 위한 디바운스
  DateTime? _lastOfflineNoticeTime;

  // 오프라인에서 온라인으로 전환 시 실행할 동기화 콜백
  VoidCallback? onBackOnline;

  /// 서비스 초기화 및 네트워크 상태 리스너 등록
  Future<void> init({VoidCallback? onBackOnlineCallback}) async {
    onBackOnline = onBackOnlineCallback;

    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _checkIsOnline(results);
    } catch (_) {
      _isOnline = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = _checkIsOnline(results);

      // 오프라인 -> 온라인으로 전환 시 동기화 콜백 실행
      if (!wasOnline && _isOnline) {
        showOnlineSyncedNotice();
        onBackOnline?.call();
      }
    });
  }

  bool _checkIsOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// 오프라인 상태에서 데이터가 저장되었을 때 사용자에게 알림 팝업/스낵바 노출
  void notifyOfflineSaved({String itemType = '기록'}) {
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
                    '기기에 안전하게 저장되었으며, 네트워크 연결 시 클라우드에 자동 백업됩니다.',
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
    _subscription?.cancel();
  }
}
