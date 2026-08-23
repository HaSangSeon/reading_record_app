import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../controllers/book_controller.dart';

class ReadingProgressDialog extends ConsumerStatefulWidget {
  final Book book;

  const ReadingProgressDialog({super.key, required this.book});

  static Future<void> show(BuildContext context, Book book) {
    return showDialog(
      context: context,
      builder: (context) => ReadingProgressDialog(book: book),
    );
  }

  @override
  ConsumerState<ReadingProgressDialog> createState() =>
      _ReadingProgressDialogState();
}

class _ReadingProgressDialogState extends ConsumerState<ReadingProgressDialog> {
  late TextEditingController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.readPages;
    _pageController = TextEditingController(text: _currentPage.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updatePage(int newPage) {
    final maxP = widget.book.totalPages > 0 ? widget.book.totalPages : 99999;
    final clamped = newPage.clamp(0, maxP);
    setState(() {
      _currentPage = clamped;
      _pageController.text = clamped.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.book.totalPages > 0 ? widget.book.totalPages : 1;
    final progress = widget.book.totalPages > 0
        ? (_currentPage / widget.book.totalPages).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = widget.book.totalPages > 0 && _currentPage >= widget.book.totalPages;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bookmark_added_rounded,
                      color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '독서 진행률 기록',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 현재 페이지 입력부
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _pageController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val) ?? 0;
                        final maxP = widget.book.totalPages > 0
                            ? widget.book.totalPages
                            : 99999;
                        setState(() {
                          _currentPage = parsed.clamp(0, maxP);
                        });
                      },
                    ),
                  ),
                  Text(
                    widget.book.totalPages > 0
                        ? '/ ${widget.book.totalPages} p'
                        : 'p',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // 슬라이더 (총 페이지 수가 있을 때)
            if (widget.book.totalPages > 0) ...[
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: isCompleted
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.borderColor,
                  thumbColor: isCompleted
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _currentPage.toDouble().clamp(0.0, total.toDouble()),
                  min: 0,
                  max: total.toDouble(),
                  onChanged: (val) => _updatePage(val.toInt()),
                ),
              ),
              Text(
                '진행률 ${(progress * 100).toInt()}% ${isCompleted ? "🎉 완독!" : ""}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCompleted
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
            ],
            // 퀵 증감 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentPage > 0 ? () => _updatePage(_currentPage - 10) : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('-10p', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentPage > 0 ? () => _updatePage(_currentPage - 1) : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('-1p', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updatePage(_currentPage + 1),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+1p', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updatePage(_currentPage + 10),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+10p', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 하단 저장 / 취소 액션
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(bookControllerProvider.notifier).updateProgress(
                            widget.book.id,
                            _currentPage,
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
