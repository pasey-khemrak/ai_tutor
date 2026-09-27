import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/visual_tutor_entities.dart';
import '../visual_tutor_design.dart';

/// Trust signal chip rendered on the whiteboard alongside the final answer.
/// Distinguishes machine-verified (e.g. SymPy) solutions from unverified AI answers.
class BoardAnswerVerificationChip extends StatelessWidget {
  const BoardAnswerVerificationChip({
    super.key,
    required this.verification,
    this.compact = false,
  });

  final VisualTutorVerificationEntity verification;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVerified = verification.verified;
    final label = isVerified ? l10n.verifiedAnswer : l10n.unverifiedAnswer;
    final icon = isVerified ? Icons.verified_outlined : Icons.info_outline;
    final color =
        isVerified ? VisualTutorColors.cyan : VisualTutorColors.textSubtle;

    return Semantics(
      label: label,
      child: Container(
        key: Key(
          isVerified
              ? 'visual-tutor-verified-chip'
              : 'visual-tutor-unverified-chip',
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: VisualTutorDecorations.verifiedChip(verified: isVerified),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: compact ? 13 : 15,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: VisualTutorTypography.fontFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
