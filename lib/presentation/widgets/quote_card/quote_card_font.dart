import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 감성 문장 카드 서체 모델
class QuoteCardFont {
  final String name;
  final String category;
  final TextStyle Function({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) fontBuilder;

  const QuoteCardFont({
    required this.name,
    required this.category,
    required this.fontBuilder,
  });
}

/// 13가지 프리미엄 감성 한글 서체 프리셋
final List<QuoteCardFont> kQuoteCardFonts = [
  QuoteCardFont(
    name: '나눔명조',
    category: '클래식 감성',
    fontBuilder: GoogleFonts.nanumMyeongjo,
  ),
  QuoteCardFont(
    name: '고운바탕',
    category: '단아한 수필',
    fontBuilder: GoogleFonts.gowunBatang,
  ),
  QuoteCardFont(
    name: '송명체',
    category: '유려한 붓선',
    fontBuilder: GoogleFonts.songMyung,
  ),
  QuoteCardFont(
    name: '고운돋움',
    category: '깔끔한 감성',
    fontBuilder: GoogleFonts.gowunDodum,
  ),
  QuoteCardFont(
    name: '나눔손글씨',
    category: '따뜻한 펜글씨',
    fontBuilder: GoogleFonts.nanumPenScript,
  ),
  QuoteCardFont(
    name: '감자꽃',
    category: '아기자기',
    fontBuilder: GoogleFonts.gamjaFlower,
  ),
  QuoteCardFont(
    name: '나눔고딕',
    category: '모던 고딕',
    fontBuilder: GoogleFonts.nanumGothic,
  ),
  QuoteCardFont(
    name: '도현체',
    category: '강렬한 볼드',
    fontBuilder: GoogleFonts.doHyeon,
  ),
  QuoteCardFont(
    name: '주아체',
    category: '동글동글',
    fontBuilder: GoogleFonts.jua,
  ),
  QuoteCardFont(
    name: '해바라기',
    category: '정감가는',
    fontBuilder: GoogleFonts.sunflower,
  ),
  QuoteCardFont(
    name: '연성체',
    category: '붓글씨',
    fontBuilder: GoogleFonts.yeonSung,
  ),
  QuoteCardFont(
    name: '싱글데이',
    category: '발랄한',
    fontBuilder: GoogleFonts.singleDay,
  ),
  QuoteCardFont(
    name: '검은고딕',
    category: '타이틀',
    fontBuilder: GoogleFonts.blackHanSans,
  ),
];
