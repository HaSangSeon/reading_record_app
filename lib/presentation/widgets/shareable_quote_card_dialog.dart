import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

class ShareableQuoteCardDialog extends StatefulWidget {
  final Book book;
  final Note note;

  const ShareableQuoteCardDialog({
    super.key,
    required this.book,
    required this.note,
  });

  static Future<void> show(BuildContext context, {required Book book, required Note note}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareableQuoteCardDialog(book: book, note: note),
    );
  }

  @override
  State<ShareableQuoteCardDialog> createState() => _ShareableQuoteCardDialogState();
}

class _ShareableQuoteCardDialogState extends State<ShareableQuoteCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;
  int _selectedThemeIndex = 0;
  bool _isStoryRatio = false; // false = 1:1, true = 9:16 (Story)
  bool _useSerifFont = true; // true = 명조/Serif, false = 산세리프

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
    return widget.note.content.trim();
  }

  String? get _displaySubMemo {
    if (widget.note.quotation.trim().isNotEmpty && widget.note.content.trim().isNotEmpty) {
      return widget.note.content.trim();
    }
    return null;
  }

  Future<void> _captureAndShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/독서한줄_문장_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(file.path, mimeType: 'image/png');
      const playStoreUrl =
          'https://play.google.com/store/apps/details?id=com.hasangseon.reading_record_app';

      final shareText = StringBuffer()
        ..writeln('“$_displayMainText”')
        ..writeln('- 《${widget.book.title}》 (${widget.book.author})')
        ..writeln()
        ..writeln('✨ 나만의 인생 문장을 기록하고 감성 카드로 공유해보세요.')
        ..write('📱 독서노트 무료 다운로드: $playStoreUrl');

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: '독서한줄 - ${widget.book.title}',
          text: shareText.toString(),
        ),
      );
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E242B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 타이틀 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '감성 문장 카드 스튜디오',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 비율 & 폰트 스타일 퀵 토글 바
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 비율 선택 세그먼트 (1:1 피드 vs 9:16 스토리)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRatioChip(
                        label: '1:1 피드',
                        icon: Icons.crop_square_rounded,
                        isSelected: !_isStoryRatio,
                        onTap: () => setState(() => _isStoryRatio = false),
                        isDark: isDark,
                      ),
                      _buildRatioChip(
                        label: '9:16 스토리',
                        icon: Icons.crop_portrait_rounded,
                        isSelected: _isStoryRatio,
                        onTap: () => setState(() => _isStoryRatio = true),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // 폰트 스타일 토글 (명조체 vs 고딕체)
                InkWell(
                  onTap: () => setState(() => _useSerifFont = !_useSerifFont),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.font_download_rounded,
                          size: 14,
                          color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _useSerifFont ? '명조 감성' : '고딕 산세리프',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 캡처 대상 감성 카드 (프리미엄 렌더링)
            RepaintBoundary(
              key: _cardKey,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: _isStoryRatio ? 420 : 260,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: _isStoryRatio ? 36 : 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: currentTheme.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: currentTheme.borderColor != null
                      ? Border.all(color: currentTheme.borderColor!, width: 1)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: _isStoryRatio ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 헤더: 따옴표 + 워터마크
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                    SizedBox(height: _isStoryRatio ? 36 : 20),

                    // 메인 인용 문장
                    Text(
                      '“$_displayMainText”',
                      style: TextStyle(
                        color: currentTheme.textColor,
                        fontSize: _isStoryRatio ? 18.5 : 16.5,
                        height: 1.65,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        fontFamily: _useSerifFont ? 'serif' : null,
                      ),
                    ),

                    // 추가 감상 메모가 있는 경우
                    if (_displaySubMemo != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _displaySubMemo!,
                        style: TextStyle(
                          color: currentTheme.subTextColor,
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: _useSerifFont ? 'serif' : null,
                        ),
                      ),
                    ],

                    SizedBox(height: _isStoryRatio ? 36 : 22),

                    // 구분선
                    Container(
                      height: 1,
                      color: currentTheme.dividerColor,
                    ),
                    const SizedBox(height: 14),

                    // 하단 도서 정보 및 기록 날짜
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: currentTheme.textColor,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${book.author}${note.pageNumber > 0 ? ' · p.${note.pageNumber}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: currentTheme.subTextColor,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: currentTheme.subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 테마 색상 선택기 (7가지 감성 프리셋)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _themes.length,
                itemBuilder: (context, index) {
                  final theme = _themes[index];
                  final isSelected = _selectedThemeIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedThemeIndex = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: theme.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.amberAccent : AppTheme.primaryColor)
                              : (theme.borderColor ?? Colors.black12),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          theme.name,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // 하단 버튼 영역 (문장 복사 & 이미지 카드 공유)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      const playStoreUrl =
                          'https://play.google.com/store/apps/details?id=com.hasangseon.reading_record_app';
                      await Clipboard.setData(ClipboardData(
                        text:
                            '“$_displayMainText”\n- 《${book.title}》 (${book.author})\n\n📱 독서노트 무료 다운로드: $playStoreUrl',
                      ));
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
                      foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share_rounded, size: 18),
                    label: Text(_isSharing ? '고화질 카드 생성 중...' : '이미지 공유하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
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
    );
  }

  Widget _buildRatioChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
