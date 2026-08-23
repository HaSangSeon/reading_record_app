import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../controllers/book_controller.dart';
import '../widgets/book_card.dart';
import '../widgets/book_form_dialog.dart';
import '../widgets/book_search_dialog.dart';
import '../widgets/stats_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooksAsync = ref.watch(filteredBooksProvider);
    final currentFilter = ref.watch(bookFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: '내 서재에서 검색...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) =>
                    ref.read(bookSearchQueryProvider.notifier).state = val,
              )
            : const Row(
                children: [
                  Icon(Icons.auto_stories_rounded,
                      color: AppTheme.primaryColor, size: 26),
                  SizedBox(width: 8),
                  Text('내 로컬 서재'),
                ],
              ),
        actions: [
          // 온라인 도서 검색 버튼
          IconButton(
            icon: const Icon(Icons.travel_explore_rounded,
                color: AppTheme.primaryColor),
            tooltip: '온라인 도서 검색 및 등록',
            onPressed: () => BookSearchDialog.show(context),
          ),
          // 내 서재 내 검색 버튼
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: '내 서재 검색',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  ref.read(bookSearchQueryProvider.notifier).state = '';
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: filteredBooksAsync.when(
        data: (books) {
          return CustomScrollView(
            slivers: [
              // 독서 통계 배너
              SliverToBoxAdapter(
                child: StatsHeader(books: books),
              ),

              // 필터 탭 (전체 / 읽는 중 / 완독)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        ref,
                        label: '전체',
                        type: BookFilterType.all,
                        isSelected: currentFilter == BookFilterType.all,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        label: '📖 읽는 중',
                        type: BookFilterType.reading,
                        isSelected: currentFilter == BookFilterType.reading,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        label: '🎉 완독',
                        type: BookFilterType.completed,
                        isSelected: currentFilter == BookFilterType.completed,
                      ),
                    ],
                  ),
                ),
              ),

              // 도서 목록 리스트 또는 빈 화면 안내
              if (books.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];
                        return BookCard(book: book);
                      },
                      childCount: books.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, _) => Center(
          child: Text('데이터를 불러오지 못했습니다: $err'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => BookFormDialog.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          '도서 등록',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref, {
    required String label,
    required BookFilterType type,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(bookFilterProvider.notifier).state = type,
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.12),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final query = ref.watch(bookSearchQueryProvider);
    final hasQuery = query.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.library_books_outlined,
                size: 56,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasQuery ? '검색 결과가 없습니다' : '아직 등록된 책이 없어요',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? '\'$query\'에 해당하는 책을 찾을 수 없습니다.'
                  : '읽고 있거나 기억하고 싶은 책을\n지금 바로 등록해 보세요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => BookSearchDialog.show(context),
                    icon: const Icon(Icons.travel_explore_rounded, size: 18),
                    label: const Text('온라인 검색'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => BookFormDialog.show(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('직접 등록하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
