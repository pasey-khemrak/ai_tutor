import 'package:flutter/material.dart';

import '../app_colors.dart';

class AppTheme {
  const AppTheme._();

  static const fontFallback = ['Kantumruy Pro', 'Noto Sans Khmer', 'sans-serif'];

  static const textTheme = TextTheme(
    displayLarge: TextStyle(height: 1.45, fontFamilyFallback: fontFallback),
    displayMedium: TextStyle(height: 1.45, fontFamilyFallback: fontFallback),
    displaySmall: TextStyle(height: 1.45, fontFamilyFallback: fontFallback),
    headlineLarge: TextStyle(height: 1.45, fontFamilyFallback: fontFallback),
    headlineMedium: TextStyle(height: 1.45, fontFamilyFallback: fontFallback),
    headlineSmall: TextStyle(height: 1.45, fontFamilyFallback: fontFallback),
    titleLarge: TextStyle(height: 1.40, fontWeight: FontWeight.w700, fontFamilyFallback: fontFallback),
    titleMedium: TextStyle(height: 1.40, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallback),
    titleSmall: TextStyle(height: 1.35, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallback),
    bodyLarge: TextStyle(height: 1.50, fontFamilyFallback: fontFallback),
    bodyMedium: TextStyle(height: 1.45, fontFamilyFallback: fontFallback),
    bodySmall: TextStyle(height: 1.40, fontFamilyFallback: fontFallback),
    labelLarge: TextStyle(height: 1.35, fontFamilyFallback: fontFallback),
    labelMedium: TextStyle(height: 1.30, fontFamilyFallback: fontFallback),
    labelSmall: TextStyle(height: 1.30, fontFamilyFallback: fontFallback),
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      fontFamily: 'Kantumruy Pro',
      fontFamilyFallback: fontFallback,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Kantumruy Pro',
      fontFamilyFallback: fontFallback,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cyan,
        brightness: Brightness.dark,
      ),
    );
  }
}
