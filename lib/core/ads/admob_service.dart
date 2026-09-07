import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;
  int _actionCounter = 0;

  /// Google AdMob SDK 초기화
  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      debugPrint('[AdMobService] Google Mobile Ads 초기화 완료');
      loadInterstitialAd(); // 전면 광고 사전 로드
    } catch (e) {
      debugPrint('[AdMobService] Google Mobile Ads 초기화 실패: $e');
    }
  }

  /// 하단 배너 광고 단위 ID
  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // Android 테스트 배너 ID
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // iOS 테스트 배너 ID
      }
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-3702899361747571/2586535773'; // Android 실제 배너 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  /// 전면 광고 단위 ID
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712'; // Android 테스트 전면광고 ID
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910'; // iOS 테스트 전면광고 ID
      }
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-3702899361747571/9211653871'; // Android 실제 전면광고 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  /// 전면 광고 로드 및 캐싱
  void loadInterstitialAd({VoidCallback? onLoaded}) {
    if (_isInterstitialAdLoading) return;
    if (_interstitialAd != null) {
      onLoaded?.call();
      return;
    }
    _isInterstitialAdLoading = true;

    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) {
      _isInterstitialAdLoading = false;
      return;
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMobService] 전면 광고 로드 성공');
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  loadInterstitialAd(); // 닫힌 후 다음 광고 사전 로드
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  debugPrint('[AdMobService] 전면 광고 노출 실패: ${error.message}');
                  ad.dispose();
                  _interstitialAd = null;
                  loadInterstitialAd();
                },
              );
          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobService] 전면 광고 로드 실패: ${error.message}');
          _interstitialAd = null;
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  DateTime? _lastInterstitialShownTime;

  /// 사용자의 특정 액션 카운터 증가 및 전면 광고 노출 (기본 4회 액션당 1회 노출, 최소 3분 쿨타임)
  void triggerActionInterstitial({
    int interval = 4,
    Duration coolDown = const Duration(minutes: 3),
  }) {
    _actionCounter++;
    debugPrint('[AdMobService] Action Counter: $_actionCounter / $interval');

    if (_actionCounter >= interval) {
      final now = DateTime.now();
      final hasElapsedCoolDown = _lastInterstitialShownTime == null ||
          now.difference(_lastInterstitialShownTime!) >= coolDown;

      if (hasElapsedCoolDown) {
        debugPrint('[AdMobService] 카운트 및 쿨타임 충족 -> 전면 광고 노출 시도');
        _actionCounter = 0;
        _lastInterstitialShownTime = now;
        showInterstitialAd();
      } else {
        final remainingSeconds =
            coolDown.inSeconds - now.difference(_lastInterstitialShownTime!).inSeconds;
        debugPrint(
          '[AdMobService] 쿨타임 적용 중 ($remainingSeconds초 남음) -> 유저 경험 보호를 위해 광고 노출 유예',
        );
        // 카운터가 interval 이상으로 유지되도록 하여 쿨타임이 지난 후 다음 액션 시 바로 노출되도록 함
        _actionCounter = interval;
      }
    }
  }

  /// 전면 광고 즉시 표시
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      debugPrint('[AdMobService] 전면 광고 표시 실행');
      _lastInterstitialShownTime = DateTime.now();
      _interstitialAd!.show();
    } else {
      debugPrint('[AdMobService] 전면 광고 캐시 없음 -> 로드 후 즉시 표시 시도');
      loadInterstitialAd(
        onLoaded: () {
          _lastInterstitialShownTime = DateTime.now();
          _interstitialAd?.show();
        },
      );
    }
  }
}
