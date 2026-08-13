import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import 'auth_footer.dart';
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
    Navigator.of(context).pushReplacementNamed(AppRoutes.signIn);
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
