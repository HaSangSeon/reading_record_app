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
  late TextEditingController _readPageController;
  late TextEditingController _totalPageController;
  late int _readPages;
  late int _totalPages;

  @override
  void initState() {
    super.initState();
    _readPages = widget.book.readPages;
    _totalPages = widget.book.totalPages;
    _readPageController = TextEditingController(
      text: _readPages > 0 ? _readPages.toString() : '',
    );
    _totalPageController = TextEditingController(
      text: _totalPages > 0 ? _totalPages.toString() : '',
    );
  }

  @override
  void dispose() {
    _readPageController.dispose();
    _totalPageController.dispose();
    super.dispose();
  }

  void _updateReadPage(int newPage) {
    final maxP = _totalPages > 0 ? _totalPages : 99999;
    final clamped = newPage.clamp(0, maxP);
    setState(() {
      _readPages = clamped;
      _readPageController.text = clamped > 0 ? clamped.toString() : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTotal = _totalPages > 0;
    final progress = hasTotal
        ? (_readPages / _totalPages).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progress * 100).toInt();
    final isCompleted = hasTotal && _readPages >= _totalPages;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E242B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? const Color(0xFF2E3842) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 상단 헤더: 아이콘 + 책 정보 & 타이틀
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
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
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
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
                            '독서 진행 기록',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
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
                              fontSize: 13,
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
                const SizedBox(height: 22),

                // 페이지 입력 카드 (읽은 쪽수 & 전체 페이지)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF13181F)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF28323D)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 현재 읽은 쪽 입력
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '현재 읽은 쪽',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E242B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF3B4654)
                                      : const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _readPageController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: isDark
                                            ? const Color(0xFF818CF8)
                                            : const Color(0xFF4F46E5),
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val) ?? 0;
                                        final maxP = _totalPages > 0
                                            ? _totalPages
                                            : 99999;
                                        setState(() {
                                          _readPages = parsed.clamp(0, maxP);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'p',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 중간 구분선
                      Container(
                        height: 48,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),

                      // 전체 총 페이지 입력
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '전체 총 페이지',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E242B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF3B4654)
                                      : const Color(0xFFCBD5E1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _totalPageController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val) ?? 0;
                                        setState(() {
                                          _totalPages = parsed.clamp(0, 99999);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'p',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 슬라이더 및 진행률 뱃지
                if (hasTotal) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '독서 달성도',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF4F46E5).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCompleted
                              ? '🎉 100% 완독 완료!'
                              : '$progressPercent% 달성',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : (isDark
                                      ? const Color(0xFF818CF8)
                                      : const Color(0xFF4F46E5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF4F46E5),
                      inactiveTrackColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      thumbColor: isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF4F46E5),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: _readPages.toDouble().clamp(
                        0.0,
                        _totalPages.toDouble(),
                      ),
                      min: 0,
                      max: _totalPages.toDouble(),
                      onChanged: (val) => _updateReadPage(val.toInt()),
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: isDark
                              ? const Color(0xFF818CF8)
                              : const Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '전체 총 페이지를 입력하시면 진행률(%)이 표시됩니다.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF818CF8)
                                  : const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 퀵 증감 버튼들 (-10p, -1p, +1p, +10p)
                Row(
                  children: [
                    _buildQuickButton(
                      label: '-10',
                      onPressed: _readPages > 0
                          ? () => _updateReadPage(_readPages - 10)
                          : null,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildQuickButton(
                      label: '-1',
                      onPressed: _readPages > 0
                          ? () => _updateReadPage(_readPages - 1)
                          : null,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 6),
                    _buildQuickButton(
                      label: '+1',
                      onPressed: () => _updateReadPage(_readPages + 1),
                      isDark: isDark,
                      isPositive: true,
                    ),
                    const SizedBox(width: 6),
                    _buildQuickButton(
                      label: '+10',
                      onPressed: () => _updateReadPage(_readPages + 10),
                      isDark: isDark,
                      isPositive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 하단 액션 버튼 영역
                Row(
                  children: [
                    if (hasTotal && !isCompleted)
                      TextButton.icon(
                        onPressed: () => _updateReadPage(_totalPages),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 17,
                        ),
                        label: const Text(
                          '완독 처리',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? AppTheme.darkTextLight
                            : AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () async {
                        final updatedBook = widget.book.copyWith(
                          readPages: _readPages,
                          totalPages: _totalPages,
                          isCompleted:
                              _totalPages > 0 && _readPages >= _totalPages,
                          completedAt:
                              (_totalPages > 0 && _readPages >= _totalPages)
                              ? (widget.book.completedAt ?? DateTime.now())
                              : null,
                        );
                        await ref
                            .read(bookControllerProvider.notifier)
                            .updateBook(updatedBook);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _totalPages > 0 && _readPages >= _totalPages
                                    ? '🎉 축하합니다! 완독하셨습니다!'
                                    : '독서 진행 상황이 저장되었습니다. (${_readPages}p)',
                              ),
                              backgroundColor:
                                  _totalPages > 0 && _readPages >= _totalPages
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF4F46E5),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '저장하기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isDark,
    bool isPositive = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isPositive
                  ? (isDark
                        ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                        : const Color(0xFF4F46E5).withValues(alpha: 0.08))
                  : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPositive
                    ? (isDark
                          ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                          : const Color(0xFF4F46E5).withValues(alpha: 0.2))
                    : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: onPressed == null
                      ? Colors.grey.withValues(alpha: 0.4)
                      : (isPositive
                            ? (isDark
                                  ? const Color(0xFF818CF8)
                                  : const Color(0xFF4F46E5))
                            : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
