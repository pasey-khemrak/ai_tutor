import 'package:flutter/material.dart';

class AppThemeController {
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static bool get isDarkMode => themeMode.value != ThemeMode.light;

  static void setDarkMode(bool enabled) {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
