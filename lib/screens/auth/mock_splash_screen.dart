import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'auth_screen.dart';

class MockSplashScreen extends StatefulWidget {
  const MockSplashScreen({super.key});

  @override
  State<MockSplashScreen> createState() => _MockSplashScreenState();
}

class _MockSplashScreenState extends State<MockSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: AppColors.backgroundDecoration,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(
                image: AssetImage('assets/images/ai_tutor_logo.png'),
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 18),
              Text(
                'REAN AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Checking your session...',
                style: TextStyle(
                  color: Color(0xFF96A0CF),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
