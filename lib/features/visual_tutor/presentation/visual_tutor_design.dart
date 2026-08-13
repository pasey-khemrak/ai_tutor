import 'package:flutter/material.dart';

class VisualTutorColors {
  const VisualTutorColors._();

  static const shell = Color(0xFF07101E);
  static const shellElevated = Color(0xFF0D1728);
  static const panel = Color(0xFF121D2D);
  static const panelRaised = Color(0xFF1A2638);
  static const card = Color(0xFF182337);
  static const border = Color(0xFF2C3A50);
  static const text = Color(0xFFEAF0F8);
  static const textMuted = Color(0xFF9DAABE);
  static const textSubtle = Color(0xFFB9C4D2);
  static const darkButton = Color(0xFF050B14);
  static const welcomePanel = Color(0xFF082438);

  static const cyan = Color(0xFF16E5F4);
  static const cyanDark = Color(0xFF075D6B);
  static const blueInk = Color(0xFF2E74FF);
  static const blackInk = Color(0xFF14110B);
  static const redInk = Color(0xFFFF4A5F);
  static const mistakeRed = Color(0xFFE94A55);
  static const success = Color(0xFF35D47B);
  static const orange = Color(0xFFFFA20D);
  static const yellowHighlight = Color(0xFFFFE88A);

  static const boardPaper = Color(0xFFFFFBF1);
  static const boardPaperLine = Color(0xFFE8DEC8);
  static const boardPaperDot = Color(0xFFEFE6D4);
  static const boardBorder = Color(0xFFE2D3B7);
  static const boardTextMuted = Color(0xFF647087);
  static const boardTextDark = Color(0xFF253044);

  static const scanIconBackground = Color(0xFF063B45);
  static const typeIconBackground = Color(0xFF2E1D52);
  static const voiceIconBackground = Color(0xFF06372F);

  // ── Redesign tokens ────────────────────────────────────────────────────────
  static const presenceBarBg = Color(0xFF0D1117);
  static const bottomSheetBg = Color(0xFF0D1117);
  static const multiChoiceCard = Color(0xFF1A2333);
  static const multiChoiceCardSelected = Color(0xFF0E3A5C);
  static const speechPanelBg = Color(0xFF1E2632);
  static const finalResultBg = Color(0xFF050B14);
  static const summaryCardBg = Color(0xFF111827);
  static const verifiedChipBg = Color(0xFF063B45);
}

class VisualTutorSpacing {
  const VisualTutorSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const screen = 18.0;
}

class VisualTutorRadius {
  const VisualTutorRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
  static const board = 26.0;
  static const pill = 999.0;
}

class VisualTutorTypography {
  const VisualTutorTypography._();

  static const fontFallback = ['Noto Sans Khmer', 'Kantumruy Pro', 'Arial'];

  static const header = TextStyle(
    color: VisualTutorColors.text,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    height: 1.15,
    fontFamilyFallback: fontFallback,
  );

  static const sectionTitle = TextStyle(
    color: VisualTutorColors.text,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    height: 1.2,
    fontFamilyFallback: fontFallback,
  );

  static const welcomeTitle = TextStyle(
    color: VisualTutorColors.text,
    fontSize: 25,
    fontWeight: FontWeight.w900,
    height: 1.1,
    fontFamilyFallback: fontFallback,
  );

  static const cardTitle = TextStyle(
    color: VisualTutorColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1.25,
    fontFamilyFallback: fontFallback,
  );

  static const khmerSubtitle = TextStyle(
    color: VisualTutorColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.35,
    fontFamilyFallback: fontFallback,
  );

  static const tutorSpeech = TextStyle(
    color: VisualTutorColors.text,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.45,
    fontStyle: FontStyle.italic,
    fontFamilyFallback: fontFallback,
  );

  static const studentTask = TextStyle(
    color: VisualTutorColors.text,
    fontSize: 15,
    fontWeight: FontWeight.w900,
    height: 1.35,
    fontFamilyFallback: fontFallback,
  );

  static const boardEquation = TextStyle(
    color: VisualTutorColors.blackInk,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.1,
    fontFamilyFallback: fontFallback,
  );

  static const boardHandwriting = TextStyle(
    color: VisualTutorColors.blueInk,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    height: 1.15,
    fontStyle: FontStyle.italic,
    fontFamilyFallback: fontFallback,
  );

  static const quickAction = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    fontFamilyFallback: fontFallback,
  );

  static const statusChip = TextStyle(
    color: VisualTutorColors.cyan,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    height: 1.1,
    fontFamilyFallback: fontFallback,
  );

  static const boardSupportingText = TextStyle(
    color: VisualTutorColors.boardTextMuted,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.45,
    fontFamilyFallback: fontFallback,
  );

  // ── Redesign additions ─────────────────────────────────────────────────────
  static const multiChoiceLabel = TextStyle(
    color: VisualTutorColors.cyan,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.1,
    fontFamilyFallback: fontFallback,
  );

  static const multiChoiceAnswer = TextStyle(
    color: VisualTutorColors.text,
    fontSize: 17,
    fontWeight: FontWeight.w900,
    height: 1.2,
    fontFamilyFallback: fontFallback,
  );

  static const presenceTitle = TextStyle(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.w900,
    height: 1.1,
    fontFamilyFallback: fontFallback,
  );

  static const presenceStatus = TextStyle(
    color: VisualTutorColors.cyan,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFamilyFallback: fontFallback,
  );

  static const finalResultLabel = TextStyle(
    color: VisualTutorColors.cyan,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    fontFamilyFallback: fontFallback,
  );

  static const finalResultEquation = TextStyle(
    color: VisualTutorColors.cyan,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    height: 1.15,
    fontFamilyFallback: fontFallback,
  );

  static const summaryLabel = TextStyle(
    color: VisualTutorColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    fontFamilyFallback: fontFallback,
  );

  static const summaryText = TextStyle(
    color: VisualTutorColors.textSubtle,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.4,
    fontFamilyFallback: fontFallback,
  );

  static const masteryPraise = TextStyle(
    color: VisualTutorColors.blueInk,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    height: 1.35,
    fontFamilyFallback: fontFallback,
  );
}

class VisualTutorShadows {
  const VisualTutorShadows._();

  static List<BoxShadow> get softPanel => [
    BoxShadow(
      color: Colors.black.withValues(alpha: .24),
      blurRadius: 22,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> get cyanGlow => [
    BoxShadow(
      color: VisualTutorColors.cyan.withValues(alpha: .36),
      blurRadius: 24,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cyanGlowStrong => [
    BoxShadow(
      color: VisualTutorColors.cyan.withValues(alpha: .52),
      blurRadius: 32,
      spreadRadius: 4,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> get orangeGlow => [
    BoxShadow(
      color: VisualTutorColors.orange.withValues(alpha: .28),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get cardRaise => [
    BoxShadow(
      color: Colors.black.withValues(alpha: .32),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

class VisualTutorDecorations {
  const VisualTutorDecorations._();

  static BoxDecoration panel({double radius = VisualTutorRadius.xl}) {
    return BoxDecoration(
      color: VisualTutorColors.panel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: VisualTutorColors.border),
      boxShadow: VisualTutorShadows.softPanel,
    );
  }

  static BoxDecoration raisedPanel({double radius = VisualTutorRadius.xl}) {
    return BoxDecoration(
      color: VisualTutorColors.panelRaised,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: VisualTutorColors.border.withValues(alpha: .8)),
    );
  }

  static BoxDecoration welcomePanel() {
    return BoxDecoration(
      color: VisualTutorColors.welcomePanel,
      borderRadius: BorderRadius.circular(VisualTutorRadius.board),
      border: Border.all(color: VisualTutorColors.cyan.withValues(alpha: .18)),
    );
  }

  static BoxDecoration actionCard({double radius = VisualTutorRadius.xl}) {
    return raisedPanel(radius: radius);
  }

  static BoxDecoration iconTile(Color background) {
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(VisualTutorRadius.md),
    );
  }

  static BoxDecoration stuckCard() {
    return BoxDecoration(
      color: VisualTutorColors.orange,
      borderRadius: BorderRadius.circular(VisualTutorRadius.xl),
      boxShadow: VisualTutorShadows.orangeGlow,
    );
  }

  static BoxDecoration statusChip({Color color = VisualTutorColors.cyan}) {
    return BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
      border: Border.all(color: color.withValues(alpha: .35)),
    );
  }

  static BoxDecoration errorBanner() {
    return BoxDecoration(
      color: VisualTutorColors.orange.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      border: Border.all(
        color: VisualTutorColors.orange.withValues(alpha: .35),
      ),
    );
  }

  static BoxDecoration subtleStudentMessage() {
    return BoxDecoration(
      color: VisualTutorColors.cyan.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      border: Border.all(color: VisualTutorColors.cyan.withValues(alpha: .25)),
    );
  }

  static BoxDecoration boardPaper({double radius = VisualTutorRadius.board}) {
    return BoxDecoration(
      color: VisualTutorColors.boardPaper,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: VisualTutorColors.boardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  static BoxDecoration softHighlight() {
    return BoxDecoration(
      color: VisualTutorColors.yellowHighlight.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
    );
  }

  // ── Redesign additions ──────────────────────────────────────────────────────

  static BoxDecoration presenceBar() {
    return const BoxDecoration(color: VisualTutorColors.presenceBarBg);
  }

  static BoxDecoration speechPanel() {
    return BoxDecoration(
      color: VisualTutorColors.speechPanelBg,
      borderRadius: BorderRadius.circular(VisualTutorRadius.xl),
      border: Border.all(color: VisualTutorColors.border.withValues(alpha: .6)),
      boxShadow: VisualTutorShadows.cardRaise,
    );
  }

  static BoxDecoration multiChoiceCard({bool selected = false}) {
    return BoxDecoration(
      color: selected
          ? VisualTutorColors.multiChoiceCardSelected
          : VisualTutorColors.multiChoiceCard,
      borderRadius: BorderRadius.circular(VisualTutorRadius.lg),
      border: Border.all(
        color: selected
            ? VisualTutorColors.cyan.withValues(alpha: .7)
            : VisualTutorColors.border,
        width: selected ? 1.5 : 1,
      ),
      boxShadow: selected ? VisualTutorShadows.cyanGlow : null,
    );
  }

  static BoxDecoration quickActionChip({bool active = false}) {
    return BoxDecoration(
      color: active
          ? VisualTutorColors.cyan.withValues(alpha: .14)
          : VisualTutorColors.panelRaised,
      borderRadius: BorderRadius.circular(VisualTutorRadius.lg),
      border: Border.all(
        color: active
            ? VisualTutorColors.cyan.withValues(alpha: .6)
            : VisualTutorColors.border,
        width: active ? 1.5 : 1,
      ),
    );
  }

  static BoxDecoration finalResultBlock() {
    return BoxDecoration(
      color: VisualTutorColors.finalResultBg,
      borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      border: Border.all(
        color: VisualTutorColors.cyan.withValues(alpha: .55),
        width: 1.5,
      ),
    );
  }

  static BoxDecoration summaryCard() {
    return BoxDecoration(
      color: VisualTutorColors.summaryCardBg,
      borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      border: Border.all(color: VisualTutorColors.border.withValues(alpha: .6)),
    );
  }

  static BoxDecoration verifiedChip() {
    return BoxDecoration(
      color: VisualTutorColors.verifiedChipBg,
      borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
      border: Border.all(color: VisualTutorColors.cyan.withValues(alpha: .4)),
    );
  }

  static BoxDecoration interactionInputField() {
    return BoxDecoration(
      color: VisualTutorColors.panel,
      borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
      border: Border.all(color: VisualTutorColors.border.withValues(alpha: .7)),
    );
  }
}

class VisualTutorButtonStyles {
  const VisualTutorButtonStyles._();

  static ButtonStyle primary({bool glow = false}) {
    return FilledButton.styleFrom(
      backgroundColor: VisualTutorColors.cyan,
      foregroundColor: VisualTutorColors.shell,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VisualTutorRadius.lg),
      ),
      textStyle: VisualTutorTypography.quickAction,
    ).copyWith(
      elevation: WidgetStatePropertyAll(glow ? 10 : 0),
      shadowColor: WidgetStatePropertyAll(
        glow
            ? VisualTutorColors.cyan.withValues(alpha: .45)
            : Colors.transparent,
      ),
    );
  }

  static ButtonStyle secondary() {
    return OutlinedButton.styleFrom(
      foregroundColor: VisualTutorColors.cyan,
      side: BorderSide(color: VisualTutorColors.cyan.withValues(alpha: .46)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
      ),
      textStyle: VisualTutorTypography.quickAction,
    );
  }

  static ButtonStyle darkCard() {
    return FilledButton.styleFrom(
      backgroundColor: VisualTutorColors.card,
      foregroundColor: VisualTutorColors.text,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      ),
      textStyle: VisualTutorTypography.quickAction,
    );
  }

  static ButtonStyle stuckCardCta() {
    return FilledButton.styleFrom(
      backgroundColor: VisualTutorColors.darkButton,
      foregroundColor: VisualTutorColors.orange,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      ),
      textStyle: VisualTutorTypography.quickAction,
    );
  }

  static ButtonStyle micFab({bool disabled = false}) {
    return FilledButton.styleFrom(
      padding: EdgeInsets.zero,
      backgroundColor:
          disabled ? VisualTutorColors.textMuted.withValues(alpha: .18) : VisualTutorColors.cyan,
      foregroundColor:
          disabled ? VisualTutorColors.textMuted : VisualTutorColors.shell,
      disabledBackgroundColor: VisualTutorColors.textMuted.withValues(alpha: .12),
      shape: const CircleBorder(),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class VisualTutorPanel extends StatelessWidget {
  const VisualTutorPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VisualTutorSpacing.lg),
    this.radius = VisualTutorRadius.xl,
    this.raised = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: raised
          ? VisualTutorDecorations.raisedPanel(radius: radius)
          : VisualTutorDecorations.panel(radius: radius),
      child: child,
    );
  }
}

class VisualTutorIconTile extends StatelessWidget {
  const VisualTutorIconTile({
    super.key,
    required this.icon,
    this.background = VisualTutorColors.card,
    this.foreground = VisualTutorColors.cyan,
    this.size = 52,
    this.iconSize = 25,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: VisualTutorDecorations.iconTile(background),
      alignment: Alignment.center,
      child: Icon(icon, color: foreground, size: iconSize),
    );
  }
}

class VisualTutorActionCard extends StatelessWidget {
  const VisualTutorActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBackground = VisualTutorColors.card,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VisualTutorRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(VisualTutorSpacing.lg),
          decoration: VisualTutorDecorations.actionCard(),
          child: Row(
            children: [
              VisualTutorIconTile(icon: icon, background: iconBackground),
              const SizedBox(width: VisualTutorSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: VisualTutorTypography.cardTitle),
                    const SizedBox(height: VisualTutorSpacing.xs),
                    Text(subtitle, style: VisualTutorTypography.khmerSubtitle),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: VisualTutorColors.textMuted.withValues(alpha: .7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VisualTutorStatusChip extends StatelessWidget {
  const VisualTutorStatusChip({
    super.key,
    required this.label,
    this.color = VisualTutorColors.cyan,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: VisualTutorDecorations.statusChip(color: color),
      child: Text(
        label.replaceAll('_', ' '),
        style: VisualTutorTypography.statusChip.copyWith(color: color),
      ),
    );
  }
}
