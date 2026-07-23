import 'dart:ui';

import 'package:flutter/material.dart';

import 'auth_footer.dart';
import 'auth_form_screen.dart';
import 'brand_intro_page.dart';
import 'clarity_intro_page.dart';
import 'learning_intro_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openAuthForm() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AuthFormScreen(initialIsSignUp: false),
      ),
    );
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _openAuthForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF080D19),
              Color(0xFF09101E),
              Color(0xFF10112A),
              Color(0xFF171342),
            ],
            stops: [0, .46, .74, 1],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _AuthBlurCircles(),
              PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _page = value),
                children: const [
                  BrandIntroPage(),
                  LearningIntroPage(),
                  ClarityIntroPage(),
                ],
              ),
              Positioned(
                left: 26,
                right: 26,
                bottom: 20,
                child: AuthFooter(page: _page, onNext: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthBlurCircles extends StatelessWidget {
  const _AuthBlurCircles();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _BlurCircle(
              diameter: 340,
              blur: 92,
              color: Color(0xFF2F4DFF),
              opacity: .26,
              right: -24,
              topFactor: .28,
            ),
            _BlurCircle(
              diameter: 280,
              blur: 78,
              color: Color(0xFF0B7E93),
              opacity: .24,
              left: -150,
              topFactor: .56,
            ),
            _BlurCircle(
              diameter: 300,
              blur: 82,
              color: Color(0xFF6F3CFF),
              opacity: .3,
              right: -132,
              topFactor: .65,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({
    required this.diameter,
    required this.blur,
    required this.color,
    required this.opacity,
    this.left,
    this.right,
    this.topFactor,
  });

  final double diameter;
  final double blur;
  final Color color;
  final double opacity;
  final double? left;
  final double? right;
  final double? topFactor;

  @override
  Widget build(BuildContext context) {
    final top = topFactor == null
        ? null
        : MediaQuery.sizeOf(context).height * topFactor! - diameter / 2;

    return Positioned(
      left: left,
      right: right,
      top: top,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * .58),
                color.withValues(alpha: 0),
              ],
              stops: const [0, .58, 1],
            ),
          ),
        ),
      ),
    );
  }
}
