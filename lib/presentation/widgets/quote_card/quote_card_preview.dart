import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/book_model.dart';
import 'quote_card_font.dart';
import 'quote_card_theme.dart';

/// 1:1 비율의 렌더링 및 캡처 전용 감성 문장 카드 캔버스 위젯
class QuoteCardPreview extends StatelessWidget {
  final GlobalKey cardKey;
  final Book book;
  final String dateStr;
  final int pageNumber;
  final String displayMainText;
  final String? displaySubMemo;
  final QuoteCardTheme theme;
  final QuoteCardFont font;
  final double fontSizeScale;
  final bool isCapturing;
  final bool isUsingCustomPhoto;
  final File? customImageFile;
  final bool isDarkTextColor;
  final double imageDimOpacity;

  const QuoteCardPreview({
    super.key,
    required this.cardKey,
    required this.book,
    required this.dateStr,
    required this.pageNumber,
    required this.displayMainText,
    this.displaySubMemo,
    required this.theme,
    required this.font,
    required this.fontSizeScale,
    required this.isCapturing,
    required this.isUsingCustomPhoto,
    this.customImageFile,
    required this.isDarkTextColor,
    required this.imageDimOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDarkText = isUsingCustomPhoto && isDarkTextColor;

    final Color effectiveTextColor = isUsingCustomPhoto
        ? (isDarkText ? const Color(0xFF0F172A) : Colors.white)
        : theme.textColor;
    final Color effectiveSubTextColor = isUsingCustomPhoto
        ? (isDarkText
            ? const Color(0xFF475569)
            : Colors.white.withValues(alpha: 0.88))
        : theme.subTextColor;
    final Color effectiveQuoteIconColor = isUsingCustomPhoto
        ? (isDarkText ? const Color(0xFFD97706) : const Color(0xFFFDE047))
        : theme.quoteIconColor;
    final Color effectiveQuoteBadgeBg = isUsingCustomPhoto
        ? (isDarkText
            ? Colors.black.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.35))
        : theme.quoteBadgeBg;
    final Color effectiveDividerColor = isUsingCustomPhoto
        ? (isDarkText
            ? Colors.black.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.25))
        : theme.dividerColor;
    final Color? effectiveBorderColor = isUsingCustomPhoto
        ? (isDarkText
            ? Colors.black.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.2))
        : theme.borderColor;

    final isQuoteOnly = displaySubMemo == null;
    final double mainFontSize = (font.name == '나눔손글씨'
            ? (isQuoteOnly ? 23.0 : 19.5)
            : (isQuoteOnly ? 18.0 : 16.0)) *
        fontSizeScale;
    final double subFontSize =
        (font.name == '나눔손글씨' ? 15.0 : 12.5) * fontSizeScale;

    return Center(
      child: RepaintBoundary(
        key: cardKey,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  isCapturing ? BorderRadius.zero : BorderRadius.circular(24),
              boxShadow: isCapturing
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.12,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius:
                  isCapturing ? BorderRadius.zero : BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: effectiveBorderColor ?? Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. 배경 레이어 (사진 또는 테마 그라디언트)
                    if (isUsingCustomPhoto && customImageFile != null) ...[
                      Image.file(
                        customImageFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white54,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      // 상하 비네팅 + 조절 가능한 딤(어둡기/화이트 톤) 오버레이
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isDarkText
                                ? [
                                    Colors.white.withValues(
                                      alpha: (imageDimOpacity + 0.10)
                                          .clamp(0.0, 1.0),
                                    ),
                                    Colors.white.withValues(
                                      alpha: imageDimOpacity,
                                    ),
                                    Colors.white.withValues(
                                      alpha: (imageDimOpacity + 0.15)
                                          .clamp(0.0, 1.0),
                                    ),
                                  ]
                                : [
                                    Colors.black.withValues(
                                      alpha: (imageDimOpacity + 0.12)
                                          .clamp(0.0, 1.0),
                                    ),
                                    Colors.black.withValues(
                                      alpha: imageDimOpacity,
                                    ),
                                    Colors.black.withValues(
                                      alpha: (imageDimOpacity + 0.18)
                                          .clamp(0.0, 1.0),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: theme.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ],

                    // 2. 카드 컨텐츠 레이어
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 상단 헤더: 따옴표 + 워터마크
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: effectiveQuoteBadgeBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.format_quote_rounded,
                                  color: effectiveQuoteIconColor,
                                  size: 22,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    color: effectiveSubTextColor,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '독서한줄',
                                    style: TextStyle(
                                      color: effectiveSubTextColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // 중앙 문장 및 감상 메모 (선택된 서체 실시간 적용)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '“$displayMainText”',
                                      style: font.fontBuilder(
                                        color: effectiveTextColor,
                                        fontSize: mainFontSize,
                                        height: isQuoteOnly ? 1.75 : 1.6,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (displaySubMemo != null) ...[
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 1.2,
                                            color: effectiveSubTextColor
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '생각 메모',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                              color: effectiveSubTextColor
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        displaySubMemo!,
                                        style: font.fontBuilder(
                                          color: effectiveSubTextColor,
                                          fontSize: subFontSize,
                                          height: 1.55,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 하단 도서 정보 및 날짜 / 워터마크
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 1,
                                color: effectiveDividerColor,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: effectiveTextColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${book.author}${pageNumber > 0 ? ' · p.$pageNumber' : ''}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: effectiveSubTextColor,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      color: effectiveSubTextColor
                                          .withValues(alpha: 0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
