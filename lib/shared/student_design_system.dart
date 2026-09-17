import 'package:flutter/material.dart';

import '../core/adaptive_colors.dart';
import '../core/app_colors.dart';

/// Shared, deliberately small presentation vocabulary for student surfaces.
/// It keeps dashboard, catalog, and tutor entry screens visually related while
/// allowing the specialised live board to retain its own rendering system.
abstract final class StudentSpace {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pageMaxWidth = 1080;
  static const double readableWidth = 760;
}

abstract final class StudentRadius {
  static const BorderRadius card = BorderRadius.all(Radius.circular(24));
  static const BorderRadius control = BorderRadius.all(Radius.circular(18));
}

class StudentPage extends StatelessWidget {
  const StudentPage({
    super.key,
    required this.child,
    this.maxWidth = StudentSpace.pageMaxWidth,
  });
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth >= 900
          ? StudentSpace.xl
          : StudentSpace.lg;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          StudentSpace.lg,
          horizontal,
          StudentSpace.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      );
    },
  );
}

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(StudentSpace.lg),
  });
  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AdaptiveColors.isLight(context) ? Colors.white : AppColors.card,
      borderRadius: StudentRadius.card,
      border: Border.all(
        color: (accent ?? AppColors.line).withValues(
          alpha: accent == null ? 1 : .45,
        ),
      ),
    ),
    child: child,
  );
}

class StudentSectionTitle extends StatelessWidget {
  const StudentSectionTitle(this.text, {super.key, this.action});
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: AdaptiveColors.text(context),
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
      ),
      ?action,
    ],
  );
}
