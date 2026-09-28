import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:url_launcher/url_launcher.dart';

class KakaoShareService {
  static final KakaoShareService _instance = KakaoShareService._internal();

  factory KakaoShareService() {
    return _instance;
  }

  KakaoShareService._internal();

  /// 기기에서 생성된 이미지 파일을 카카오 서버에 업로드 후 공유합니다.
  Future<void> shareLocalImageCard({
    required File imageFile,
    required String text,
  }) async {
    bool isKakaoTalkSharingAvailable =
        await ShareClient.instance.isKakaoTalkSharingAvailable();

    try {
      // 1. 카카오 서버로 이미지 업로드 (카카오톡 공유를 위해 필요)
      final ImageUploadResult imageUploadResult =
          await ShareClient.instance.uploadImage(byteData: imageFile.readAsBytesSync());
      final String imageUrl = imageUploadResult.infos.original.url;

      // 2. 카카오톡 공유 템플릿 구성
      final String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.hasangseon.reading_record_app';
      final Link commonLink = Link(
        webUrl: Uri.parse(playStoreUrl),
        mobileWebUrl: Uri.parse(playStoreUrl),
        androidExecutionParams: {'action': 'view'},
      );

      // 이미지 클릭 시 원본 이미지를 웹/모바일웹으로 열어 저장할 수 있도록 설정
      final Link imageLink = Link(
        webUrl: Uri.parse(imageUrl),
        mobileWebUrl: Uri.parse(imageUrl),
      );

      final FeedTemplate defaultFeed = FeedTemplate(
        content: Content(
          title: '', // 텍스트 없이 이미지만 강조
          imageUrl: Uri.parse(imageUrl),
          link: imageLink, // 이미지는 이미지 링크로 연결
        ),
        buttons: [
          Button(
            title: '나도 독서카드 만들기', // 다정하고 친근한 문구로 변경
            link: commonLink, // 버튼은 앱 실행 또는 플레이스토어로 연결
          ),
        ],
      );

      // 3. 공유 실행
      if (isKakaoTalkSharingAvailable) {
        await ShareClient.instance.shareDefault(template: defaultFeed);
      } else {
        Uri shareUrl = await WebSharerClient.instance
            .makeDefaultUrl(template: defaultFeed);
        await launchUrl(shareUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('카카오톡 공유 실패: $e');
      rethrow;
    }
  }
}


