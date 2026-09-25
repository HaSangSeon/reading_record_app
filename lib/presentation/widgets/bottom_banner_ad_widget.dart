import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ads/admob_service.dart';

/// 스크린샷 캡쳐용 배너 숨김 플래그 (false: 정상 광고 표시)
const bool kHideBannerAdForScreenshot = false;

class BottomBannerAdWidget extends StatefulWidget {
  const BottomBannerAdWidget({super.key});

  @override
  State<BottomBannerAdWidget> createState() => _BottomBannerAdWidgetState();
}

class _BottomBannerAdWidgetState extends State<BottomBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  AdSize? _adSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kHideBannerAdForScreenshot) {
      _loadAdaptiveBannerAd();
    }
  }

  Future<void> _loadAdaptiveBannerAd() async {
    if (kHideBannerAdForScreenshot) return;
    if (_isAdLoaded && _bannerAd != null) return;

    final adUnitId = AdMobService.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    // 기기 화면 가로 폭 100%를 가져와서 꽉 차는 표준 적응형 배너 사이즈 생성
    final width = MediaQuery.of(context).size.width.truncate();

    // ignore: deprecated_member_use
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width) ??
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    if (size == null) return;

    _adSize = size;
    _bannerAd?.dispose();

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size, // 기기 가로 100% 꽉 채우는 AdSize
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          final banner = ad as BannerAd;
          final platformSize = await banner.getPlatformAdSize();
          debugPrint(
            '[BottomBannerAdWidget] 배너 로드 성공! 요청 size: ${_adSize?.width}x${_adSize?.height}, 실제 size: ${platformSize?.width}x${platformSize?.height}',
          );
          if (mounted) {
            setState(() {
              if (platformSize != null) {
                _adSize = platformSize;
              }
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '[BottomBannerAdWidget] 적응형 배너 로드 실패: ${error.message} (code: ${error.code})',
          );
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kHideBannerAdForScreenshot || !_isAdLoaded || _bannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: _adSize!.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E242B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C353F) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
      ),
      child: SizedBox(
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
