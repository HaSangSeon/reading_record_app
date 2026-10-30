import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/theme/app_theme.dart";
import "../../data/models/book_model.dart";
import "../../data/models/note_model.dart";
import "../../providers/repository_providers.dart";
import "../controllers/theme_controller.dart";
import "../widgets/reading_calendar_view.dart";
import "../widgets/stats/stats_widgets.dart";

/// 통계 및 캘린더 화면 상단 세그먼트 인덱스 (0: 통계 대시보드, 1: 독서 캘린더)
final statsTabSegmentProvider = StateProvider<int>((ref) => 0);

class StatsDashboardScreen extends ConsumerStatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  ConsumerState<StatsDashboardScreen> createState() =>
      _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends ConsumerState<StatsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _barAnim;

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _barAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _syncData({bool isManualButton = false}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final firebaseService = ref.read(firebaseServiceProvider);
      final isGoogleLinked = firebaseService.isLinked;
      final localBookCount = hiveService.bookBox.values.length;

      final syncResult = isGoogleLinked
          ? await firebaseService.syncWithCloud(hiveService)
          : null;

      ref.invalidate(allBooksStreamProvider);
      ref.invalidate(allNotesStreamProvider);

      if (!mounted) return;

      if (isManualButton) {
        _animCtrl.forward(from: 0.0);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        String message;
        IconData icon;
        Color bgColor;

        if (!isGoogleLinked) {
          message = '설정에서 구글 계정을 연동하면 다른 기기와 실시간 동기화됩니다.';
          icon = Icons.info_outline_rounded;
          bgColor = const Color(0xFF6366F1);
        } else if (syncResult != null && !syncResult.success) {
          message = '동기화 중 오류가 발생했습니다.';
          icon = Icons.cloud_off_rounded;
          bgColor = Colors.redAccent;
        } else if (localBookCount == 0) {
          message = '클라우드 동기화 완료 (등록된 도서가 없습니다)';
          icon = Icons.cloud_done_rounded;
          bgColor = const Color(0xFF10B981);
        } else {
          message = '클라우드와 최신 데이터로 동기화되었습니다.';
          icon = Icons.cloud_done_rounded;
          bgColor = const Color(0xFF10B981);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: bgColor,
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booksAsync = ref.watch(allBooksStreamProvider);
    final notesAsync = ref.watch(allNotesStreamProvider);
    final selectedSegment = ref.watch(statsTabSegmentProvider);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: AppTheme.buildAppBarFlexibleSpace(isDark),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                selectedSegment == 0
                    ? Icons.analytics_rounded
                    : Icons.calendar_month_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(selectedSegment == 0 ? "독서 통계 & 리포트" : "독서 캘린더"),
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
            tooltip: "클라우드 동기화",
            onPressed: _isSyncing ? null : () => _syncData(isManualButton: true),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isDark ? Colors.amberAccent : AppTheme.textSecondary,
            ),
            tooltip: isDark ? "라이트 모드로 전환" : "다크 모드로 전환",
            onPressed: () =>
                ref.read(themeControllerProvider.notifier).toggleTheme(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: (isDark
                        ? const Color(0xFF1B172C)
                        : const Color(0xFFEDE8F5))
                    .withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C2548)
                      : const Color(0xFFDFD8EC),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      title: "통계 대시보드",
                      icon: Icons.analytics_rounded,
                      isSelected: selectedSegment == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(statsTabSegmentProvider.notifier).state = 0;
                      },
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      title: "독서 캘린더",
                      icon: Icons.calendar_month_rounded,
                      isSelected: selectedSegment == 1,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(statsTabSegmentProvider.notifier).state = 1;
                      },
                      isDark: isDark,
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
        child: booksAsync.when(
          data: (books) {
            return notesAsync.when(
              data: (notes) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: selectedSegment == 1
                      ? ReadingCalendarView(
                          key: const ValueKey("reading_calendar_view"),
                          books: books,
                          notes: notes,
                          onRefresh: _syncData,
                        )
                      : _buildDashboardBody(context, books, notes),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (err, _) => Center(child: Text("노트 통계 오류: $err")),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (err, _) => Center(child: Text("도서 통계 오류: $err")),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.primaryColor : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark
                        ? Colors.white
                        : (isSelected ? primary : AppTheme.textPrimary))
                    : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardBody(
    BuildContext context,
    List<Book> books,
    List<Note> notes,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (books.isEmpty) {
      return StatsEmptyState(onRefresh: _syncData);
    }

    final totalBooks = books.length;
    final completedBooks = books.where((b) => b.isCompleted).length;
    final readingBooks = totalBooks - completedBooks;
    final completionRate =
        totalBooks > 0 ? ((completedBooks / totalBooks) * 100).toInt() : 0;
    final totalNotes = notes.length;

    final ratedBooks = books.where((b) => b.rating > 0).toList();
    final avgRating = ratedBooks.isNotEmpty
        ? ratedBooks.fold<double>(0, (sum, b) => sum + b.rating) /
            ratedBooks.length
        : 0.0;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      onRefresh: _syncData,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnim,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 핵심 요약 Hero 배너
              StatsHeroInsightBanner(
                totalBooks: totalBooks,
                completedBooks: completedBooks,
                readingBooks: readingBooks,
                completionRate: completionRate,
                barAnim: _barAnim,
              ),

              const SizedBox(height: 16),

              // 2. 빠른 지표 3 카드 (완독 도서, 독서 기록, 별점)
              StatsQuickMetricsRow(
                completedBooks: completedBooks,
                totalNotes: totalNotes,
                avgRating: avgRating,
              ),

              const SizedBox(height: 16),

              // 3. 완독 진행 상태 (도넛 차트 & 프로그레스)
              StatsCompletionStatusCard(
                totalBooks: totalBooks,
                completedBooks: completedBooks,
                readingBooks: readingBooks,
                completionRate: completionRate,
                barAnim: _barAnim,
              ),

              const SizedBox(height: 16),

              // 4. 최근 6개월 완독 추이 바 차트
              StatsMonthlyChartCard(
                books: books,
                barAnim: _barAnim,
              ),

              const SizedBox(height: 16),

              // 5. 인생 도서 & 높은 평점 하이라이트
              StatsTopRatedBooksCard(
                books: books,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
