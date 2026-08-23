import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';
import '../../providers/repository_providers.dart';
import 'book_detail_screen.dart';

class StatsDashboardScreen extends ConsumerWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(allBooksStreamProvider);
    final notesAsync = ref.watch(allNotesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.insights_rounded, color: AppTheme.primaryColor, size: 26),
            SizedBox(width: 8),
            Text('독서 통계 & 리포트'),
          ],
        ),
      ),
      body: booksAsync.when(
        data: (books) {
          return notesAsync.when(
            data: (notes) => _buildDashboardBody(context, books, notes),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
            error: (err, _) => Center(child: Text('노트 통계 오류: $err')),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, _) => Center(child: Text('도서 통계 오류: $err')),
      ),
    );
  }

  Widget _buildDashboardBody(
    BuildContext context,
    List<Book> books,
    List<Note> notes,
  ) {
    if (books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 56, color: AppTheme.textLight),
              SizedBox(height: 16),
              Text(
                '아직 등록된 도서가 없습니다.',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                '책을 등록하고 독서 기록을 남기면\n다양한 통계 리포트가 제공됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final totalBooks = books.length;
    final completedBooks = books.where((b) => b.isCompleted).length;
    final readingBooks = totalBooks - completedBooks;
    final completionRate =
        totalBooks > 0 ? ((completedBooks / totalBooks) * 100).toInt() : 0;
    final totalPages = books.fold<int>(0, (sum, b) => sum + b.readPages);
    final totalNotes = notes.length;

    // 평균 별점 계산 (별점이 있는 도서 대상)
    final ratedBooks = books.where((b) => b.rating > 0).toList();
    final avgRating = ratedBooks.isNotEmpty
        ? ratedBooks.fold<double>(0, (sum, b) => sum + b.rating) /
            ratedBooks.length
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 핵심 요약 카드 그리드
          _buildSummaryGrid(
            totalBooks: totalBooks,
            completedBooks: completedBooks,
            readingBooks: readingBooks,
            completionRate: completionRate,
            totalPages: totalPages,
            totalNotes: totalNotes,
            avgRating: avgRating,
          ),

          const SizedBox(height: 20),

          // 2. 완독 현황 게이지 카드
          _buildCompletionStatusCard(
            totalBooks: totalBooks,
            completedBooks: completedBooks,
            readingBooks: readingBooks,
            completionRate: completionRate,
          ),

          const SizedBox(height: 20),

          // 3. 월별 독서량 차트 (지난 6개월)
          _buildMonthlyReadingChart(books),

          const SizedBox(height: 20),

          // 4. 높은 평점 도서 하이라이트
          _buildTopRatedBooksCard(context, books),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid({
    required int totalBooks,
    required int completedBooks,
    required int readingBooks,
    required int completionRate,
    required int totalPages,
    required int totalNotes,
    required double avgRating,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                '나의 누적 독서 인사이트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStatMetric(
                label: '총 등록 도서',
                value: '$totalBooks 권',
                icon: Icons.menu_book_rounded,
              ),
              _buildStatDivider(),
              _buildStatMetric(
                label: '완독률',
                value: '$completionRate %',
                icon: Icons.task_alt_rounded,
              ),
              _buildStatDivider(),
              _buildStatMetric(
                label: '누적 페이지',
                value: '$totalPages p',
                icon: Icons.import_contacts_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatMetric(
                label: '작성한 독서 노트',
                value: '$totalNotes 개',
                icon: Icons.edit_note_rounded,
              ),
              _buildStatDivider(),
              _buildStatMetric(
                label: '평균 별점',
                value: avgRating > 0 ? '★ ${avgRating.toStringAsFixed(1)}' : '-',
                icon: Icons.star_rounded,
              ),
              _buildStatDivider(),
              _buildStatMetric(
                label: '현재 읽는 중',
                value: '$readingBooks 권',
                icon: Icons.local_fire_department_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildCompletionStatusCard({
    required int totalBooks,
    required int completedBooks,
    required int readingBooks,
    required int completionRate,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '완독 진행 상태 🎯',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    if (completedBooks > 0)
                      Expanded(
                        flex: completedBooks,
                        child: Container(color: AppTheme.successColor),
                      ),
                    if (readingBooks > 0)
                      Expanded(
                        flex: readingBooks,
                        child: Container(color: AppTheme.primaryColor),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '완독 $completedBooks권 ($completionRate%)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '읽는 중 $readingBooks권 (${100 - completionRate}%)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReadingChart(List<Book> books) {
    // 지난 6개월간의 월별 완독 권수 집계
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return d;
    });

    final counts = months.map((month) {
      return books.where((b) {
        if (!b.isCompleted) return false;
        final targetDate = b.completedAt ?? b.createdAt;
        return targetDate.year == month.year && targetDate.month == month.month;
      }).length;
    }).toList();

    final maxCount =
        counts.fold<int>(1, (max, c) => c > max ? c : max).clamp(1, 999);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  '최근 6개월 완독 추이 📈',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 155,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) {
                  final month = months[index];
                  final count = counts[index];
                  final monthLabel = DateFormat('M월').format(month);
                  final ratio = count / maxCount;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count > 0 ? '$count권' : '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: (85 * (ratio > 0 ? ratio : 0.05)).toDouble(),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: count > 0
                                  ? [
                                      AppTheme.primaryLight,
                                      AppTheme.primaryColor
                                    ]
                                  : [
                                      AppTheme.borderColor,
                                      AppTheme.borderColor
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: index == 5
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: index == 5
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
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

  Widget _buildTopRatedBooksCard(BuildContext context, List<Book> books) {
    final topBooks = books.where((b) => b.rating >= 4.0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    if (topBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  '인생 도서 & 높은 평점 🏆',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...topBooks.take(3).map((book) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailScreen(bookId: book.id),
                    ),
                  );
                },
                leading: Container(
                  width: 40,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(book.coverUrl!, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.menu_book_rounded,
                              size: 20,
                              color: AppTheme.primaryLight))
                      : const Icon(Icons.menu_book_rounded,
                          size: 20, color: AppTheme.primaryLight),
                ),
                title: Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  book.author,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppTheme.accentColor, size: 18),
                    const SizedBox(width: 2),
                    Text(
                      book.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
