import 'package:flutter/material.dart';

/// 감성 문장 카드 그라디언트 및 텍스트/뱃지 색상 테마 모델
class QuoteCardTheme {
  final String name;
  final List<Color> gradientColors;
  final Color textColor;
  final Color subTextColor;
  final Color quoteIconColor;
  final Color quoteBadgeBg;
  final Color dividerColor;
  final Color? borderColor;

  const QuoteCardTheme({
    required this.name,
    required this.gradientColors,
    required this.textColor,
    required this.subTextColor,
    required this.quoteIconColor,
    required this.quoteBadgeBg,
    required this.dividerColor,
    this.borderColor,
  });
}

/// 12가지 프리미엄 감성 배경 테마 프리셋
final List<QuoteCardTheme> kQuoteCardThemes = [
  // 1. 미드나잇 인디고 (시그니처 다크)
  QuoteCardTheme(
    name: '미드나잇',
    gradientColors: [const Color(0xFF1E1B4B), const Color(0xFF312E81)],
    textColor: Colors.white,
    subTextColor: Colors.white70,
    quoteIconColor: const Color(0xFFFBBF24),
    quoteBadgeBg: Colors.white.withValues(alpha: 0.15),
    dividerColor: Colors.white.withValues(alpha: 0.15),
  ),
  // 2. 웜 페이퍼 (베이지 양장본 감성)
  QuoteCardTheme(
    name: '페이퍼',
    gradientColors: [const Color(0xFFFBF8F1), const Color(0xFFF2EBE0)],
    textColor: const Color(0xFF292524),
    subTextColor: const Color(0xFF78716C),
    quoteIconColor: const Color(0xFFD97706),
    quoteBadgeBg: const Color(0xFFE7DFD5),
    dividerColor: const Color(0xFFD6CEBF),
    borderColor: const Color(0xFFE0D7C9),
  ),
  // 3. 미니멀 화이트 (모던 클린)
  QuoteCardTheme(
    name: '미니멀',
    gradientColors: [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
    textColor: const Color(0xFF0F172A),
    subTextColor: const Color(0xFF64748B),
    quoteIconColor: const Color(0xFF4F46E5),
    quoteBadgeBg: const Color(0xFFEEF2FF),
    dividerColor: const Color(0xFFE2E8F0),
    borderColor: const Color(0xFFE2E8F0),
  ),
  // 4. 선셋 로즈 (따뜻한 노을)
  QuoteCardTheme(
    name: '선셋',
    gradientColors: [const Color(0xFF831843), const Color(0xFFBE185D)],
    textColor: Colors.white,
    subTextColor: Colors.white70,
    quoteIconColor: const Color(0xFFFDE047),
    quoteBadgeBg: Colors.white.withValues(alpha: 0.15),
    dividerColor: Colors.white.withValues(alpha: 0.18),
  ),
  // 5. 딥 포레스트 (차분한 세이지 그린)
  QuoteCardTheme(
    name: '포레스트',
    gradientColors: [const Color(0xFF064E3B), const Color(0xFF047857)],
    textColor: Colors.white,
    subTextColor: Colors.white70,
    quoteIconColor: const Color(0xFF6EE7B7),
    quoteBadgeBg: Colors.white.withValues(alpha: 0.15),
    dividerColor: Colors.white.withValues(alpha: 0.15),
  ),
  // 6. 다크 오닉스 (차콜 슬레이트)
  QuoteCardTheme(
    name: '다크',
    gradientColors: [const Color(0xFF0F172A), const Color(0xFF1E293B)],
    textColor: Colors.white,
    subTextColor: Colors.white60,
    quoteIconColor: const Color(0xFF38BDF8),
    quoteBadgeBg: Colors.white.withValues(alpha: 0.12),
    dividerColor: Colors.white.withValues(alpha: 0.12),
  ),
  // 7. 로얄 바이올렛 (감성 퍼플)
  QuoteCardTheme(
    name: '바이올렛',
    gradientColors: [const Color(0xFF4C1D95), const Color(0xFF7C3AED)],
    textColor: Colors.white,
    subTextColor: Colors.white70,
    quoteIconColor: const Color(0xFFFCD34D),
    quoteBadgeBg: Colors.white.withValues(alpha: 0.15),
    dividerColor: Colors.white.withValues(alpha: 0.15),
  ),
  // 8. 오션 브리즈 (청량한 바다)
  QuoteCardTheme(
    name: '오션',
    gradientColors: [const Color(0xFF0369A1), const Color(0xFF0EA5E9)],
    textColor: Colors.white,
    subTextColor: Colors.white70,
    quoteIconColor: const Color(0xFF7DD3FC),
    quoteBadgeBg: Colors.white.withValues(alpha: 0.15),
    dividerColor: Colors.white.withValues(alpha: 0.15),
  ),
  // 9. 블라썸 핑크 (사랑스러운 벚꽃)
  QuoteCardTheme(
    name: '블라썸',
    gradientColors: [const Color(0xFFFDF2F8), const Color(0xFFFCE7F3)],
    textColor: const Color(0xFF831843),
    subTextColor: const Color(0xFFBE185D),
    quoteIconColor: const Color(0xFFF43F5E),
    quoteBadgeBg: const Color(0xFFFBCFE8),
    dividerColor: const Color(0xFFF9A8D4),
    borderColor: const Color(0xFFFBCFE8),
  ),
  // 10. 말차 라떼 (따뜻한 그린)
  QuoteCardTheme(
    name: '말차',
    gradientColors: [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
    textColor: const Color(0xFF064E3B),
    subTextColor: const Color(0xFF047857),
    quoteIconColor: const Color(0xFF10B981),
    quoteBadgeBg: const Color(0xFFD1FAE5),
    dividerColor: const Color(0xFFA7F3D0),
    borderColor: const Color(0xFFD1FAE5),
  ),
  // 11. 딥 나이트 (신비로운 밤)
  QuoteCardTheme(
    name: '나이트',
    gradientColors: [const Color(0xFF2E1065), const Color(0xFF4C1D95)],
    textColor: Colors.white,
    subTextColor: Colors.white70,
    quoteIconColor: const Color(0xFFC084FC),
    quoteBadgeBg: Colors.white.withValues(alpha: 0.15),
    dividerColor: Colors.white.withValues(alpha: 0.15),
  ),
  // 12. 모카 브라운 (아늑한 커피)
  QuoteCardTheme(
    name: '모카',
    gradientColors: [const Color(0xFF451A03), const Color(0xFF78350F)],
    textColor: Colors.white,
    subTextColor: Colors.white70,
    quoteIconColor: const Color(0xFFFCD34D),
    quoteBadgeBg: Colors.white.withValues(alpha: 0.15),
    dividerColor: Colors.white.withValues(alpha: 0.15),
  ),
];
