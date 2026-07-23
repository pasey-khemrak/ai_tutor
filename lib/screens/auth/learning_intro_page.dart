import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class LearningIntroPage extends StatelessWidget {
  const LearningIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final artSize = (constraints.maxWidth * .68).clamp(238.0, 300.0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 106),
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
                            gradient: RadialGradient(
                              colors: [
                                AppColors.blue.withValues(alpha: .2),
                                AppColors.blue.withValues(alpha: .03),
                              ],
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/ai_tutor_brain.png',
                          width: artSize * .32,
                          fit: BoxFit.contain,
                        ),
                        const Positioned(
                          top: 18,
                          left: -18,
                          child: AnimatedIntroChip(
                            delay: Duration(milliseconds: 80),
                            floatOffset: 5,
                            child: SubjectChip(
                              label: 'Mathematic',
                              icon: Icons.calculate_rounded,
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 60,
                          right: -28,
                          child: AnimatedIntroChip(
                            delay: Duration(milliseconds: 260),
                            floatOffset: 4,
                            child: SubjectChip(
                              label: 'English',
                              icon: Icons.translate_rounded,
                            ),
                          ),
                        ),
                        const Positioned(
                          right: -18,
                          bottom: 42,
                          child: AnimatedIntroChip(
                            delay: Duration(milliseconds: 440),
                            floatOffset: 6,
                            child: SubjectChip(
                              label: 'Physic',
                              icon: Icons.science_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const FeatureBadge(),
              const SizedBox(height: 18),
              const Text(
                'Learn at your\nown pace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rean adapts to your learning style, difficulty level, and schedule - creating a unique path just for you.',
                style: TextStyle(
                  color: const Color(0xFF96A0CF).withValues(alpha: .78),
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

class AnimatedIntroChip extends StatefulWidget {
  const AnimatedIntroChip({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.floatOffset = 5,
  });

  final Widget child;
  final Duration delay;
  final double floatOffset;

  @override
  State<AnimatedIntroChip> createState() => _AnimatedIntroChipState();
}

class _AnimatedIntroChipState extends State<AnimatedIntroChip>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _floatController]),
      child: widget.child,
      builder: (context, child) {
        final wave = math.sin(_floatController.value * math.pi * 2);
        return Opacity(
          opacity: _entranceController.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(
              0,
              (1 - _entrance.value) * 12 + wave * widget.floatOffset,
            ),
            child: Transform.scale(
              scale: .88 + _entrance.value * .12,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class LearningRing extends StatelessWidget {
  const LearningRing({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final scale in const [.98, .68])
          Container(
            width: size * scale,
            height: size * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.blue.withValues(alpha: .82),
                width: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class SubjectChip extends StatelessWidget {
  const SubjectChip({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF090D19).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFB7C5FF), size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFDDE4FF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureBadge extends StatelessWidget {
  const FeatureBadge({super.key, this.label = 'PERSONALISED'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ai_tutor_light.png',
            width: 12,
            height: 12,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF8BA0FF),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
