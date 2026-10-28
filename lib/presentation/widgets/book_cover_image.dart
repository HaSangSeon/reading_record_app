import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// 웹 URL(HTTP/HTTPS), 초경량 Base64 클라우드 동기화 이미지(data:image/...), 로컬 파일 경로를 통합 지원하는 위젯
class BookCoverImage extends StatelessWidget {
  final String? coverUrl;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const BookCoverImage({
    super.key,
    required this.coverUrl,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final url = coverUrl?.trim();
    if (url == null || url.isEmpty) {
      return errorBuilder != null
          ? errorBuilder!(context, 'No cover', null)
          : const SizedBox();
    }

    // 1. Base64 초경량 클라우드 동기화 이미지 (스마트폰 ↔ 태블릿 다중 기기 실시간 공유)
    if (url.startsWith('data:image/') || url.startsWith('data:')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Str =
            commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      } catch (e, st) {
        if (errorBuilder != null) {
          return errorBuilder!(context, e, st);
        }
        return const SizedBox();
      }
    }

    // 2. 인터넷 웹 URL (카카오/구글 검색 도서)
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    // 3. 로컬 파일 경로 (하위 호환성)
    try {
      final file = File(url);
      return Image.file(
        file,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    } catch (e, st) {
      if (errorBuilder != null) {
        return errorBuilder!(context, e, st);
      }
      return const SizedBox();
    }
  }
}

