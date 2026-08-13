import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0B0F1B);
  static const lightBackground = Color(0xFFF6F8FF);
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF080D19),
      Color(0xFF09101E),
      Color(0xFF10112A),
      Color(0xFF171342),
    ],
    stops: [0, .46, .74, 1],
  );
  static const lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8FAFF),
      Color(0xFFF4F7FF),
      Color(0xFFEFF4FF),
      Color(0xFFEAF0FF),
    ],
    stops: [0, .46, .74, 1],
  );
  static const backgroundDecoration = BoxDecoration(
    gradient: backgroundGradient,
  );
  static const lightBackgroundDecoration = BoxDecoration(
    gradient: lightBackgroundGradient,
  );

  static BoxDecoration backgroundDecorationFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lightBackgroundDecoration
        : backgroundDecoration;
  }

  static const panel = Color(0xFF111623);
  static const card = Color(0xFF191E32);
  static const answer = Color(0xFF282C3B);
  static const cyan = Color(0xFF12DDF5);
  static const blue = Color(0xFF4057FF);
  static const peach = Color(0xFFFFAAA4);
  static const text = Color(0xFFDDE0EC);
  static const subtle = Color(0xFFCED1DE);
  static const muted = Color(0xFFA7ABBA);
  static const line = Color(0xFF2C3145);
}
