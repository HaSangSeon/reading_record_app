import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../providers/repository_providers.dart';
import '../controllers/book_controller.dart';
import '../controllers/theme_controller.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allBooksAsync = ref.watch(allBooksStreamProvider);
    final filteredBooksAsync = ref.watch(filteredBooksProvider);
    final currentFilter = ref.watch(bookFilterProvider);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: AppTheme.buildAppBarFlexibleSpace(isDark),
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
            : Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  const Text('내 로컬 서재'),
                ],
              ),
        actions: [
          // 내 서재 내 검색 버튼
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
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
          // 다크/라이트 테마 토글 버튼
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isDark ? Colors.amberAccent : AppTheme.textSecondary,
            ),
            tooltip: '테마 전환 (라이트/다크)',
            onPressed: () =>
                ref.read(themeControllerProvider.notifier).toggleTheme(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF818CF8),
                    Color(0xFF6366F1),
                    Color(0xFF4F46E5),
                  ]
                : const [
                    Color(0xFF6366F1),
                    Color(0xFF4F46E5),
                    Color(0xFF4338CA),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF4F46E5,
              ).withValues(alpha: isDark ? 0.5 : 0.38),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddBookOptions(context),
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '책 등록',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0C0E17),
                    const Color(0xFF131726),
                    const Color(0xFF0C0E17),
                  ]
                : [
                    const Color(0xFFF7F5FC),
                    const Color(0xFFF1EDF8),
                    const Color(0xFFF6F4FA),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: filteredBooksAsync.when(
          data: (books) {
            return CustomScrollView(
              slivers: [
                // 독서 통계 배너
                SliverToBoxAdapter(child: StatsHeader(books: books)),

                // 프리미엄 일체형 세그먼트 필터 바 (전체 / 읽는 중 / 완독)
                SliverToBoxAdapter(
                  child: _buildSegmentedFilterBar(
                    context,
                    ref,
                    currentFilter: currentFilter,
                    allBooks: allBooksAsync.value ?? [],
                    isDark: isDark,
                  ),
                ),

                // 도서 목록 그리드/리스트
                if (books.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 90,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final book = books[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookCard(book: book),
                        );
                      }, childCount: books.length),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (err, stack) => Center(child: Text('오류가 발생했습니다: $err')),
        ),
      ),
    );
  }

  void _showAddBookOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    '새 책 등록',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.travel_explore_rounded,
                      color: primary,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    '온라인 도서 검색',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    '국립중앙도서관/카카오 API로 도서 정보 자동 등록',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    BookSearchDialog.show(context);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.accentColor,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    '직접 입력하여 등록',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: const Text(
                    '표지 사진 첨부 및 수기 정보 입력',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    BookFormDialog.show(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedFilterBar(
    BuildContext context,
    WidgetRef ref, {
    required BookFilterType currentFilter,
    required List<Book> allBooks,
    required bool isDark,
  }) {
    final readingCount = allBooks.where((b) => b.isCompleted == false).length;
    final completedCount = allBooks.where((b) => b.isCompleted == true).length;
    final totalCount = allBooks.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C28) : const Color(0xFFEDEAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF263246) : const Color(0xFFDCD5EE),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildSegmentItem(
            ref: ref,
            title: '전체',
            icon: Icons.grid_view_rounded,
            count: totalCount,
            type: BookFilterType.all,
            isSelected: currentFilter == BookFilterType.all,
            isDark: isDark,
          ),
          _buildSegmentItem(
            ref: ref,
            title: '읽는 중',
            icon: Icons.menu_book_rounded,
            count: readingCount,
            type: BookFilterType.reading,
            isSelected: currentFilter == BookFilterType.reading,
            isDark: isDark,
          ),
          _buildSegmentItem(
            ref: ref,
            title: '완독',
            icon: Icons.check_circle_rounded,
            count: completedCount,
            type: BookFilterType.completed,
            isSelected: currentFilter == BookFilterType.completed,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required int count,
    required BookFilterType type,
    required bool isSelected,
    required bool isDark,
  }) {
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(bookFilterProvider.notifier).state = type;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF242E42) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF384763)
                        : const Color(0xFFD8D2EC),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.5,
                color: isSelected
                    ? primary
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -0.3,
                  color: isSelected
                      ? (isDark ? Colors.white : AppTheme.textPrimary)
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.textSecondary),
                ),
              ),
              const SizedBox(width: 4.5),
              // 카운트 뱃지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5.5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: isDark ? 0.3 : 0.12)
                      : (isDark
                                ? const Color(0xFF2C384E)
                                : const Color(0xFFDCD5EE))
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? primary
                        : (isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textLight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 72,
              color: (isDark ? AppTheme.darkTextLight : AppTheme.textLight)
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '조건에 맞는 책이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 책을 등록하거나 온라인에서 검색해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => BookFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('직접 등록'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor,
                    foregroundColor: isDark
                        ? AppTheme.darkBackground
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
