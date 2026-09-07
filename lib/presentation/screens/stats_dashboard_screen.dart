import "dart:math" as math;
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "../../core/theme/app_theme.dart";
import "../../data/models/book_model.dart";
import "../../data/models/note_model.dart";
import "../../providers/repository_providers.dart";
import "../controllers/theme_controller.dart";
import "book_detail_screen.dart";

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booksAsync = ref.watch(allBooksStreamProvider);
    final notesAsync = ref.watch(allNotesStreamProvider);

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
                Icons.analytics_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text("독서 통계 & 리포트"),
          ],
        ),
        actions: [
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
              data: (notes) => _buildDashboardBody(context, books, notes),
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

  Widget _buildDashboardBody(
    BuildContext context,
    List<Book> books,
    List<Note> notes,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (books.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final totalBooks = books.length;
    final completedBooks = books.where((b) => b.isCompleted).length;
    final readingBooks = totalBooks - completedBooks;
    final completionRate =
        totalBooks > 0 ? ((completedBooks / totalBooks) * 100).toInt() : 0;
    final totalPages = books.fold<int>(0, (sum, b) => sum + b.readPages);
    final totalNotes = notes.length;

    final ratedBooks = books.where((b) => b.rating > 0).toList();
    final avgRating = ratedBooks.isNotEmpty
        ? ratedBooks.fold<double>(0, (sum, b) => sum + b.rating) /
              ratedBooks.length
        : 0.0;

    return AnimatedBuilder(
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 핵심 요약 Hero 배너
            _buildHeroInsightBanner(
              totalBooks: totalBooks,
              completedBooks: completedBooks,
              readingBooks: readingBooks,
              completionRate: completionRate,
              totalPages: totalPages,
              totalNotes: totalNotes,
              avgRating: avgRating,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // 2. 빠른 지표 3 카드 (페이지, 노트, 별점)
            _buildQuickMetricsRow(
              totalPages: totalPages,
              totalNotes: totalNotes,
              avgRating: avgRating,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // 3. 완독 진행 상태 (도넛 차트 & 프로그레스)
            _buildCompletionStatusCard(
              context: context,
              totalBooks: totalBooks,
              completedBooks: completedBooks,
              readingBooks: readingBooks,
              completionRate: completionRate,
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // 4. 최근 6개월 완독 추이 바 차트
            _buildMonthlyChart(context, books, isDark),

            const SizedBox(height: 16),

            // 5. 인생 도서 & 높은 평점 하이라이트
            _buildTopRatedBooksCard(context, books, isDark),
          ],
        ),
      ),
    );
  }

  // ── 빈 상태 화면 ──
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 52,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "등록된 도서가 아직 없습니다",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "책을 등록하고 독서 노트를 남기면\n다양한 분석 리포트가 완성됩니다.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
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

  // ── 1. Hero 인사이트 배너 ──
  Widget _buildHeroInsightBanner({
    required int totalBooks,
    required int completedBooks,
    required int readingBooks,
    required int completionRate,
    required int totalPages,
    required int totalNotes,
    required double avgRating,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E2468),
            Color(0xFF4A3894),
            Color(0xFF5E46B8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF9F8FFF).withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF382B6E).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // 배경 앰비언트 원형 장식
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC084FC).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 라벨
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "나의 독서 인사이트",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          "누적 독서 활동 리포트",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 핵심 3대 지표 (총 등록 / 완독 / 읽는 중)
                Row(
                  children: [
                    _buildHeroMetricItem(
                      icon: Icons.menu_book_rounded,
                      label: "총 등록",
                      value: "$totalBooks",
                      unit: "권",
                      textColor: Colors.white,
                    ),
                    _buildVerticalDivider(),
                    _buildHeroMetricItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: "완독",
                      value: "$completedBooks",
                      unit: "권",
                      textColor: const Color(0xFF86EFAC),
                    ),
                    _buildVerticalDivider(),
                    _buildHeroMetricItem(
                      icon: Icons.local_fire_department_rounded,
                      label: "읽는 중",
                      value: "$readingBooks",
                      unit: "권",
                      textColor: const Color(0xFFFDE047),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 완독률 프로그레스 바 카드
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "전체 완독률",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            "$completionRate%",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _barAnim,
                        builder: (context, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: totalBooks > 0
                                  ? (completedBooks / totalBooks) * _barAnim.value
                                  : 0.0,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF86EFAC),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color textColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: textColor.withValues(alpha: 0.85)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 38,
      width: 1,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // ── 2. 빠른 지표 행 (3개 카드) ──
  Widget _buildQuickMetricsRow({
    required int totalPages,
    required int totalNotes,
    required double avgRating,
    required bool isDark,
  }) {
    final numberFormat = NumberFormat("#,###");
    final pagesStr = numberFormat.format(totalPages);

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF3B82F6),
            iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            value: pagesStr,
            unit: "p",
            label: "읽은 페이지",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.mode_edit_outline_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFF10B981).withValues(alpha: 0.12),
            value: "$totalNotes",
            unit: "개",
            label: "독서 노트",
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            value: avgRating > 0 ? avgRating.toStringAsFixed(1) : "-",
            unit: avgRating > 0 ? "점" : "",
            label: "평균 평점",
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String unit,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B28) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 3. 완독 진행 상태 카드 (도넛 차트) ──
  Widget _buildCompletionStatusCard({
    required BuildContext context,
    required int totalBooks,
    required int completedBooks,
    required int readingBooks,
    required int completionRate,
    required bool isDark,
  }) {
    final badgeText = completionRate >= 80
        ? "🔥 훌륭해요!"
        : completionRate >= 50
            ? "👍 순조로워요"
            : "📖 힘내볼까요?";

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B28) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.donut_large_rounded,
                    color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "완독 진행 현황",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 도넛 차트 및 범례
            Row(
              children: [
                // 도넛 차트
                SizedBox(
                  width: 96,
                  height: 96,
                  child: AnimatedBuilder(
                    animation: _barAnim,
                    builder: (context, _) {
                      final fraction = totalBooks > 0
                          ? (completedBooks / totalBooks) * _barAnim.value
                          : 0.0;
                      return CustomPaint(
                        painter: _DonutChartPainter(
                          completedFraction: fraction,
                          completedColor: const Color(0xFF10B981),
                          readingColor: isDark
                              ? const Color(0xFF818CF8)
                              : AppTheme.primaryColor,
                          bgColor: isDark
                              ? const Color(0xFF24293E)
                              : const Color(0xFFF1EEF8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "$completionRate%",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "완독률",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 18),

                // 완독 / 읽는 중 범례
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusRow(
                        color: const Color(0xFF10B981),
                        label: "완독한 도서",
                        count: completedBooks,
                        total: totalBooks,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildStatusRow(
                        color: isDark
                            ? const Color(0xFF818CF8)
                            : AppTheme.primaryColor,
                        label: "읽고 있는 도서",
                        count: readingBooks,
                        total: totalBooks,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required Color color,
    required String label,
    required int count,
    required int total,
    required bool isDark,
  }) {
    final pct = total > 0 ? ((count / total) * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              "$count권 ($pct%)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        AnimatedBuilder(
          animation: _barAnim,
          builder: (context, _) {
            final barVal =
                total > 0 ? (count / total) * _barAnim.value : 0.0;
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barVal,
                minHeight: 5,
                backgroundColor: isDark
                    ? const Color(0xFF24293E)
                    : const Color(0xFFF1EEF8),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── 4. 최근 6개월 완독 추이 바 차트 ──
  Widget _buildMonthlyChart(
    BuildContext context,
    List<Book> books,
    bool isDark,
  ) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    final counts = months.map((month) {
      return books.where((b) {
        if (!b.isCompleted) return false;
        final targetDate = b.completedAt ?? b.createdAt;
        return targetDate.year == month.year &&
            targetDate.month == month.month;
      }).length;
    }).toList();

    final totalCount = counts.fold<int>(0, (a, b) => a + b);
    final maxCount =
        counts.fold<int>(1, (max, c) => c > max ? c : max).clamp(1, 999);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B28) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF3B82F6),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "최근 6개월 완독 추이",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF24293E)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "총 $totalCount권",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 차트 바 영역 (오버플로우 방지 및 여유로운 패딩)
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) {
                  final month = months[index];
                  final count = counts[index];
                  final monthLabel = DateFormat("M월").format(month);
                  final isCurrentMonth = index == 5;
                  final ratio = count / maxCount;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 권수 레이블
                          SizedBox(
                            height: 16,
                            child: count > 0
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "$count",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isCurrentMonth
                                            ? (isDark
                                                ? const Color(0xFF93C5FD)
                                                : const Color(0xFF2563EB))
                                            : (isDark
                                                ? AppTheme.darkTextSecondary
                                                : AppTheme.textSecondary),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 4),

                          // 바 그래프 본체 (최대 높이 80px)
                          AnimatedBuilder(
                            animation: _barAnim,
                            builder: (context, _) {
                              final barHeight = count > 0
                                  ? (80 * ratio * _barAnim.value).clamp(8.0, 80.0)
                                  : 4.0;

                              return Container(
                                width: double.infinity,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  gradient: count > 0
                                      ? LinearGradient(
                                          colors: isCurrentMonth
                                              ? [
                                                  const Color(0xFF60A5FA),
                                                  const Color(0xFF2563EB),
                                                ]
                                              : [
                                                  isDark
                                                      ? const Color(0xFF818CF8)
                                                      : const Color(0xFF6366F1),
                                                  isDark
                                                      ? const Color(0xFF4F46E5)
                                                      : const Color(0xFF4338CA),
                                                ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: count == 0
                                      ? (isDark
                                          ? const Color(0xFF24293E)
                                          : const Color(0xFFE2E8F0))
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: count > 0 && isCurrentMonth
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          // 월 텍스트 레이블
                          Text(
                            monthLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrentMonth
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isCurrentMonth
                                  ? (isDark
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFF2563EB))
                                  : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 5. 인생 도서 & 높은 평점 카드 ──
  Widget _buildTopRatedBooksCard(
    BuildContext context,
    List<Book> books,
    bool isDark,
  ) {
    final topBooks = books.where((b) => b.rating >= 4.0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    if (topBooks.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B28) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "인생 도서 & 높은 평점",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${topBooks.length}권",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            ...topBooks.take(5).toList().asMap().entries.map((entry) {
              return _buildTopBookItem(
                context,
                entry.value,
                entry.key,
                isDark,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBookItem(
    BuildContext context,
    Book book,
    int index,
    bool isDark,
  ) {
    final medalColors = [
      const Color(0xFFF59E0B), // 금 (1위)
      const Color(0xFF94A3B8), // 은 (2위)
      const Color(0xFFB45309), // 동 (3위)
    ];

    final hasMedal = index < 3;
    final medalColor =
        hasMedal ? medalColors[index] : AppTheme.textSecondary;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(bookId: book.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222638) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3249) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            // 순위 뱃지
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hasMedal
                    ? medalColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: medalColor,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 도서 표지
            Container(
              width: 32,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D3249)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.menu_book_rounded,
                        size: 16,
                        color: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor,
                      ),
                    )
                  : Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                    ),
            ),

            const SizedBox(width: 10),

            // 도서 제목 및 저자
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 별점 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 13,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    book.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 도넛 차트 CustomPainter (오버플로우 방지 & 둥근 캡) ──
class _DonutChartPainter extends CustomPainter {
  final double completedFraction;
  final Color completedColor;
  final Color readingColor;
  final Color bgColor;

  _DonutChartPainter({
    required this.completedFraction,
    required this.completedColor,
    required this.readingColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 11.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // 배경 트랙
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);

    // 읽는 중 (남은 부분)
    if (completedFraction < 1.0) {
      final readingPaint = Paint()
        ..color = readingColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2 + (2 * math.pi * completedFraction),
        2 * math.pi * (1.0 - completedFraction),
        false,
        readingPaint,
      );
    }

    // 완독 완료 부분
    if (completedFraction > 0.0) {
      final completedPaint = Paint()
        ..color = completedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * completedFraction,
        false,
        completedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) =>
      oldDelegate.completedFraction != completedFraction;
}
