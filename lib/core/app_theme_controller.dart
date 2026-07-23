import 'package:flutter/material.dart';

class AppThemeController {
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static void setDarkMode(bool enabled) {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
