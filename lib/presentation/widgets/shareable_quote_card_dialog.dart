import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/ads/admob_service.dart';
import '../../core/services/kakao_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import 'quote_card/quote_card_controls.dart';
import 'quote_card/quote_card_font.dart';
import 'quote_card/quote_card_preview.dart';
import 'quote_card/quote_card_theme.dart';

export 'quote_card/quote_card_font.dart';
export 'quote_card/quote_card_theme.dart';

/// SNS 및 메신저 공유용 감성 문장 카드 제작 모달 다이얼로그 / 바텀시트
class ShareableQuoteCardDialog extends StatefulWidget {
  final Book book;
  final Note note;
  final bool isDialog;

  const ShareableQuoteCardDialog({
    super.key,
    required this.book,
    required this.note,
    this.isDialog = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Book book,
    required Note note,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width > 600;

    if (isWide) {
      final dialogWidth = math.min(mediaQuery.size.width * 0.85, 440.0);
      final dialogHeight = math.min(mediaQuery.size.height * 0.86, 700.0);
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: ShareableQuoteCardDialog(
              book: book,
              note: note,
              isDialog: true,
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: mediaQuery.size.height * 0.88,
        child: ShareableQuoteCardDialog(book: book, note: note),
      ),
    );
  }

  @override
  State<ShareableQuoteCardDialog> createState() =>
      _ShareableQuoteCardDialogState();
}

class _ShareableQuoteCardDialogState extends State<ShareableQuoteCardDialog>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  late final ScrollController _scrollController;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  bool _showScrollHint = true;
  bool _isSharingKakao = false;
  bool _isSharingOther = false;
  bool _isCapturing = false;

  int _selectedThemeIndex = 0;
  int _selectedFontIndex = 0;
  bool _includeMemo = true; // 구절만 vs 구절+메모 토글 상태
  double _fontSizeScale = 1.0; // 텍스트 크기 조절 배율 (0.5 ~ 1.3)
  bool _hasUserAdjustedFontSize = false; // 사용자가 슬라이더로 직접 조절했는지 여부
  File? _customImageFile; // 사용자가 앨범에서 선택한 배경 사진
  bool _isCustomImageActive = false; // 내 사진 배경 활성화 여부
  double _imageDimOpacity = 0.45; // 배경 사진 어둡기 오버레이 투명도 (0.15 ~ 0.85)
  bool _isDarkTextColor = false; // 내 사진 배경 시 글자 색상 (false: 화이트, true: 차콜 블랙)

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fontSizeScale = _calculateInitialFontSizeScale();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 25 && _showScrollHint) {
        setState(() => _showScrollHint = false);
      } else if (_scrollController.offset <= 25 && !_showScrollHint) {
        setState(() => _showScrollHint = true);
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasQuotation => widget.note.quotation.trim().isNotEmpty;
  bool get _hasMemo => widget.note.content.trim().isNotEmpty;
  bool get _canToggleMemo => _hasQuotation && _hasMemo;

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

  /// 텍스트 길이 및 줄바꿈 수에 맞춰 카드 하단이 잘리지 않으면서도
  /// 위아래 공백을 최소화하여 시각적으로 꽉 차도록 초기 폰트 크기 배율 자동 산출
  double _calculateInitialFontSizeScale({bool? includeMemo, int? fontIndex}) {
    final useMemo = includeMemo ?? _includeMemo;
    final mainText = _displayMainText;
    final bool hasSubMemo =
        _canToggleMemo && useMemo && widget.note.content.trim().isNotEmpty;
    final subText = hasSubMemo ? widget.note.content.trim() : null;

    final selectedFont = kQuoteCardFonts[fontIndex ?? _selectedFontIndex];
    final bool isHandwriting = selectedFont.name == '나눔손글씨';
    final bool isQuoteOnly = subText == null;

    // 1:1 카드 내부 중앙 텍스트 영역의 가용 높이 (약 220px) 및 가용 너비 (약 295px)
    const double availableHeight = 220.0;
    const double availableWidth = 295.0;

    // 큰 배율부터 역순으로 탐색하여 잘리지 않고 가장 꽉 차는 최적 배율 채택
    const List<double> candidateScales = [
      1.10,
      1.05,
      1.00,
      0.95,
      0.90,
      0.85,
      0.80,
      0.75,
      0.70,
      0.65,
      0.60,
      0.55,
      0.50,
    ];

    for (final scale in candidateScales) {
      final double baseMainSize = isHandwriting
          ? (isQuoteOnly ? 23.0 : 19.5)
          : (isQuoteOnly ? 18.0 : 16.0);
      final double mainFontSize = baseMainSize * scale;
      final double mainLineHeight = mainFontSize * (isQuoteOnly ? 1.62 : 1.55);

      // 한글 + 영문/기호/공백 혼합 시 평균 글자당 폭 (약 fontSize * 0.54)
      final double mainCharsPerLine =
          math.max(16.0, availableWidth / (mainFontSize * 0.54));

      // 본문 문단별 줄 수 계산
      double estimatedMainLines = 0;
      final mainParagraphs = mainText.split('\n');
      for (final para in mainParagraphs) {
        if (para.trim().isEmpty) {
          estimatedMainLines += 0.6;
        } else {
          // 따옴표 기호(“ ”) 폭 감안
          final len = para.length +
              (para == mainParagraphs.first ? 1 : 0) +
              (para == mainParagraphs.last ? 1 : 0);
          estimatedMainLines +=
              math.max(1.0, (len / mainCharsPerLine).ceilToDouble());
        }
      }

      double requiredHeight = estimatedMainLines * mainLineHeight;

      // 생각 메모가 포함된 경우
      if (subText != null) {
        // 구분선 여백(14) + 라벨 높이(16) + 라벨 하단 여백(6) = 36px
        const double memoHeaderHeight = 36.0;
        final double baseSubSize = isHandwriting ? 15.0 : 12.5;
        final double subFontSize = baseSubSize * scale;
        final double subLineHeight = subFontSize * 1.5;

        final double subCharsPerLine =
            math.max(18.0, availableWidth / (subFontSize * 0.54));

        double estimatedSubLines = 0;
        final subParagraphs = subText.split('\n');
        for (final para in subParagraphs) {
          if (para.trim().isEmpty) {
            estimatedSubLines += 0.6;
          } else {
            estimatedSubLines +=
                math.max(1.0, (para.length / subCharsPerLine).ceilToDouble());
          }
        }

        requiredHeight += memoHeaderHeight + (estimatedSubLines * subLineHeight);
      }

      // 가용 높이에 여유 있게 들어가면 해당 배율 채택
      if (requiredHeight <= availableHeight) {
        return scale;
      }
    }

    return 0.55;
  }

  Future<void> _pickCustomImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (picked != null) {
        setState(() {
          _customImageFile = File(picked.path);
          _isCustomImageActive = true;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진을 불러오지 못했습니다: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareViaKakao() async {
    if (_isSharingKakao || _isSharingOther) return;
    setState(() {
      _isSharingKakao = true;
      _isCapturing = true;
    });

    // 화면이 사각형 테두리로 렌더링되도록 잠시 대기
    await Future.delayed(const Duration(milliseconds: 50));

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
        '${tempDir.path}/독서한줄_문장_카카오_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      // 카카오톡 이미지 업로드 및 공유 실행
      await KakaoShareService().shareLocalImageCard(
        imageFile: file,
        text: _displayMainText,
      );

      // 소셜 카드 공유 완료 시 통합 액션 카운터 증가
      AdMobService().triggerActionInterstitial();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카카오톡 공유 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharingKakao = false;
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _captureAndShare() async {
    if (_isSharingKakao || _isSharingOther) return;
    setState(() {
      _isSharingOther = true;
      _isCapturing = true;
    });

    // 화면이 사각형 테두리로 렌더링되도록 잠시 대기
    await Future.delayed(const Duration(milliseconds: 50));

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

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
        ),
      );

      // 소셜 카드 공유 완료 시 통합 액션 카운터 증가
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
        setState(() {
          _isSharingOther = false;
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _copyTextToClipboard() async {
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.hasangseon.reading_record_app';
    final copyBuffer = StringBuffer()..writeln('“$_displayMainText”');
    if (_displaySubMemo != null) {
      copyBuffer
        ..writeln()
        ..writeln('💭 나의 생각: $_displaySubMemo');
    }
    copyBuffer
      ..writeln('- 《${widget.book.title}》 (${widget.book.author})')
      ..writeln()
      ..write('📱 독서한줄 앱 다운로드: $playStoreUrl');

    await Clipboard.setData(
      ClipboardData(text: copyBuffer.toString()),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문장과 앱 링크가 클립보드에 복사되었습니다. 📋'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final book = widget.book;
    final note = widget.note;
    final dateStr = DateFormat('yyyy.MM.dd').format(note.createdAt);
    final isUsingCustomPhoto = _isCustomImageActive && _customImageFile != null;
    final currentTheme = kQuoteCardThemes[_selectedThemeIndex];
    final currentFont = kQuoteCardFonts[_selectedFontIndex];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(28)
            : const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
                              color: const Color(0xFF8B5CF6).withValues(
                                alpha: isDark ? 0.4 : 0.25,
                              ),
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
                      // 복사 버튼
                      IconButton(
                        onPressed: _copyTextToClipboard,
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
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

            // 2. 본문 카드 커스텀 및 공유 영역 (스크롤바 + 힌트 인디케이터 포함)
            Expanded(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    thickness: 5,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        top: 18,
                        left: 20,
                        right: 20,
                        bottom: math.max(
                              MediaQuery.of(context).viewPadding.bottom,
                              MediaQuery.of(context).padding.bottom,
                            ) +
                            48,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1:1 정사각형 감성 문장 카드 (RepaintBoundary로 캡처)
                          QuoteCardPreview(
                            cardKey: _cardKey,
                            book: book,
                            dateStr: dateStr,
                            pageNumber: note.pageNumber,
                            displayMainText: _displayMainText,
                            displaySubMemo: _displaySubMemo,
                            theme: currentTheme,
                            font: currentFont,
                            fontSizeScale: _fontSizeScale,
                            isCapturing: _isCapturing,
                            isUsingCustomPhoto: isUsingCustomPhoto,
                            customImageFile: _customImageFile,
                            isDarkTextColor: _isDarkTextColor,
                            imageDimOpacity: _imageDimOpacity,
                          ),

                          const SizedBox(height: 18),

                          // 0) 카드 포함 내용 선택 토글 (구절과 메모가 둘 다 작성된 경우에만 스마트 노출)
                          if (_canToggleMemo) ...[
                            QuoteCardMemoToggle(
                              includeMemo: _includeMemo,
                              onToggle: (val) {
                                setState(() {
                                  _includeMemo = val;
                                  if (!_hasUserAdjustedFontSize) {
                                    _fontSizeScale =
                                        _calculateInitialFontSizeScale(
                                            includeMemo: val);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 18),
                          ],

                          // 1) 서체 스타일 선택 세그먼트 (13가지 다채로운 감성 폰트)
                          QuoteCardFontSelector(
                            fonts: kQuoteCardFonts,
                            selectedIndex: _selectedFontIndex,
                            onSelect: (index) {
                              setState(() {
                                _selectedFontIndex = index;
                                if (!_hasUserAdjustedFontSize) {
                                  _fontSizeScale =
                                      _calculateInitialFontSizeScale(
                                          fontIndex: index);
                                }
                              });
                            },
                          ),

                          const SizedBox(height: 18),

                          // 2) 배경 테마 색상 선택 세그먼트
                          QuoteCardThemeSelector(
                            themes: kQuoteCardThemes,
                            selectedThemeIndex: _selectedThemeIndex,
                            isUsingCustomPhoto: isUsingCustomPhoto,
                            customImageFile: _customImageFile,
                            onSelectTheme: (index) {
                              setState(() {
                                _isCustomImageActive = false;
                                _selectedThemeIndex = index;
                              });
                            },
                            onPickCustomImage: _pickCustomImage,
                            onSelectExistingPhoto: () {
                              setState(() => _isCustomImageActive = true);
                            },
                          ),

                          // 내 사진 선택 시 상세 컨트롤 박스 (Option A: 글자 색상 2단 토글 & 톤 조절 & 사진 변경 / 해제)
                          if (isUsingCustomPhoto) ...[
                            const SizedBox(height: 12),
                            QuoteCardPhotoEffectControls(
                              imageDimOpacity: _imageDimOpacity,
                              isDarkTextColor: _isDarkTextColor,
                              onPickCustomImage: _pickCustomImage,
                              onResetCustomImage: () {
                                setState(() {
                                  _isCustomImageActive = false;
                                  _customImageFile = null;
                                });
                              },
                              onTextColorChanged: (val) {
                                setState(() => _isDarkTextColor = val);
                              },
                              onDimOpacityChanged: (val) {
                                setState(() => _imageDimOpacity = val);
                              },
                            ),
                          ],

                          const SizedBox(height: 18),

                          // 3) 폰트 크기 조절 슬라이더
                          QuoteCardFontSizeSlider(
                            fontSizeScale: _fontSizeScale,
                            onChanged: (val) {
                              setState(() {
                                _fontSizeScale = val;
                                _hasUserAdjustedFontSize = true;
                              });
                            },
                          ),

                          const SizedBox(height: 22),

                          // 하단 버튼 영역 (카카오톡 공유 & 기타 공유)
                          QuoteCardShareActions(
                            isSharingKakao: _isSharingKakao,
                            isSharingOther: _isSharingOther,
                            isDialog: widget.isDialog,
                            onShareKakao: _shareViaKakao,
                            onShareOther: _captureAndShare,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. 하단 스크롤 안내 반투명 플로팅 바운스 화살표 인디케이터 (스크롤이 상단에 있을 때 노출)
                  Positioned(
                    bottom: 14,
                    child: AnimatedOpacity(
                      opacity: _showScrollHint ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: IgnorePointer(
                        ignoring: !_showScrollHint,
                        child: AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _bounceAnimation.value),
                              child: child,
                            );
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _scrollController.animateTo(
                                  220,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                          .withValues(alpha: 0.65)
                                      : Colors.black.withValues(alpha: 0.4),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
