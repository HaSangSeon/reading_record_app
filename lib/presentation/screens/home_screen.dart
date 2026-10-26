import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/repository_providers.dart';
import '../controllers/book_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/book_card.dart';
import '../widgets/home/home_widgets.dart';
import '../widgets/library_background.dart';
import '../widgets/stats_header.dart';
import 'stats_dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  bool _isSyncing = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _syncData() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final firebaseService = ref.read(firebaseServiceProvider);
      final syncResult = await firebaseService.syncWithCloud(hiveService);
      ref.invalidate(allBooksStreamProvider);
      ref.invalidate(allNotesStreamProvider);
      final success = syncResult.success;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    success
                        ? '클라우드와 최신 데이터로 동기화되었습니다.'
                        : '동기화 중 오류가 발생했습니다.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor:
                success ? const Color(0xFF10B981) : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF4C3A93), const Color(0xFF6B4BC8)]
                            : [AppTheme.primaryColor, const Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '내 서재',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  allBooksAsync.when(
                    data: (books) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${books.length}',
                        style: TextStyle(
                          fontSize: 11,
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
          // 클라우드 동기화 (새로고침) 버튼
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Icon(
                    Icons.sync_rounded,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
            tooltip: '클라우드 동기화',
            onPressed: _isSyncing ? null : _syncData,
          ),
          // 독서 캘린더 바로가기 버튼
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: '독서 캘린더',
            onPressed: () {
              ref.read(statsTabSegmentProvider.notifier).state = 1;
              ref.read(mainNavigationIndexProvider.notifier).state = 2;
            },
          ),
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
      floatingActionButton: filteredBooksAsync.maybeWhen(
        data: (books) {
          if (books.isEmpty) return null; // 빈 화면일 때는 중앙 버튼을 사용하므로 FAB 숨김
          return Container(
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
                onTap: () => AddBookOptionsSheet.show(context),
                borderRadius: BorderRadius.circular(18),
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '책 등록',
                        style: TextStyle(
                          fontSize: 13.5,
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
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: LibraryBackground(isDark: isDark),
          ),
          filteredBooksAsync.when(
            data: (books) {
              return RefreshIndicator(
                color: AppTheme.primaryColor,
                backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                onRefresh: _syncData,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // 독서 통계 배너
                    SliverToBoxAdapter(child: StatsHeader(books: books)),

                    // 프리미엄 일체형 세그먼트 필터 바 (전체 / 읽는 중 / 완독)
                    SliverToBoxAdapter(
                      child: BookFilterSegmentedBar(
                        currentFilter: currentFilter,
                        allBooks: allBooksAsync.value ?? [],
                        isDark: isDark,
                      ),
                    ),

                    // 도서 목록 그리드/리스트
                    if (books.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: HomeEmptyState(isDark: isDark),
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
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
            error: (err, stack) => Center(child: Text('오류가 발생했습니다: $err')),
          ),
        ],
      ),
    );
  }
}
