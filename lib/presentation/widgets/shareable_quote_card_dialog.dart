import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/ads/admob_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';

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
  })
  fontBuilder;

  const QuoteCardFont({
    required this.name,
    required this.category,
    required this.fontBuilder,
  });
}

class ShareableQuoteCardDialog extends StatefulWidget {
  final Book book;
  final Note note;

  const ShareableQuoteCardDialog({
    super.key,
    required this.book,
    required this.note,
  });

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required Note note,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareableQuoteCardDialog(book: book, note: note),
    );
  }

  @override
  State<ShareableQuoteCardDialog> createState() =>
      _ShareableQuoteCardDialogState();
}

class _ShareableQuoteCardDialogState extends State<ShareableQuoteCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;
  int _selectedThemeIndex = 0;
  int _selectedFontIndex = 0;
  bool _includeMemo = true; // 구절만 vs 구절+메모 토글 상태

  bool get _hasQuotation => widget.note.quotation.trim().isNotEmpty;
  bool get _hasMemo => widget.note.content.trim().isNotEmpty;
  bool get _canToggleMemo => _hasQuotation && _hasMemo;

  // 8가지 프리미엄 감성 한글 서체 프리셋
  final List<QuoteCardFont> _fonts = [
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
  ];

  final List<QuoteCardTheme> _themes = [
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
  ];

  String get _displayMainText {
    if (widget.note.quotation.trim().isNotEmpty) {
      return widget.note.quotation.trim();
    }
    if (widget.note.content.trim().isNotEmpty) {
      return widget.note.content.trim();
    }
    return '남겨진 기록이 없습니다.';
  }

  String? get _displaySubMemo {
    if (_canToggleMemo && !_includeMemo) {
      return null;
    }
    if (widget.note.quotation.trim().isNotEmpty &&
        widget.note.content.trim().isNotEmpty) {
      return widget.note.content.trim();
    }
    return null;
  }

  Future<void> _captureAndShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/독서한줄_문장_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(file.path, mimeType: 'image/png');
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=com.hasangseon.reading_record_app';

      final shareText = StringBuffer()
        ..writeln('“$_displayMainText”');

      if (_displaySubMemo != null) {
        shareText
          ..writeln()
          ..writeln('💭 나의 생각: $_displaySubMemo');
      }

      shareText
        ..writeln('- 《${widget.book.title}》 (${widget.book.author})')
        ..writeln()
        ..writeln('✨ 나만의 인생 문장을 기록하고 감성 카드로 공유해보세요.')
        ..write('📱 독서한줄 앱 다운로드: $playStoreUrl');

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: '독서한줄 - ${widget.book.title}',
          text: shareText.toString(),
        ),
      );

      // 소셜 카드 공유 완료 시 통합 액션 카운터 증가 (기본 4회 완료 시 1회 노출, 3분 쿨타임)
      AdMobService().triggerActionInterstitial();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 공유 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final book = widget.book;
    final note = widget.note;
    final dateStr = DateFormat('yyyy.MM.dd').format(note.createdAt);
    final currentTheme = _themes[_selectedThemeIndex];
    final currentFont = _fonts[_selectedFontIndex];

    final isQuoteOnly = _displaySubMemo == null;
    // 구절만 있을 때는 명문장 느낌을 살려 글씨 크기를 키우고, 메모가 있을 때는 균형감 있게 배치
    final double mainFontSize = currentFont.name == '나눔손글씨'
        ? (isQuoteOnly ? 23.0 : 19.5)
        : (isQuoteOnly ? 18.0 : 16.0);
    final double subFontSize = currentFont.name == '나눔손글씨' ? 15.0 : 12.5;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 프리미엄 상단 헤더 영역
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 14, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? AppTheme.headerGradientDark
                    : AppTheme.headerGradientLight,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E2749)
                      : const Color(0xFFDCD5F0),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              children: [
                // 상단 드래그 핸들
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3B485E)
                          : const Color(0xFFB8C7DC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 아이콘 뱃지
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: isDark ? 0.4 : 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 타이틀 & 도서명 서브타이틀
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '감성 문장 카드 스튜디오',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 닫기 버튼
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. 본문 카드 커스텀 및 공유 영역
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 18,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1:1 정사각형 감성 문장 카드 (RepaintBoundary로 캡처)
                  Center(
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: currentTheme.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: currentTheme.borderColor != null
                                ? Border.all(
                                    color: currentTheme.borderColor!,
                                    width: 1.2,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.12,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 상단 헤더: 따옴표 + 워터마크
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: currentTheme.quoteBadgeBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.format_quote_rounded,
                                      color: currentTheme.quoteIconColor,
                                      size: 22,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_stories_rounded,
                                        color: currentTheme.subTextColor,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '독서한줄',
                                        style: TextStyle(
                                          color: currentTheme.subTextColor,
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
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '“$_displayMainText”',
                                          style: currentFont.fontBuilder(
                                            color: currentTheme.textColor,
                                            fontSize: mainFontSize,
                                            height: isQuoteOnly ? 1.75 : 1.6,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        if (_displaySubMemo != null) ...[
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Container(
                                                width: 14,
                                                height: 1.2,
                                                color: currentTheme.subTextColor
                                                    .withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '생각 메모',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                  color: currentTheme.subTextColor
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _displaySubMemo!,
                                            style: currentFont.fontBuilder(
                                              color: currentTheme.subTextColor,
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

                              // 하단 도서 정보 및 날짜 / 앱 설치 워터마크
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 1,
                                    color: currentTheme.dividerColor,
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
                                                color: currentTheme.textColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                height: 1.25,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${book.author}${note.pageNumber > 0 ? ' · p.${note.pageNumber}' : ''}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color:
                                                    currentTheme.subTextColor,
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
                                          color: currentTheme.subTextColor
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
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 0) 카드 포함 내용 선택 토글 (구절과 메모가 둘 다 작성된 경우에만 스마트 노출)
                  if (_canToggleMemo) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2633)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2B384D)
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 1. 구절만 공유
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_includeMemo) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _includeMemo = false);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: !_includeMemo
                                      ? (isDark
                                          ? AppTheme.primaryLight
                                          : AppTheme.primaryColor)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_includeMemo
                                      ? [
                                          BoxShadow(
                                            color: (isDark
                                                    ? AppTheme.primaryLight
                                                    : AppTheme.primaryColor)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.format_quote_rounded,
                                      size: 16,
                                      color: !_includeMemo
                                          ? Colors.white
                                          : (isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.textSecondary),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '구절 공유',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: !_includeMemo
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: !_includeMemo
                                            ? Colors.white
                                            : (isDark
                                                ? AppTheme.darkTextPrimary
                                                : AppTheme.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // 2. 구절+메모 공유
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_includeMemo) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _includeMemo = true);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: _includeMemo
                                      ? (isDark
                                          ? AppTheme.primaryLight
                                          : AppTheme.primaryColor)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _includeMemo
                                      ? [
                                          BoxShadow(
                                            color: (isDark
                                                    ? AppTheme.primaryLight
                                                    : AppTheme.primaryColor)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notes_rounded,
                                      size: 16,
                                      color: _includeMemo
                                          ? Colors.white
                                          : (isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.textSecondary),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '구절+메모 공유',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _includeMemo
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _includeMemo
                                            ? Colors.white
                                            : (isDark
                                                ? AppTheme.darkTextPrimary
                                                : AppTheme.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 1) 서체 스타일 선택 세그먼트 (8가지 다채로운 감성 폰트)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.text_fields_rounded,
                            size: 16,
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '서체 스타일',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${currentFont.name} · ${currentFont.category}',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 8가지 서체 가로 스크롤 선택기
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fonts.length,
                      itemBuilder: (context, index) {
                        final font = _fonts[index];
                        final isSelected = _selectedFontIndex == index;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFontIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                        ? AppTheme.primaryLight
                                        : AppTheme.primaryColor)
                                  : (isDark
                                        ? const Color(0xFF1E2633)
                                        : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark
                                          ? const Color(0xFF2B384D)
                                          : const Color(0xFFE2E8F0)),
                                width: 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            (isDark
                                                    ? AppTheme.primaryLight
                                                    : AppTheme.primaryColor)
                                                .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                font.name,
                                style: font.fontBuilder(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.textPrimary),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2) 배경 테마 색상 선택 세그먼트
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 16,
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '배경 테마',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _themes[_selectedThemeIndex].name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 테마 색상 선택기 (7가지 감성 프리셋)
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _themes.length,
                      itemBuilder: (context, index) {
                        final theme = _themes[index];
                        final isSelected = _selectedThemeIndex == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedThemeIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: theme.gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark
                                          ? Colors.amberAccent
                                          : AppTheme.primaryColor)
                                    : (theme.borderColor ??
                                          Colors.black.withValues(alpha: 0.08)),
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isSelected ? 0.2 : 0.08,
                                  ),
                                  blurRadius: isSelected ? 6 : 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                theme.name,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 하단 버튼 영역 (문장 복사 & 이미지 카드 공유)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            const playStoreUrl =
                                'https://play.google.com/store/apps/details?id=com.hasangseon.reading_record_app';
                            final copyBuffer = StringBuffer()
                              ..writeln('“$_displayMainText”');
                            if (_displaySubMemo != null) {
                              copyBuffer
                                ..writeln()
                                ..writeln('💭 나의 생각: $_displaySubMemo');
                            }
                            copyBuffer
                              ..writeln('- 《${book.title}》 (${book.author})')
                              ..writeln()
                              ..write('📱 독서한줄 앱 다운로드: $playStoreUrl');

                            await Clipboard.setData(
                              ClipboardData(text: copyBuffer.toString()),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('문장과 앱 링크가 클립보드에 복사되었습니다. 📋'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('문장 복사'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSharing ? null : _captureAndShare,
                          icon: _isSharing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            _isSharing ? '고화질 카드 생성 중...' : '이미지 공유하기',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
