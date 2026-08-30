import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/ads/admob_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../providers/repository_providers.dart';
import '../controllers/book_controller.dart';
import 'book_search_dialog.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  final Book? initialBook;
  final String? initialTitle;
  final String? initialAuthor;
  final String? initialPublisher;
  final String? initialCoverUrl;
  final int? initialTotalPages;

  const BookFormDialog({
    super.key,
    this.initialBook,
    this.initialTitle,
    this.initialAuthor,
    this.initialPublisher,
    this.initialCoverUrl,
    this.initialTotalPages,
  });

  static Future<void> show(
    BuildContext context, {
    Book? book,
    String? title,
    String? author,
    String? publisher,
    String? coverUrl,
    int? totalPages,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookFormDialog(
        initialBook: book,
        initialTitle: title,
        initialAuthor: author,
        initialPublisher: publisher,
        initialCoverUrl: coverUrl,
        initialTotalPages: totalPages,
      ),
    );
  }

  @override
  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends ConsumerState<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _publisherController;
  late TextEditingController _coverUrlController;
  late TextEditingController _memoController;

  late bool _isCompleted;
  late double _rating;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final b = widget.initialBook;
    _titleController = TextEditingController(
      text: b?.title ?? widget.initialTitle ?? '',
    );
    _authorController = TextEditingController(
      text: b?.author ?? widget.initialAuthor ?? '',
    );
    _publisherController = TextEditingController(
      text: b?.publisher ?? widget.initialPublisher ?? '',
    );
    _coverUrlController = TextEditingController(
      text: b?.coverUrl ?? widget.initialCoverUrl ?? '',
    );
    _memoController = TextEditingController(text: b?.memo ?? '');

    _isCompleted = b?.isCompleted ?? false;
    _rating = b?.rating ?? 0.0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _coverUrlController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _coverUrlController.text = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이미지 가져오기 실패: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppTheme.primaryColor,
              ),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.secondaryColor,
              ),
              title: const Text('카메라로 책 표지 촬영'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final publisher = _publisherController.text.trim();
    final coverUrl = _coverUrlController.text.trim().isEmpty
        ? null
        : _coverUrlController.text.trim();
    final memo = _memoController.text.trim();

    final isEdit = widget.initialBook != null;

    if (!isEdit) {
      final allBooksAsync = ref.read(allBooksStreamProvider);
      final existingBooks = allBooksAsync.value ?? [];
      final hasDuplicate = existingBooks.any(
        (b) => b.title.trim().replaceAll(' ', '') == title.replaceAll(' ', ''),
      );

      if (hasDuplicate) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  '동일한 도서 안내',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              '\'$title\' 도서가 이미 내 서재에 등록되어 있습니다.\n\n새로 추가(N회독)하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('새로 추가하기'),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }
    }

    bool success;

    if (isEdit) {
      final updated = widget.initialBook!.copyWith(
        title: title,
        author: author,
        publisher: publisher,
        coverUrl: coverUrl,
        isCompleted: _isCompleted,
        rating: _rating,
        memo: memo,
      );
      success = await ref
          .read(bookControllerProvider.notifier)
          .updateBook(updated);
    } else {
      success = await ref
          .read(bookControllerProvider.notifier)
          .addBook(
            title: title,
            author: author,
            publisher: publisher,
            coverUrl: coverUrl,
            isCompleted: _isCompleted,
            rating: _rating,
            memo: memo,
          );
    }

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? '도서 정보가 수정되었습니다.' : '새 도서가 등록되었습니다! 📚'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 도서 등록/수정 완료 시 3회에 1회 전면 광고 노출
      AdMobService().triggerActionInterstitial(interval: 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.initialBook != null;
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
                            : Icons.library_add_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 타이틀 & 서브타이틀
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? '도서 정보 수정' : '새 도서 등록',
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
                            isEdit
                                ? (widget.initialBook?.title ?? '도서 정보 수정')
                                : '직접 입력하여 등록',
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
                    const SizedBox(width: 12),
                    // 온라인 검색 숏컷 (신규 등록 시)
                    if (!isEdit) ...[
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          BookSearchDialog.show(context);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppTheme.primaryLight
                                        : AppTheme.primaryColor)
                                    .withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.travel_explore_rounded,
                                size: 14,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '온라인 검색',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
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
                bottom: mediaQuery.viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 18,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 도서 제목 (필수)
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: '책 제목 *',
                        hintText: '예: 불편한 편의점',
                        prefixIcon: Icon(
                          Icons.menu_book_rounded,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? '책 제목을 입력해 주세요.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // 저자 (필수) & 출판사
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _authorController,
                            decoration: InputDecoration(
                              labelText: '저자 *',
                              hintText: '김호연',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                              ),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? '저자를 입력해 주세요.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _publisherController,
                            decoration: InputDecoration(
                              labelText: '출판사',
                              hintText: '나무옆의자',
                              prefixIcon: Icon(
                                Icons.business_outlined,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 표지 이미지 URL & 사진 촬영/갤러리 선택
                    TextFormField(
                      controller: _coverUrlController,
                      decoration: InputDecoration(
                        labelText: '표지 이미지 (URL 또는 사진 선택)',
                        hintText: 'https://... 또는 우측 버튼으로 사진 선택',
                        prefixIcon: Icon(
                          Icons.image_outlined,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.add_a_photo_outlined,
                                size: 20,
                              ),
                              tooltip: '사진 촬영 또는 갤러리 선택',
                              onPressed: _showImageSourceDialog,
                            ),
                            if (_coverUrlController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _coverUrlController.clear()),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 별점 선택
                    Row(
                      children: [
                        Text(
                          '내 별점:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final starValue = index + 1.0;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rating = (_rating == starValue)
                                      ? 0.0
                                      : starValue;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Icon(
                                  index < _rating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: AppTheme.accentColor,
                                  size: 28,
                                ),
                              ),
                            );
                          }),
                        ),
                        const Spacer(),
                        // 완독 여부 토글
                        FilterChip(
                          label: const Text('완독 여부'),
                          selected: _isCompleted,
                          onSelected: (val) =>
                              setState(() => _isCompleted = val),
                          selectedColor: AppTheme.successColor.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: AppTheme.successColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 한 줄 메모
                    TextFormField(
                      controller: _memoController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '한 줄 평 / 메모',
                        hintText: '이 책을 읽고 난 느낌이나 기억하고 싶은 점',
                        prefixIcon: Icon(
                          Icons.note_alt_outlined,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 등록/수정 버튼
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                        foregroundColor: isDark
                            ? AppTheme.darkBackground
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEdit ? '도서 정보 수정 완료' : '내 서재에 등록하기',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
}
