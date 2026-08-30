import 'package:flutter/material.dart';

class AppTheme {
  // 브랜드 컬러 팔레트 (신뢰감과 깊이감을 주는 프리미엄 딥 인디고 & 바이올렛)
  static const Color primaryColor = Color(0xFF4338CA); // Indigo 700
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF312E81); // Indigo 900
  static const Color secondaryColor = Color(0xFF0284C7); // Sky 600
  static const Color accentColor = Color(0xFFD97706); // Amber 600 (별점 및 강조)
  static const Color successColor = Color(0xFF059669); // Emerald 600 (완독 뱃지)

  // 라이트 모드 중립 컬러 (따뜻하고 깨끗한 감성 라벤더 서재 톤)
  static const Color backgroundColor = Color(0xFFF6F4FA);
  static const Color surfaceColor = Colors.white;
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color headerBgLight = Color(
    0xFFECE8F8,
  ); // 우아하고 고급스럽게 감도는 프리미엄 소프트 라벤더 바이올렛 틴트
  static const Color headerBorderLight = Color(
    0xFFDCD5F0,
  ); // 은은하고 깔끔한 라벤더 바이올렛 하단 보더
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textLight = Color(0xFF94A3B8); // Slate 400
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200

  // 다크 모드 중립 컬러 (깊이감 있는 럭셔리 미드나잇 오닉스 & 바이올렛 슬레이트)
  static const Color darkBackground = Color(
    0xFF0C0E17,
  ); // Midnight Charcoal & Violet Slate
  static const Color darkSurface = Color(0xFF131726); // Deep Slate
  static const Color darkSurfaceCard = Color(0xFF182234); // Elevated Slate Card
  static const Color headerBgDark = Color(
    0xFF181528,
  ); // 깊이감 있고 럭셔리한 미드나잇 바이올렛 헤더
  static const Color headerBorderDark = Color(0xFF2E2749); // 세련된 바이올렛 다크 보더
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextLight = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF243048);

  // 프리미엄 오로라 바이올렛 그라데이션 팔레트
  static const List<Color> headerGradientLight = [
    Color(0xFFFBF9FF), // 상단 맑은 화이트 라벤더
    Color(0xFFEFE8F9), // 중간 소프트 라벤더
    Color(0xFFE2D7F5), // 하단 감성 인디고 바이올렛
  ];

  static const List<Color> headerGradientDark = [
    Color(0xFF261D3D), // 상단 로얄 미드나잇 바이올렛
    Color(0xFF1A142D), // 중간 딥 바이올렛
    Color(0xFF130E22), // 하단 오닉스 바이올렛
  ];

  /// 모든 페이지 상단 AppBar용 프리미엄 그라데이션 flexibleSpace 빌더
  static Widget buildAppBarFlexibleSpace(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? headerGradientDark : headerGradientLight,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // 상단 은은한 엠보싱 하이라이트 광원 라인
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1.2,
            child: Container(
              color: isDark
                  ? const Color(0xFF818CF8).withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// 라이트 테마 정의
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBgLight,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: headerBorderLight, width: 1.0)),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// 다크 테마 정의
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        primary: primaryLight,
        secondary: secondaryColor,
        surface: darkSurface,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBgDark,
        foregroundColor: darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: headerBorderDark, width: 1.0)),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111724),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        labelStyle: const TextStyle(
          color: darkTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: darkTextLight, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: darkBackground,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
