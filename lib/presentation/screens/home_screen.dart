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
import '../widgets/library_background.dart';
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: LibraryBackground(isDark: isDark),
          ),
          filteredBooksAsync.when(
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
        ],
      ),
    );
  }

  void _showAddBookOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF1E1B2E),
                      AppTheme.darkSurface,
                      AppTheme.darkBackground,
                    ]
                  : [
                      const Color(0xFFFAF8FE),
                      Colors.white,
                      const Color(0xFFF6F4FA),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2D9F3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 드래그 핸들 바
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // 프리미엄 헤더 (아이콘 + 타이틀/서브타이틀 + 닫기 버튼)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    AppTheme.primaryLight,
                                    const Color(0xFF4F46E5),
                                  ]
                                : [
                                    const Color(0xFF6366F1),
                                    AppTheme.primaryColor,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '새 도서 등록',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '나만의 서재에 소중한 책을 담아보세요',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 은은한 그라데이션 구분선
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: 0.02),
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.02),
                              ]
                            : [
                                Colors.black.withValues(alpha: 0.02),
                                const Color(0xFFE2D9F3),
                                Colors.black.withValues(alpha: 0.02),
                              ],
                      ),
                    ),
                  ),

                  // 1. 온라인 도서 검색 카드 (추천)
                  _buildBookAddOptionCard(
                    isDark: isDark,
                    badgeText: '추천 • 빠른 검색',
                    badgeColor: primary,
                    gradientColors: const [
                      Color(0xFF6366F1),
                      Color(0xFF0284C7),
                    ],
                    icon: Icons.travel_explore_rounded,
                    title: '온라인 도서 검색',
                    description: '국립중앙도서관·카카오 공식 DB를 통해\n표지와 도서 정보를 1초 만에 자동 완성해요.',
                    borderColor: isDark
                        ? primary.withValues(alpha: 0.25)
                        : const Color(0xFFDDD6FE),
                    onTap: () {
                      Navigator.pop(ctx);
                      BookSearchDialog.show(context);
                    },
                  ),

                  const SizedBox(height: 12),

                  // 2. 직접 입력하여 등록 카드
                  _buildBookAddOptionCard(
                    isDark: isDark,
                    badgeText: '자유로운 수기 작성',
                    badgeColor: AppTheme.accentColor,
                    gradientColors: const [
                      Color(0xFFF59E0B),
                      Color(0xFFEA580C),
                    ],
                    icon: Icons.edit_note_rounded,
                    title: '직접 입력하여 등록',
                    description: '소장 중인 책의 실물 표지를 직접 촬영하고\n원하는 세부 정보와 메모를 자유롭게 기록해요.',
                    borderColor: isDark
                        ? AppTheme.accentColor.withValues(alpha: 0.25)
                        : const Color(0xFFFED7AA),
                    onTap: () {
                      Navigator.pop(ctx);
                      BookFormDialog.show(context);
                    },
                  ),

                  const SizedBox(height: 14),

                  // 하단 부드러운 팁 문구
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 14,
                          color: isDark
                              ? AppTheme.darkTextLight
                              : AppTheme.textLight,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '검색되지 않는 독립출판물이나 고서는 직접 등록을 추천해요.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppTheme.darkTextLight
                                : AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookAddOptionCard({
    required bool isDark,
    required String badgeText,
    required Color badgeColor,
    required List<Color> gradientColors,
    required IconData icon,
    required String title,
    required String description,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 좌측 입체 그라데이션 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 15),

                // 중앙 텍스트 그룹
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 캡슐 태그 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(
                            alpha: isDark ? 0.18 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? (badgeColor == AppTheme.primaryColor
                                    ? AppTheme.primaryLight
                                    : badgeColor)
                                : badgeColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // 타이틀
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // 설명
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 우측 진입 버튼 아이콘
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDark
                        ? AppTheme.darkTextLight
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
