import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController {
  AppLanguageController._();

  static const String preferenceKey = 'app_language_code';

  static final currentLocale = ValueNotifier<Locale>(const Locale('km'));

  static bool get isKhmer => currentLocale.value.languageCode == 'km';

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(preferenceKey);
      if (code != null && (code == 'km' || code == 'en')) {
        currentLocale.value = Locale(code);
      } else {
        // Default to Khmer
        currentLocale.value = const Locale('km');
      }
    } catch (_) {
      currentLocale.value = const Locale('km');
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    final code = languageCode == 'en' ? 'en' : 'km';
    currentLocale.value = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(preferenceKey, code);
    } catch (_) {}
  }

  static Future<void> toggleLanguage() async {
    final next = isKhmer ? 'en' : 'km';
    await setLanguage(next);
  }
}
