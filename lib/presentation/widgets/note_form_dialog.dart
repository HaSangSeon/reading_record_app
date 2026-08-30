import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../controllers/note_controller.dart';

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
                bottom: mediaQuery.viewInsets.bottom + 24,
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
                        _buildFieldLabel('인상 깊은 구절 / 발췌문 *', isDark),
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
