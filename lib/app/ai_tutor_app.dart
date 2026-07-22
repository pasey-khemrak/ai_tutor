import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/auth/auth_screen.dart';

class AiTutorApp extends StatelessWidget {
  const AiTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Tutor',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthScreen(),
    );
  }
}
