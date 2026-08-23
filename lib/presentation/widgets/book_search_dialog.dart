import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_search_result.dart';
import '../controllers/book_controller.dart';
import '../controllers/book_search_controller.dart';
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
    final searchState = ref.watch(bookSearchControllerProvider);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.travel_explore_rounded,
                            color: AppTheme.primaryColor, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '온라인 도서 검색',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textSecondary),
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
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.primaryColor),
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
                          icon: const Icon(Icons.arrow_forward_rounded,
                              color: AppTheme.primaryColor),
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

          const Divider(height: 1, color: AppTheme.borderColor),

          // 검색 결과 본문
          Expanded(
            child: searchState.when(
              data: (results) {
                if (_queryController.text.trim().isEmpty && results.isEmpty) {
                  return _buildInitialGuide();
                }

                if (results.isEmpty) {
                  return _buildEmptyResult();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return _buildSearchResultItem(context, item);
                  },
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      '온라인 도서 데이터베이스 검색 중...',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
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
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: Colors.orangeAccent),
                      const SizedBox(height: 12),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
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

  Widget _buildSearchResultItem(BuildContext context, BookSearchResult item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.coverUrl != null && item.coverUrl!.isNotEmpty
                ? Image.network(
                    item.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.menu_book_rounded,
                      color: AppTheme.primaryLight,
                      size: 28,
                    ),
                  )
                : const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.primaryLight,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 12),
          // 도서 정보 및 등록 버튼
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.author}${item.publisher.isNotEmpty ? ' · ${item.publisher}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (item.totalPages > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '총 ${item.totalPages} 페이지',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
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
                        BookFormDialog.show(
                          context,
                          book: item.toBook(),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('수정 후 등록', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    // 즉시 내 서재에 담기
                    ElevatedButton.icon(
                      onPressed: () async {
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
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.bookmark_add_rounded, size: 14),
                      label: const Text('내 서재에 담기',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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

  Widget _buildInitialGuide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories_rounded,
                  size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              '원하는 책을 검색해 보세요',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '제목, 저자명을 검색하면 표지 이미지, 출판사,\n페이지 수가 자동으로 채워집니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                _buildSuggestChip('클린 코드'),
                _buildSuggestChip('데미안'),
                _buildSuggestChip('어린 왕자'),
                _buildSuggestChip('사피엔스'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestChip(String keyword) {
    return ActionChip(
      label: Text(keyword),
      backgroundColor: AppTheme.backgroundColor,
      side: const BorderSide(color: AppTheme.borderColor),
      labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
      onPressed: () {
        _queryController.text = keyword;
        _onSearch();
      },
    );
  }

  Widget _buildEmptyResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppTheme.textLight),
            const SizedBox(height: 12),
            const Text(
              '검색된 도서가 없습니다',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              '철자를 확인하거나 다른 검색어로 검색해 보세요.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
