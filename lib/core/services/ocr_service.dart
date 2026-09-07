import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  /// 이미지 파일에서 한글/영문 텍스트를 고정밀 OCR로 추출합니다.
  Future<String> recognizeTextFromImage(File imageFile) async {
    // 한국어 인식에 최적화된 스크립트 지정
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      final rawText = recognizedText.text;
      return cleanBookText(rawText);
    } finally {
      // 리소스 해제
      await textRecognizer.close();
    }
  }

  /// 책 페이지 텍스트 특성에 맞게 줄바꿈 및 불필요한 공백을 정돈합니다.
  String cleanBookText(String rawText) {
    if (rawText.trim().isEmpty) return '';

    final lines = rawText.split('\n');
    final buffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (buffer.isNotEmpty) {
        final lastChar = buffer.toString().trimRight().characters.last;
        // 이전 줄이 마침표, 물음표, 느낌표, 따옴표로 끝났으면 줄바꿈 유지
        if (['.', '?', '!', '"', '”', '’'].contains(lastChar)) {
          buffer.write('\n');
        } else {
          // 문장 중간의 줄바꿈인 경우 띄어쓰기로 부드럽게 연결
          buffer.write(' ');
        }
      }

      buffer.write(line);
    }

    return buffer.toString().trim();
  }
}
