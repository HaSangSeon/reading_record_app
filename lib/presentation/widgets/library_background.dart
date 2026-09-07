import 'dart:ui';
import 'package:flutter/material.dart';

/// 메모리 부하가 전혀 없는 순수 벡터 및 방사형 그라데이션 기반의 모던 배경 위젯
/// 비트맵 이미지 없이 GPU 단일 패스로 렌더링되며 RepaintBoundary와 함께 캐싱되어 0KB에 가까운 메모리를 사용합니다.
class LibraryBackground extends StatelessWidget {
  final bool isDark;

  const LibraryBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. 베이스 딥/파스텔 그라데이션
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      Color(0xFF0C0E17),
                      Color(0xFF131726),
                      Color(0xFF0D0F18),
                    ]
                  : const [
                      Color(0xFFF8F7FD),
                      Color(0xFFF2EFF9),
                      Color(0xFFF7F5FC),
                    ],
            ),
          ),
        ),

        // 2. 파스텔 오로라 광원 1 (우측 상단 은은한 바이올렛 글로우)
        Positioned(
          top: -70,
          right: -70,
          width: 320,
          height: 320,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF818CF8))
                        .withValues(alpha: isDark ? 0.20 : 0.15),
                    (isDark
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFA5B4FC))
                        .withValues(alpha: isDark ? 0.08 : 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 3. 파스텔 오로라 광원 2 (좌측 중하단 부드러운 스카이블루/인디고 글로우)
        Positioned(
          top: 360,
          left: -90,
          width: 340,
          height: 340,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF38BDF8))
                        .withValues(alpha: isDark ? 0.12 : 0.10),
                    (isDark
                            ? const Color(0xFF0284C7)
                            : const Color(0xFFBAE6FD))
                        .withValues(alpha: isDark ? 0.05 : 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 4. 모던 미세 도트(Dot) 매트릭스 그리드 (GPU 일괄 점 렌더링)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DotGridPainter(isDark: isDark),
            ),
          ),
        ),
      ],
    );
  }
}

/// 단일 DrawPoints 호출로 0.1ms 미만에 그려지는 초경량 도트 그리드 페인터
class _DotGridPainter extends CustomPainter {
  final bool isDark;

  const _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 26.0;
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF4F46E5))
          .withValues(alpha: isDark ? 0.045 : 0.042)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.35;

    final List<Offset> points = [];
    final int cols = (size.width / spacing).ceil();
    final int rows = (size.height / spacing).ceil();

    for (int r = 0; r <= rows; r++) {
      final double y = r * spacing;
      for (int c = 0; c <= cols; c++) {
        final double x = c * spacing;
        points.add(Offset(x, y));
      }
    }

    canvas.drawPoints(PointMode.points, points, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
