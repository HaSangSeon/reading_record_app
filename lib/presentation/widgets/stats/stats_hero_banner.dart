import 'package:flutter/material.dart';

/// 1. 나의 독서 인사이트 핵심 요약 Hero 배너
class StatsHeroInsightBanner extends StatelessWidget {
  final int totalBooks;
  final int completedBooks;
  final int readingBooks;
  final int completionRate;
  final Animation<double> barAnim;

  const StatsHeroInsightBanner({
    super.key,
    required this.totalBooks,
    required this.completedBooks,
    required this.readingBooks,
    required this.completionRate,
    required this.barAnim,
  });

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

  @override
  Widget build(BuildContext context) {
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
                        animation: barAnim,
                        builder: (context, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: totalBooks > 0
                                  ? (completedBooks / totalBooks) *
                                      barAnim.value
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
}
