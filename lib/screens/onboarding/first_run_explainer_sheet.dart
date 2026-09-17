import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/responsive/app_breakpoints.dart';
import '../../shared/rean_avatar.dart';

class FirstRunExplainerSheet extends StatelessWidget {
  const FirstRunExplainerSheet({
    super.key,
    required this.onStart,
    required this.onSkip,
    this.onSelectProblem,
  });

  final VoidCallback onStart;
  final VoidCallback onSkip;
  final ValueChanged<String>? onSelectProblem;

  static const String prefKeySeen = 'has_seen_first_run_explainer';

  static const String sampleLimits = r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}';
  static const String samplePhysics = 'v = u + at, u=0, a=2, t=5';
  static const String sampleChemistry = r'2H_2 + O_2 \to 2H_2O';

  static Future<bool> showIfNeeded(
    BuildContext context, {
    ValueChanged<String>? onSelectProblem,
    VoidCallback? onStarted,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(prefKeySeen) ?? false;
    if (hasSeen) return false;

    if (!context.mounted) return false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FirstRunExplainerSheet(
        onStart: () {
          Navigator.of(sheetContext).pop();
          onStarted?.call();
        },
        onSkip: () => Navigator.of(sheetContext).pop(),
        onSelectProblem: (problem) {
          Navigator.of(sheetContext).pop();
          onSelectProblem?.call(problem);
        },
      ),
    );
    return true;
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeySeen, true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = AppBreakpoints.isPhone(context);

    return Container(
      key: const Key('first-run-explainer-sheet'),
      constraints: BoxConstraints(
        maxWidth: AppBreakpoints.maxReadingWidth,
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      margin: EdgeInsets.symmetric(
        horizontal: isPhone ? 0 : 24,
        vertical: isPhone ? 0 : 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1523) : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(24),
          bottom: Radius.circular(isPhone ? 0 : 24),
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, isPhone ? 12 : 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with Rean Avatar
              Row(
                children: [
                  const ReanAvatar(size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.firstRunTitle,
                          style: TextStyle(
                            color: AdaptiveColors.text(context),
                            fontSize: isPhone ? 17 : 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          loc.firstRunSubtitle,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 3 Benefit Rows
              _BenefitRow(
                key: const Key('first-run-benefit-whiteboard'),
                icon: Icons.draw_rounded,
                iconColor: const Color(0xFF00E5FF),
                title: loc.firstRunBenefit1Title,
                body: loc.firstRunBenefit1Body,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _BenefitRow(
                key: const Key('first-run-benefit-bilingual'),
                icon: Icons.translate_rounded,
                iconColor: const Color(0xFF818CF8),
                title: loc.firstRunBenefit2Title,
                body: loc.firstRunBenefit2Body,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _BenefitRow(
                key: const Key('first-run-benefit-followups'),
                icon: Icons.lightbulb_outline_rounded,
                iconColor: const Color(0xFFFBBF24),
                title: loc.firstRunBenefit3Title,
                body: loc.firstRunBenefit3Body,
                isDark: isDark,
              ),
              const SizedBox(height: 18),

              // Sample Starter Chips
              Text(
                loc.trySampleProblem,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StarterChip(
                    key: const Key('starter-chip-limits'),
                    label: '📐 Limits: lim x→3 (x²-9)/(x-3)',
                    onTap: () async {
                      await _markSeen();
                      onSelectProblem?.call(sampleLimits);
                    },
                  ),
                  _StarterChip(
                    key: const Key('starter-chip-physics'),
                    label: '⚡ Kinematics: v = u + at',
                    onTap: () async {
                      await _markSeen();
                      onSelectProblem?.call(samplePhysics);
                    },
                  ),
                  _StarterChip(
                    key: const Key('starter-chip-chemistry'),
                    label: '🧪 Reaction: 2H₂ + O₂ → 2H₂O',
                    onTap: () async {
                      await _markSeen();
                      onSelectProblem?.call(sampleChemistry);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Primary CTA & Skip
              FilledButton(
                key: const Key('first-run-start-learning-button'),
                onPressed: () async {
                  await _markSeen();
                  onStart();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: const Color(0xFF070B14),
                  minimumSize: const Size(double.infinity, AppBreakpoints.minTouchTarget + 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                child: Text(loc.startLearning),
              ),
              const SizedBox(height: 6),
              TextButton(
                key: const Key('first-run-skip-button'),
                onPressed: () async {
                  await _markSeen();
                  onSkip();
                },
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  minimumSize: const Size(double.infinity, AppBreakpoints.minTouchTarget),
                ),
                child: Text(loc.skip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AdaptiveColors.text(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterChip extends StatelessWidget {
  const _StarterChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
