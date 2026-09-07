import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/ads/admob_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../controllers/note_controller.dart';
import '../screens/live_ocr_scan_screen.dart';
import 'ocr_text_picker_sheet.dart';

class NoteFormDialog extends ConsumerStatefulWidget {
  final Book book;
  final Note? initialNote;

  const NoteFormDialog({super.key, required this.book, this.initialNote});

  static Future<void> show(
    BuildContext context, {
    required Book book,
    Note? note,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteFormDialog(book: book, initialNote: note),
    );
  }

  @override
  ConsumerState<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends ConsumerState<NoteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pageController;
  late TextEditingController _quotationController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;
    _pageController = TextEditingController(
      text: note != null && note.pageNumber > 0
          ? note.pageNumber.toString()
          : (widget.book.readPages > 0 ? widget.book.readPages.toString() : ''),
    );
    _quotationController = TextEditingController(text: note?.quotation ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _quotationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _scanQuoteFromImage() async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      // 1. 촬영 vs 갤러리 선택 바텀시트
      final String? action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2633) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3B485E)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: isDark ? 0.4 : 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '책 속 문장 스캔',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: isDark ? 0.25 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'AI OCR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '책 페이지를 비추면 AI가 글자를 즉시 인식합니다',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 1. 카메라 조준 스캔 카드 (추천 · 원터치)
              InkWell(
                onTap: () => Navigator.pop(ctx, 'camera'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF242E3E)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.crop_free_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '카메라 조준 스캔',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '원터치 추천',
                                    style: TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '박스에 문장을 맞추고 셔터 1번으로 즉시 추출해요',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 2. 앨범에서 선택 카드
              InkWell(
                onTap: () => Navigator.pop(ctx, 'gallery'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF242E3E)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '앨범에서 사진 선택',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '보관해 둔 책 사진에서 문장을 가져옵니다',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (action == null || !mounted) return;

      String? scannedText;

      if (action == 'camera') {
        // 1. 실시간 조준 라이브 스캐너 실행 (원터치 자동 크롭 & 인식)
        scannedText = await LiveOcrScanScreen.show(context);
      } else {
        // 2. 앨범에서 사진 선택 후 크롭
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );

        if (picked == null || !mounted) return;

        final croppedFile = await ImageCropper().cropImage(
          sourcePath: picked.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '문장 영역 선택',
              toolbarColor: const Color(0xFF111318),
              toolbarWidgetColor: Colors.white,
              backgroundColor: const Color(0xFF0A0B0E),
              activeControlsWidgetColor: const Color(0xFF818CF8),
              dimmedLayerColor: const Color(0xB3000000),
              cropFrameColor: const Color(0xFF818CF8),
              cropGridColor: const Color(0x40818CF8),
              cropFrameStrokeWidth: 2,
              cropGridStrokeWidth: 1,
              showCropGrid: true,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              statusBarLight: false,
              navBarLight: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.square,
              ],
            ),
            IOSUiSettings(
              title: '문장 영역 선택',
              doneButtonTitle: '완료',
              cancelButtonTitle: '취소',
              aspectRatioPickerButtonHidden: false,
              resetAspectRatioEnabled: true,
            ),
          ],
        );

        if (croppedFile == null || !mounted) return;

        scannedText = await OcrTextPickerSheet.show(
          context,
          imageFile: File(croppedFile.path),
        );
      }

      if (scannedText == null || scannedText.trim().isEmpty || !mounted) return;

      final trimmedText = scannedText.trim();

      // 3. 기존 텍스트가 있을 경우 이어붙이기 / 교체 확인
      if (_quotationController.text.trim().isNotEmpty) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('구절 입력 방식 선택'),
            content: const Text(
              '기존에 입력된 구절이 있습니다.\n기존 내용 뒤에 이어서 붙일까요, 아니면 새 내용으로 바꿀까요?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('새 내용으로 바꾸기'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('이어서 붙이기'),
              ),
            ],
          ),
        );

        if (replace == true) {
          _quotationController.text = trimmedText;
        } else if (replace == false) {
          _quotationController.text =
              '${_quotationController.text.trim()}\n$trimmedText';
        }
      } else {
        _quotationController.text = trimmedText;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진을 가져오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final pageNumber = int.tryParse(_pageController.text.trim()) ?? 0;
    final quotation = _quotationController.text.trim();
    final content = _contentController.text.trim();

    final isEdit = widget.initialNote != null;
    bool success;

    if (isEdit) {
      final updated = widget.initialNote!.copyWith(
        pageNumber: pageNumber,
        quotation: quotation,
        content: content,
      );
      success = await ref
          .read(noteControllerProvider.notifier)
          .updateNote(updated);
    } else {
      success = await ref
          .read(noteControllerProvider.notifier)
          .addNote(
            bookId: widget.book.id,
            pageNumber: pageNumber,
            content: content,
            quotation: quotation,
            updateBookPageIfHigher: true,
          );
    }

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? '독서 기록이 수정되었습니다.' : '새 독서 기록이 추가되었습니다.'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // 독서 기록 저장/수정 완료 시 통합 액션 카운터 증가 (기본 4회 완료 시 1회 노출, 3분 쿨타임)
      AdMobService().triggerActionInterstitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.initialNote != null;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 프리미엄 상단 헤더 영역 (전용 배경색 + 아이콘 + 타이틀 & 서브타이틀 + 닫기 버튼)
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
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF4F46E5),
                                  const Color(0xFF6366F1),
                                ]
                              : [
                                  const Color(0xFF4338CA),
                                  const Color(0xFF4F46E5),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: isDark ? 0.4 : 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_note_rounded
                            : Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 타이틀 & 도서명 서브타이틀
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? '독서 기록 수정' : '새 독서 노트 작성',
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
                    const SizedBox(width: 10),
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

          // 2. 본문 폼 입력 영역
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 18,
                left: 20,
                right: 20,
                bottom: mediaQuery.viewInsets.bottom +
                    math.max(mediaQuery.viewPadding.bottom, 24.0),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 페이지 번호 및 진행률 동기화 옵션
                    // 기록 페이지 입력 (선택)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('기록 페이지 (선택)', isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _pageController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '예: 42',
                            suffixText: widget.book.totalPages > 0
                                ? '/ ${widget.book.totalPages}p'
                                : 'p',
                            suffixStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.bookmark_outline_rounded,
                              color: isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor,
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 인상 깊은 문장 (발췌문 - 필수)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFieldLabel('인상 깊은 구절 / 발췌문 *', isDark),
                            InkWell(
                              onTap: _scanQuoteFromImage,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF6366F1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.document_scanner_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '문장 스캔',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _quotationController,
                          maxLines: 3,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                            height: 1.45,
                          ),
                          decoration: InputDecoration(
                            hintText: '책에서 마음에 와닿은 문장을 적어보세요.',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 36),
                              child: Icon(
                                Icons.format_quote_rounded,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? '인상 깊은 구절을 입력해 주세요.'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 나의 생각 / 메모 (선택)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('나의 생각 / 메모 (선택)', isDark),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _contentController,
                          maxLines: 4,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                            height: 1.45,
                          ),
                          decoration: InputDecoration(
                            hintText: '이 구절을 읽고 어떤 생각이 들었나요?',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 54),
                              child: Icon(
                                Icons.edit_note_rounded,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 등록/수정 버튼
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isEdit ? '기록 수정 완료' : '독서 기록 저장하기',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
