import 'package:flutter/material.dart';

import '../app_colors.dart';

class AppTheme {
  const AppTheme._();

  /// Latin comes from the default face; these carry the Khmer glyphs.
  ///
  /// Kantumruy Pro is bundled (see pubspec.yaml) so Khmer renders on the first
  /// frame instead of appearing as empty boxes until a fallback font has been
  /// fetched. It must not be the primary family: its charset is Khmer plus
  /// punctuation, with no Latin letters, so making it primary would leave every
  /// English word to resolve through fallback.
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
      fontFamilyFallback: fontFallback,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cyan,
        brightness: Brightness.dark,
      ),
    );
  }
}
