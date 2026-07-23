import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme_controller.dart';
import '../screens/auth/auth_screen.dart';

class AiTutorApp extends StatelessWidget {
  const AiTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AI Tutor',
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F7FB),
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.blue,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
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
      },
    );
  }
}
