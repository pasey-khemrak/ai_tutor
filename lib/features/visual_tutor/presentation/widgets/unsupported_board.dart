import 'package:flutter/material.dart';

import '../../domain/entities/visual_tutor_entities.dart';
import '../visual_tutor_design.dart';
import 'board_element_renderer.dart';

class UnsupportedBoard extends StatelessWidget {
  const UnsupportedBoard({
    super.key,
    required this.board,
    this.actions = const [],
    this.finalAnswerLocked = true,
    this.compact = false,
  });

  final VisualTutorBoardEntity? board;
  final List<VisualTutorBoardActionEntity> actions;
  final bool finalAnswerLocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final message =
        board?.metadata['friendly_message']?.toString() ??
        "I'm sorry, I can't solve this type of problem yet.";
    final khmerExplanation =
        board?.metadata['khmer_explanation']?.toString() ??
        'សូមសាកល្បងប្រធានបទផ្សេង ឬពិនិត្យមើលគុណភាពរូបភាព។';
    return BoardPaperScaffold(
      key: const Key('unsupported-problem-board'),
      compact: compact,
      showLines: false,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SYSTEM STATUS\nUnsupported Problem',
                        style: VisualTutorTypography.boardEquation.copyWith(
                          fontSize: 21,
                        ),
                      ),
                    ),
                    Container(
                      key: const Key('unsupported-error-pill'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: VisualTutorColors.redInk.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(
                          VisualTutorRadius.pill,
                        ),
                        border: Border.all(
                          color: VisualTutorColors.redInk.withValues(
                            alpha: .26,
                          ),
                        ),
                      ),
                      child: const Text(
                        'ERROR\n(កំហុស)',
                        style: TextStyle(
                          color: VisualTutorColors.redInk,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Center(
                  child: Container(
                    key: const Key('unsupported-illustration-placeholder'),
                    width: compact ? 108 : 132,
                    height: compact ? 108 : 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VisualTutorColors.boardPaperLine.withValues(
                        alpha: .55,
                      ),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: VisualTutorColors.blueInk,
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    '"$message"',
                    textAlign: TextAlign.center,
                    style: VisualTutorTypography.boardHandwriting.copyWith(
                      color: VisualTutorColors.blackInk,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    khmerExplanation,
                    key: const Key('unsupported-khmer-explanation'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: VisualTutorColors.textMuted.withValues(alpha: .9),
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: VisualTutorTypography.fontFallback,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _Suggestion(
                  key: Key('unsupported-suggestion-topic'),
                  label: 'Try a different topic',
                  icon: Icons.lightbulb_outline,
                ),
                const SizedBox(height: 10),
                const _Suggestion(
                  key: Key('unsupported-suggestion-image-quality'),
                  label: 'Check the image quality',
                  icon: Icons.camera_alt_rounded,
                ),
              ],
            ),
          ),
          BoardActionOverlay(
            actions: actions,
            finalAnswerLocked: finalAnswerLocked,
          ),
        ],
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .64),
        borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: VisualTutorColors.blueInk, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF253044),
                fontWeight: FontWeight.w800,
                fontFamilyFallback: VisualTutorTypography.fontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
