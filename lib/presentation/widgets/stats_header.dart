import "package:flutter/material.dart";
import "../../data/models/book_model.dart";

class StatsHeader extends StatelessWidget {
  final List<Book> books;

  const StatsHeader({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    final totalBooks = books.length;
    final readingBooks = books.where((b) => !b.isCompleted).length;
    final completedBooks = books.where((b) => b.isCompleted).length;
    final completionRate =
        totalBooks > 0 ? ((completedBooks / totalBooks) * 100).toInt() : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
            color: const Color(0xFF382B6E).withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // 앰비언트 글로우 데코
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC084FC).withValues(alpha: 0.32),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 타이틀 & 뱃지
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_stories_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "나의 독서 여정",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            totalBooks > 0
                                ? "총 $totalBooks권 중 $completedBooks권을 완독했어요 ✨"
                                : "첫 도서를 등록하고 나만의 서재를 가꿔보세요",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bookmark_added_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "전체 $totalBooks권",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 중앙 3대 지표 (읽는 중 / 완독 / 완독률)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStatItem(
                            label: "읽는 중",
                            number: "$readingBooks",
                            unit: "권",
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFFDE047),
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            label: "완독",
                            number: "$completedBooks",
                            unit: "권",
                            icon: Icons.check_circle_rounded,
                            iconColor: const Color(0xFF86EFAC),
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            label: "완독률",
                            number: "$completionRate",
                            unit: "%",
                            icon: Icons.pie_chart_rounded,
                            iconColor: const Color(0xFFC4B5FD),
                          ),
                        ],
                      ),
                      if (totalBooks > 0) ...[
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (completedBooks / totalBooks)
                                  .clamp(0.0, 1.0),
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF86EFAC),
                                      Color(0xFF34D399),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: completedBooks > 0
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF34D399)
                                                .withValues(alpha: 0.45),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStatItem({
    required String label,
    required String number,
    required String unit,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 17,
                height: 17,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 10.5, color: iconColor),
              ),
              const SizedBox(width: 4.5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}
