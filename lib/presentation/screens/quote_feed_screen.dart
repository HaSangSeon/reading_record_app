import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../../providers/repository_providers.dart';
import '../controllers/note_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/action_bottom_sheet.dart';
import '../widgets/custom_confirm_dialog.dart';
import '../widgets/note_form_dialog.dart';
import '../widgets/shareable_quote_card_dialog.dart';
import 'book_detail_screen.dart';

class QuoteFeedScreen extends ConsumerStatefulWidget {
  const QuoteFeedScreen({super.key});

  @override
  ConsumerState<QuoteFeedScreen> createState() => _QuoteFeedScreenState();
}

class _QuoteFeedScreenState extends ConsumerState<QuoteFeedScreen> {
  bool _isSearching = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedAsync = ref.watch(filteredQuoteFeedProvider);
    final allBooksAsync = ref.watch(allBooksStreamProvider);
    final allNotesAsync = ref.watch(allNotesWithBookProvider);
    final selectedBookId = ref.watch(quoteFeedSelectedBookIdProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.backgroundColor,
      appBar: AppBar(
        flexibleSpace: AppTheme.buildAppBarFlexibleSpace(isDark),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: '문장, 메모, 책 제목으로 검색...',
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  ref.read(quoteFeedSearchQueryProvider.notifier).state = val;
                },
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.format_quote_rounded,
                      size: 20,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('한줄 피드'),
                  const SizedBox(width: 8),
                  allNotesAsync.when(
                    data: (items) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
            tooltip: _isSearching ? '검색 닫기' : '기록 검색',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(quoteFeedSearchQueryProvider.notifier).state = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isDark ? Colors.amberAccent : AppTheme.textSecondary,
            ),
            tooltip: isDark ? '라이트 모드로 전환' : '다크 모드로 전환',
            onPressed: () {
              ref.read(themeControllerProvider.notifier).toggleTheme(context);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 도서별 가로 스크롤 필터 칩 바
          allBooksAsync.when(
            data: (books) {
              if (books.isEmpty) return const SizedBox.shrink();
              return Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: books.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final primary = isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor;
                    if (index == 0) {
                      final isSelected = selectedBookId == null;
                      return ChoiceChip(
                        label: const Text('전체 보기'),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                                  .read(
                                    quoteFeedSelectedBookIdProvider.notifier,
                                  )
                                  .state =
                              null;
                        },
                        selectedColor: isDark
                            ? primary.withValues(alpha: 0.22)
                            : primary.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? primary
                              : (isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary),
                        ),
                        backgroundColor: isDark
                            ? AppTheme.darkSurface
                            : Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? primary
                              : (isDark
                                    ? AppTheme.darkBorder
                                    : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.4 : 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      );
                    }

                    final book = books[index - 1];
                    final isSelected = selectedBookId == book.id;
                    return ChoiceChip(
                      label: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        ref
                            .read(quoteFeedSelectedBookIdProvider.notifier)
                            .state = isSelected
                            ? null
                            : book.id;
                      },
                      selectedColor: isDark
                          ? primary.withValues(alpha: 0.22)
                          : primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? primary
                            : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary),
                      ),
                      backgroundColor: isDark
                          ? AppTheme.darkSurface
                          : Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? primary
                            : (isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.4 : 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // 피드 본문 리스트
          Expanded(
            child: feedAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 8,
                    left: 16,
                    right: 16,
                    bottom: 110, // 배너 광고 및 탭바 높이 대응
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildFeedCard(
                      context,
                      ref,
                      item.book,
                      item.note,
                      isDark,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('기록을 불러오는 중 오류가 발생했습니다: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(
    BuildContext context,
    WidgetRef ref,
    Book book,
    Note note,
    bool isDark,
  ) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final formattedDate = dateFormat.format(note.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFEDF0F5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더: 미니 책 표지 + 책 제목 + 저자 + 페이지 & 더보기
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 미니 책 표지 썸네일
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(bookId: book.id),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color:
                          (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.1),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildMiniCover(book.coverUrl),
                  ),
                ),
                const SizedBox(width: 12),

                // 책 제목 & 저자 & 작성일
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailScreen(bookId: book.id),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                book.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            if (note.pageNumber > 0) ...[
                              Text(
                                ' · ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.darkTextLight
                                      : AppTheme.textLight,
                                ),
                              ),
                              Text(
                                'p.${note.pageNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 작성 날짜 및 더보기 메뉴
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                  ),
                  tooltip: '더보기',
                  onPressed: () {
                    ActionBottomSheet.showNoteActions(
                      context,
                      book: book,
                      note: note,
                      onShare: () {
                        ShareableQuoteCardDialog.show(
                          context,
                          book: book,
                          note: note,
                        );
                      },
                      onEdit: () {
                        NoteFormDialog.show(context, book: book, note: note);
                      },
                      onDelete: () {
                        _showDeleteDialog(context, ref, note);
                      },
                    );
                  },
                ),
              ],
            ),

            // 인상 깊은 구절 (발췌문) 박스
            if (note.quotation.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131822)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                      width: 3.5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 18,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note.quotation,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 나의 생각 / 메모 본문
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                note.content,
                style: TextStyle(
                  fontSize: 14.5,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                  height: 1.55,
                ),
              ),
            ],

            const SizedBox(height: 14),
            // 하단 액션 바: 작성일자 & 감성 카드 공유 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                InkWell(
                  onTap: () => ShareableQuoteCardDialog.show(
                    context,
                    book: book,
                    note: note,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '감성 카드 공유',
                          style: TextStyle(
                            fontSize: 12,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCover(String? coverUrl) {
    if (coverUrl == null || coverUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.book_rounded, size: 18, color: Colors.grey),
      );
    }
    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.book_rounded, size: 18, color: Colors.grey),
        ),
      );
    }
    return Image.file(
      File(coverUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.book_rounded, size: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 34,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '아직 작성된 한줄 기록이 없습니다 ✍️',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '책을 읽으며 마음에 와닿은 문장이나\n나만의 생각을 자유롭게 기록해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final displayText = note.quotation.isNotEmpty
        ? note.quotation
        : (note.content.isNotEmpty ? note.content : '독서 기록');

    final confirmed = await CustomConfirmDialog.show(
      context,
      title: '독서 기록을 삭제하시겠습니까?',
      highlightedTarget: displayText,
      message: '이 독서 기록과 발췌문이 피드 및 서재에서 영구히 삭제됩니다.',
      confirmText: '기록 삭제',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(noteControllerProvider.notifier).deleteNote(note.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('독서 기록이 삭제되었습니다.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
