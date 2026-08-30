import 'package:flutter/material.dart';
import '../../data/models/book_model.dart';

class StatsHeader extends StatelessWidget {
  final List<Book> books;

  const StatsHeader({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    final totalBooks = books.length;
    final readingBooks = books.where((b) => !b.isCompleted).length;
    final completedBooks = books.where((b) => b.isCompleted).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF382B6E), // Deep Royal Violet
            Color(0xFF4C3A93), // Royal Violet-Indigo
            Color(0xFF5E49B4), // Vivid Violet
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF818CF8).withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C3A93).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. 우측 상단 맑고 연한 라벤더-바이올렛 앰비언트 글로우 구체
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFD8B4FE,
                    ).withValues(alpha: 0.45), // 연한 파스텔 라벤더 코어
                    const Color(0xFFA855F7).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                  stops: const [0.1, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // 2. 우측 상단 미니 하이라이트 원형 데코
          Positioned(
            right: 22,
            top: 14,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE9D5FF).withValues(alpha: 0.22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
            ),
          ),
          // 3. 좌측 하단 보조 글로우 원
          Positioned(
            left: 30,
            bottom: -35,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF818CF8).withValues(alpha: 0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.auto_stories_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '나의 독서 여정',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            totalBooks > 0
                                ? '총 $totalBooks권 중 $completedBooks권을 완독했어요 ✨'
                                : '첫 도서를 등록하고 나만의 서재를 가꿔보세요',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bookmark_added_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '총 $totalBooks권',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '읽는 중',
                        '$readingBooks권',
                        Icons.local_fire_department_rounded,
                        const Color(0xFFFBBF24),
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        '완독 완료',
                        '$completedBooks권',
                        Icons.check_circle_rounded,
                        const Color(0xFF34D399),
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        '완독률',
                        '${totalBooks > 0 ? (completedBooks / totalBooks * 100).toInt() : 0}%',
                        Icons.auto_awesome_rounded,
                        const Color(0xFFA5B4FC),
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

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}
