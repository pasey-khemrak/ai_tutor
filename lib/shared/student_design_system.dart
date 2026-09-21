import 'package:flutter/material.dart';

import '../core/adaptive_colors.dart';
import '../core/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';

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

/// Text and surface styles shared by the student Home and Tutor screens so
/// both read as one product in light and dark themes.
abstract final class StudentStyle {
  static TextStyle title(BuildContext context, double size) => TextStyle(
    color: AdaptiveColors.text(context),
    fontSize: size,
    height: 1.3,
    fontWeight: FontWeight.w800,
    letterSpacing: -.3,
    fontFamilyFallback: AppTheme.fontFallback,
  );

  static TextStyle body(BuildContext context, {double size = 13, Color? color}) => TextStyle(
    color: color ?? AdaptiveColors.muted(context),
    fontSize: size,
    height: 1.45,
    fontWeight: FontWeight.w500,
    fontFamilyFallback: AppTheme.fontFallback,
  );

  static BoxDecoration card(BuildContext context, {Color? accent}) {
    final light = AdaptiveColors.isLight(context);
    return BoxDecoration(
      color: AdaptiveColors.card(context),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accent?.withValues(alpha: light ? .35 : .4) ?? AdaptiveColors.line(context),
      ),
      boxShadow: light
          ? [
              BoxShadow(
                color: const Color(0xFF1B2A55).withValues(alpha: .06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );
  }
}

/// Colour and icon identity for a subject, matched on English or Khmer names.
({Color color, IconData icon}) subjectVisual(String subject) {
  final key = subject.toLowerCase();
  if (key.contains('phys') || key.contains('រូប')) {
    return (color: const Color(0xFFF59E0B), icon: Icons.speed_rounded);
  }
  if (key.contains('chem') || key.contains('គីមី')) {
    return (color: const Color(0xFF10B981), icon: Icons.science_rounded);
  }
  if (key.contains('math') || key.contains('គណិត')) {
    return (color: const Color(0xFF5B6CFF), icon: Icons.functions_rounded);
  }
  return (color: AppColors.cyan, icon: Icons.auto_stories_rounded);
}

/// The backend sends English subject names; show the student's language.
String localizedSubjectName(AppLocalizations l10n, String subject) {
  final key = subject.toLowerCase();
  if (key.startsWith('math')) return l10n.subjectMath;
  if (key.startsWith('phys')) return l10n.subjectPhysics;
  if (key.startsWith('chem')) return l10n.subjectChemistry;
  return subject;
}

/// Selectable filter pill used for grade and subject filters.
class StudentFilterChip extends StatelessWidget {
  const StudentFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
    this.count,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.cyan;
    final light = AdaptiveColors.isLight(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? accent.withValues(alpha: light ? .14 : .18) : AdaptiveColors.card(context),
        shape: StadiumBorder(
          side: BorderSide(color: selected ? accent : AdaptiveColors.line(context)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: AdaptiveColors.text(context),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).number(count!),
                      style: TextStyle(
                        color: AdaptiveColors.muted(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small status or metadata label.
class StudentPill extends StatelessWidget {
  const StudentPill({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Section heading used across student tabs: optional icon, title, and an
/// optional trailing action such as "Browse topics".
class StudentSectionHeader extends StatelessWidget {
  const StudentSectionHeader(this.title, {super.key, this.icon, this.action});
  final String title;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AdaptiveColors.muted(context)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: StudentStyle.title(context, 17)),
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// One number in a row of learning stats (streak, mastered, practice done).
class StudentStatTile extends StatelessWidget {
  const StudentStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.caption,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: StudentStyle.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: StudentStyle.title(context, 22)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AdaptiveColors.subtle(context),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: StudentStyle.body(context, size: 11),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Equal-height stat tiles in a row; stacked on very narrow screens.
class StudentStatRow extends StatelessWidget {
  const StudentStatRow({super.key, required this.tiles});
  final List<StudentStatTile> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 330) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              tiles[i],
            ],
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      );
    },
  );
}
