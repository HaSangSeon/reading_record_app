import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/book_search_result.dart';
import '../../providers/repository_providers.dart';
import '../controllers/book_controller.dart';
import '../controllers/book_search_controller.dart';
import '../screens/book_detail_screen.dart';
import 'book_form_dialog.dart';

class BookSearchDialog extends ConsumerStatefulWidget {
  const BookSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BookSearchDialog(),
    );
  }

  @override
  ConsumerState<BookSearchDialog> createState() => _BookSearchDialogState();
}

class _BookSearchDialogState extends ConsumerState<BookSearchDialog> {
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _queryController.text.trim();
    if (query.isNotEmpty) {
      ref.read(bookSearchControllerProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(bookSearchControllerProvider);
    final allBooksAsync = ref.watch(allBooksStreamProvider);
    final existingBooks = allBooksAsync.value ?? [];
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 상단 핸들 & 타이틀
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.travel_explore_rounded,
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '온라인 도서 검색',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 검색 입력창
                TextField(
                  controller: _queryController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSearch(),
                  decoration: InputDecoration(
                    hintText: '책 제목, 저자, ISBN 검색 (예: 불편한 편의점)',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_queryController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _queryController.clear();
                              ref
                                  .read(bookSearchControllerProvider.notifier)
                                  .clear();
                              setState(() {});
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor,
                          ),
                          onPressed: _onSearch,
                        ),
                      ],
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
          ),

          // 검색 결과 본문
          Expanded(
            child: searchState.when(
              data: (items) {
                if (_queryController.text.trim().isEmpty && items.isEmpty) {
                  return _buildInitialGuide(context);
                }
                if (items.isEmpty) {
                  return _buildEmptyResult(context);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildSearchResultItem(context, item, existingBooks);
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '국내외 도서 정보를 검색하고 있습니다...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _onSearch,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(
    BuildContext context,
    BookSearchResult item,
    List<Book> existingBooks,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 이미 서재에 등록된 도서인지 확인 (제목 및 저자 매칭)
    final existingBook = existingBooks.cast<Book?>().firstWhere(
      (b) =>
          b != null &&
          b.title.trim().replaceAll(' ', '') ==
              item.title.trim().replaceAll(' ', ''),
      orElse: () => null,
    );
    final isAlreadyInLibrary = existingBook != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlreadyInLibrary
              ? (isDark
                    ? AppTheme.primaryLight.withValues(alpha: 0.5)
                    : AppTheme.primaryColor.withValues(alpha: 0.4))
              : (isDark ? AppTheme.darkBorder : AppTheme.borderColor),
          width: isAlreadyInLibrary ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 표지 썸네일
          Container(
            width: 64,
            height: 92,
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                ? Image.network(
                    item.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.menu_book_rounded,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                      size: 28,
                    ),
                  )
                : Icon(
                    Icons.menu_book_rounded,
                    color: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 12),
          // 도서 정보 및 등록 버튼
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isAlreadyInLibrary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 11,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 3),
                            Text(
                              '서재에 있음',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.author}${item.publisher.isNotEmpty ? ' · ${item.publisher}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
                ),
                if (item.totalPages > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '총 ${item.totalPages} 페이지',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 상세 입력 후 등록
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        BookFormDialog.show(context, book: item.toBook());
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                        foregroundColor: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                      ),
                      child: const Text(
                        '수정 후 등록',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 내 서재에 담기 버튼 (중복 여부에 따른 스마트 분기)
                    if (isAlreadyInLibrary)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showDuplicateDialog(context, item, existingBook),
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                        label: const Text(
                          '담김 (중복 확인)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF10B981),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _addBookDirectly(context, item),
                        icon: const Icon(Icons.bookmark_add_rounded, size: 14),
                        label: const Text(
                          '내 서재에 담기',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primaryColor,
                          foregroundColor: isDark
                              ? AppTheme.darkBackground
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addBookDirectly(
    BuildContext context,
    BookSearchResult item,
  ) async {
    final book = item.toBook();
    final success = await ref
        .read(bookControllerProvider.notifier)
        .addBook(
          title: book.title,
          author: book.author,
          publisher: book.publisher,
          coverUrl: book.coverUrl,
          totalPages: book.totalPages,
          memo: book.memo,
        );

    if (context.mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\'${item.title}\' 도서가 내 서재에 등록되었습니다.'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showDuplicateDialog(
    BuildContext context,
    BookSearchResult item,
    Book existingBook,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              '이미 서재에 있는 책입니다',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\'${item.title}\' 도서가 이미 내 서재에 등록되어 있습니다.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '• 기존 도서로 이동하여 독서 기록을 이어갈 수 있습니다.\n• 새로운 마음으로 다시 읽기(N회독)를 원하시면 새로 추가할 수도 있습니다.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey[700],
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // 검색창 닫기
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailScreen(bookId: existingBook.id),
                ),
              );
            },
            child: const Text('기존 도서로 이동'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _addBookDirectly(context, item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('새로 추가하기 (N회독)'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialGuide(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 48,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '원하는 책을 검색해 보세요',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '제목, 저자명을 검색하면 표지 이미지, 출판사,\n페이지 수가 자동으로 채워집니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                _buildSuggestChip('클린 코드', context),
                _buildSuggestChip('데미안', context),
                _buildSuggestChip('어린 왕자', context),
                _buildSuggestChip('사피엔스', context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestChip(String keyword, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      label: Text(keyword),
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : AppTheme.backgroundColor,
      side: BorderSide(
        color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
      ),
      onPressed: () {
        _queryController.text = keyword;
        _onSearch();
      },
    );
  }

  Widget _buildEmptyResult(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: (isDark ? AppTheme.darkTextLight : AppTheme.textLight)
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              '검색된 도서가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '철자를 확인하거나 다른 검색어로 검색해 보세요.',
              style: TextStyle(
                fontSize: 13,
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
}
