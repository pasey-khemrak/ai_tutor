import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'learning_intro_page.dart';

class ClarityIntroPage extends StatelessWidget {
  const ClarityIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final artSize = (constraints.maxWidth * .7).clamp(240.0, 306.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 106),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: artSize,
                    height: artSize,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        LearningRing(size: artSize),
                        Container(
                          width: artSize * .52,
                          height: artSize * .52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF0B1121,
                            ).withValues(alpha: .6),
                          ),
                        ),
                        _BulbMark(size: artSize * .27),
                        const Positioned(
                          top: 10,
                          left: -18,
                          child: AnimatedIntroChip(
                            delay: Duration(milliseconds: 80),
                            floatOffset: 5,
                            child: _InsightChip(label: 'Instant answers'),
                          ),
                        ),
                        const Positioned(
                          top: 62,
                          right: -24,
                          child: AnimatedIntroChip(
                            delay: Duration(milliseconds: 260),
                            floatOffset: 4,
                            child: _InsightChip(label: 'Any subject'),
                          ),
                        ),
                        const Positioned(
                          right: -34,
                          bottom: 44,
                          child: AnimatedIntroChip(
                            delay: Duration(milliseconds: 440),
                            floatOffset: 6,
                            child: _InsightChip(label: 'Step by step'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const FeatureBadge(label: 'INTERACTIVE'),
              const SizedBox(height: 18),
              const Text(
                'Ask anything,\nget clarity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'From Math to Physic, to chemistry -\nget clear, step-by-step explanation in seconds.',
                style: TextStyle(
                  color: const Color(0xFF96A0CF).withValues(alpha: .8),
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF080C18).withValues(alpha: .95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '%',
            style: TextStyle(
              color: Color(0xFFDDE4FF),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFDDE4FF),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulbMark extends StatelessWidget {
  const _BulbMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: const Color(0xFF63A4FF),
            size: size,
          ),
          Positioned.fill(child: CustomPaint(painter: _BulbRayPainter())),
        ],
      ),
    );
  }
}

class _BulbRayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue.withValues(alpha: .62)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final rays = <(Offset, Offset)>[
      (Offset(center.dx, 0), Offset(center.dx, size.height * .11)),
      (Offset(center.dx, size.height), Offset(center.dx, size.height * .89)),
      (Offset(0, center.dy), Offset(size.width * .11, center.dy)),
      (Offset(size.width, center.dy), Offset(size.width * .89, center.dy)),
      (
        Offset(size.width * .14, size.height * .14),
        Offset(size.width * .24, size.height * .24),
      ),
      (
        Offset(size.width * .86, size.height * .14),
        Offset(size.width * .76, size.height * .24),
      ),
    ];

    for (final ray in rays) {
      canvas.drawLine(ray.$1, ray.$2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
