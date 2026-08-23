import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../controllers/book_controller.dart';
import 'book_search_dialog.dart';

class BookFormDialog extends ConsumerStatefulWidget {
  final Book? initialBook;

  const BookFormDialog({super.key, this.initialBook});

  static Future<void> show(BuildContext context, {Book? book}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookFormDialog(initialBook: book),
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
  late TextEditingController _totalPagesController;
  late TextEditingController _readPagesController;
  late TextEditingController _coverUrlController;
  late TextEditingController _memoController;

  double _rating = 0.0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    final b = widget.initialBook;
    _titleController = TextEditingController(text: b?.title ?? '');
    _authorController = TextEditingController(text: b?.author ?? '');
    _publisherController = TextEditingController(text: b?.publisher ?? '');
    _totalPagesController = TextEditingController(
        text: b != null && b.totalPages > 0 ? b.totalPages.toString() : '');
    _readPagesController = TextEditingController(
        text: b != null && b.readPages > 0 ? b.readPages.toString() : '');
    _coverUrlController = TextEditingController(text: b?.coverUrl ?? '');
    _memoController = TextEditingController(text: b?.memo ?? '');
    _rating = b?.rating ?? 0.0;
    _isCompleted = b?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _totalPagesController.dispose();
    _readPagesController.dispose();
    _coverUrlController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final publisher = _publisherController.text.trim();
    final totalPages = int.tryParse(_totalPagesController.text.trim()) ?? 0;
    final readPages = int.tryParse(_readPagesController.text.trim()) ?? 0;
    final coverUrl = _coverUrlController.text.trim().isNotEmpty
        ? _coverUrlController.text.trim()
        : null;
    final memo = _memoController.text.trim();

    final isEdit = widget.initialBook != null;
    bool success;

    if (isEdit) {
      final updated = widget.initialBook!.copyWith(
        title: title,
        author: author,
        publisher: publisher,
        totalPages: totalPages,
        readPages: readPages,
        coverUrl: coverUrl,
        isCompleted: _isCompleted || (totalPages > 0 && readPages >= totalPages),
        rating: _rating,
        memo: memo,
      );
      success = await ref.read(bookControllerProvider.notifier).updateBook(updated);
    } else {
      success = await ref.read(bookControllerProvider.notifier).addBook(
            title: title,
            author: author,
            publisher: publisher,
            totalPages: totalPages,
            readPages: readPages,
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
          content: Text(isEdit ? '도서 정보가 수정되었습니다.' : '새 도서가 등록되었습니다.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialBook != null;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: mediaQuery.viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 드래그 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? '도서 정보 수정 ✏️' : '새 도서 등록 📚',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      if (!isEdit)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            BookSearchDialog.show(context);
                          },
                          icon: const Icon(Icons.travel_explore_rounded,
                              size: 16, color: AppTheme.primaryColor),
                          label: const Text('온라인 검색',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 도서 제목 (필수)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '책 제목 *',
                  hintText: '예: 불편한 편의점',
                  prefixIcon: Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? '책 제목을 입력해 주세요.' : null,
              ),
              const SizedBox(height: 12),
              // 저자 (필수) & 출판사
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: '저자 *',
                        hintText: '김호연',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? '저자를 입력해 주세요.' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _publisherController,
                      decoration: const InputDecoration(
                        labelText: '출판사',
                        hintText: '나무옆의자',
                        prefixIcon: Icon(Icons.business_outlined, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 전체 페이지 & 읽은 페이지
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalPagesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '총 페이지 수',
                        hintText: '300',
                        suffixText: 'p',
                        prefixIcon: Icon(Icons.auto_stories_outlined, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _readPagesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '현재 읽은 페이지',
                        hintText: '0',
                        suffixText: 'p',
                        prefixIcon: Icon(Icons.bookmark_outline_rounded, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 표지 이미지 URL
              TextFormField(
                controller: _coverUrlController,
                decoration: const InputDecoration(
                  labelText: '표지 이미지 URL (선택)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.image_outlined, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              // 별점 선택
              Row(
                children: [
                  const Text(
                    '내 별점:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = (_rating == starValue) ? 0.0 : starValue;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
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
                    onSelected: (val) => setState(() => _isCompleted = val),
                    selectedColor: AppTheme.successColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.successColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 한 줄 메모
              TextFormField(
                controller: _memoController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '한 줄 평 / 메모',
                  hintText: '이 책을 읽고 난 느낌이나 기억하고 싶은 점',
                  prefixIcon: Icon(Icons.note_alt_outlined, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              // 등록/수정 버튼
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  isEdit ? '도서 정보 수정 완료' : '내 서재에 등록하기',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
