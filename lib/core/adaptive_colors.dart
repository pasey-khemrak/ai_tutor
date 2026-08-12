import 'package:flutter/material.dart';

import 'app_colors.dart';

class AdaptiveColors {
  const AdaptiveColors._();

  static bool isLight(BuildContext context) {
    return false;
  }

  static Color text(BuildContext context) {
    return isLight(context) ? const Color(0xFF172033) : AppColors.text;
  }

  static Color subtle(BuildContext context) {
    return isLight(context) ? const Color(0xFF3C465D) : AppColors.subtle;
  }

  static Color muted(BuildContext context) {
    return isLight(context) ? const Color(0xFF69738A) : AppColors.muted;
  }

  static Color panel(BuildContext context) {
    return isLight(context) ? Colors.white : AppColors.panel;
  }

  static Color card(BuildContext context) {
    return isLight(context) ? Colors.white : AppColors.card;
  }

  static Color line(BuildContext context) {
    return isLight(context) ? const Color(0xFFD8DEEC) : AppColors.line;
  }

  static Color controlFill(BuildContext context) {
    return isLight(context) ? const Color(0xFFF0F4FA) : AppColors.panel;
  }
}
