import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import '../../screens/book_detail_screen.dart';

/// 5. 인생 도서 & 높은 평점 카드 (평점 4.0 이상 상위 5권)
class StatsTopRatedBooksCard extends StatelessWidget {
  final List<Book> books;

  const StatsTopRatedBooksCard({
    super.key,
    required this.books,
  });

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
                  ? (book.coverUrl!.startsWith('http://') ||
                          book.coverUrl!.startsWith('https://')
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
                      : Image.file(
                          File(book.coverUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.menu_book_rounded,
                            size: 16,
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor,
                          ),
                        ))
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
}
