import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../controllers/note_controller.dart';

class NoteFormDialog extends ConsumerStatefulWidget {
  final Book book;
  final Note? initialNote;

  const NoteFormDialog({
    super.key,
    required this.book,
    this.initialNote,
  });

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
  bool _syncBookProgress = true;

  @override
  void initState() {
    super.initState();
    final n = widget.initialNote;
    final defaultPage = n != null
        ? n.pageNumber.toString()
        : (widget.book.readPages > 0 ? widget.book.readPages.toString() : '');

    _pageController = TextEditingController(text: defaultPage);
    _quotationController = TextEditingController(text: n?.quotation ?? '');
    _contentController = TextEditingController(text: n?.content ?? '');
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
      success =
          await ref.read(noteControllerProvider.notifier).updateNote(updated);
    } else {
      success = await ref.read(noteControllerProvider.notifier).addNote(
            bookId: widget.book.id,
            pageNumber: pageNumber,
            content: content,
            quotation: quotation,
            updateBookPageIfHigher: _syncBookProgress,
          );
    }

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? '독서 노트가 수정되었습니다.' : '새 독서 기록이 추가되었습니다.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? '독서 기록 수정 📝' : '새 독서 노트 작성 ✍️',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 기록 페이지 및 진행률 동기화 (여유 있는 너비 및 겹침 방지 레이아웃)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _pageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '기록한 페이지',
                        hintText: '42',
                        suffixText: widget.book.totalPages > 0
                            ? ' / ${widget.book.totalPages}p'
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
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (!isEdit) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkBorder
                                : AppTheme.borderColor,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: _syncBookProgress,
                          onChanged: (val) =>
                              setState(() => _syncBookProgress = val ?? true),
                          title: Text(
                            '진행률 동기화',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // 인상 깊은 문장 (발췌문)
              TextFormField(
                controller: _quotationController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '인상 깊은 구절 / 발췌문 (선택)',
                  hintText: '책에서 마음에 와닿은 문장을 적어보세요.',
                  prefixIcon: Icon(
                    Icons.format_quote_rounded,
                    color:
                        isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),

              // 나의 생각 / 메모 (필수)
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '나의 생각 / 메모 *',
                  hintText: '이 구절을 읽고 어떤 생각이 들었나요?',
                  prefixIcon: Icon(
                    Icons.edit_note_rounded,
                    color:
                        isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? '메모 내용을 입력해 주세요.'
                    : null,
              ),
              const SizedBox(height: 24),

              // 등록/수정 버튼
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                  foregroundColor:
                      isDark ? AppTheme.darkBackground : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  isEdit ? '기록 수정 완료' : '독서 노트 저장하기',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
