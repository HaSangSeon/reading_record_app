import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
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
            : Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color:
                        isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  const Text('내 로컬 서재'),
                ],
              ),
        actions: [
          // 내 서재 내 검색 버튼
          IconButton(
            icon:
                Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookOptions(context),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          '책 등록',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        elevation: 4,
        backgroundColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                        context: context,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        label: '📖 읽는 중',
                        type: BookFilterType.reading,
                        isSelected: currentFilter == BookFilterType.reading,
                        context: context,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        ref,
                        label: '🎉 완독',
                        type: BookFilterType.completed,
                        isSelected: currentFilter == BookFilterType.completed,
                        context: context,
                      ),
                    ],
                  ),
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
                      left: 16, right: 16, top: 8, bottom: 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookCard(book: book),
                        );
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
        error: (err, stack) => Center(
          child: Text('오류가 발생했습니다: $err'),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    child: Icon(Icons.travel_explore_rounded,
                        color: primary, size: 24),
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
                      borderRadius: BorderRadius.circular(12)),
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
                    child: const Icon(Icons.edit_note_rounded,
                        color: AppTheme.accentColor, size: 24),
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
                      borderRadius: BorderRadius.circular(12)),
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

  Widget _buildFilterChip(
    WidgetRef ref, {
    required String label,
    required BookFilterType type,
    required bool isSelected,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(bookFilterProvider.notifier).state = type;
        }
      },
      selectedColor: isDark
          ? primary.withValues(alpha: 0.22)
          : primary.withValues(alpha: 0.1),
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? primary
            : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? primary
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.4 : 0.8,
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                color:
                    isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
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
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => BookFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('직접 등록'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                    foregroundColor:
                        isDark ? AppTheme.darkBackground : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
