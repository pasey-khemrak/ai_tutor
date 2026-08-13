import 'package:flutter/material.dart';

import '../../domain/entities/visual_tutor_entities.dart';
import '../visual_tutor_design.dart';
import 'board_element_renderer.dart';

class FinalAnswerBoard extends StatelessWidget {
  const FinalAnswerBoard({
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
    final metadata = board?.metadata ?? const <String, dynamic>{};
    final title =
        _value(metadata, 'problem_title') ??
        board?.title ??
        'Integration by Parts';
    final finalAnswer =
        _value(metadata, 'final_answer') ??
        _item('final_answer') ??
        _item('Final') ??
        'Verified answer unavailable';
    final summary = _metadataMap(metadata['summary']);
    final formula =
        summary['key_formula']?.toString() ??
        _value(metadata, 'key_formula') ??
        '∫u dv = uv - ∫v du';
    final rule =
        summary['applied_rule']?.toString() ??
        _value(metadata, 'applied_rule') ??
        'LIATE rule for selecting u.';
    final workedSolution = _workedSolution(metadata);
    final masteryMessage =
        _value(metadata, 'mastery_message') ??
        'Great job! You\'ve mastered this problem.';

    return BoardPaperScaffold(
      key: const Key('final-answer-board'),
      compact: compact,
      showLines: false,
      // Final-answer boards use this purpose-built, semantic layout.  The
      // historical coordinate actions belong to the teaching canvas and can
      // use a different coordinate system; overlaying them here can obscure
      // the verified answer or create an empty task box.
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: PROBLEM SOLVED + VERIFIED chip ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROBLEM SOLVED',
                        key: const Key('problem-solved-label'),
                        style: TextStyle(
                          color: VisualTutorColors.boardTextMuted.withValues(
                            alpha: .7,
                          ),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                          fontFamilyFallback:
                              VisualTutorTypography.fontFallback,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        key: const Key('problem-title-text'),
                        style: VisualTutorTypography.boardEquation.copyWith(
                          fontSize: compact ? 20 : 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Verified chip
                Container(
                  key: const Key('verified-pill'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: VisualTutorColors.cyan.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
                    border: Border.all(
                      color: VisualTutorColors.cyan.withValues(alpha: .45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: VisualTutorColors.cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'VERIFIED (ចាស់ចំ)',
                        style: TextStyle(
                          color: VisualTutorColors.cyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: .5,
                          fontFamilyFallback:
                              VisualTutorTypography.fontFallback,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Worked solution steps ────────────────────────────────────
            if (workedSolution.isNotEmpty)
              Container(
                key: const Key('worked-solution-area'),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: VisualTutorColors.boardBorder.withValues(
                        alpha: .9,
                      ),
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final step in workedSolution)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          step,
                          style: VisualTutorTypography.boardHandwriting
                              .copyWith(
                                color: VisualTutorColors.blackInk.withValues(
                                  alpha: .8,
                                ),
                                fontSize: compact ? 16 : 18,
                              ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // ── FINAL RESULT dark block ──────────────────────────────────
            Container(
              key: const Key('final-result-card'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: VisualTutorColors.shell,
                borderRadius: BorderRadius.circular(VisualTutorRadius.md),
                border: Border.all(
                  color: VisualTutorColors.cyan.withValues(alpha: .55),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: VisualTutorColors.cyan,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FINAL RESULT',
                        style: VisualTutorTypography.finalResultLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '= $finalAnswer',
                    key: const Key('final-result-equation'),
                    style: VisualTutorTypography.finalResultEquation.copyWith(
                      fontSize: compact ? 20 : 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── SUMMARY card ─────────────────────────────────────────────
            Container(
              key: const Key('solution-summary-card'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .58),
                borderRadius: BorderRadius.circular(VisualTutorRadius.md),
                border: Border.all(color: VisualTutorColors.boardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        color: VisualTutorColors.boardTextMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SUMMARY',
                        style: TextStyle(
                          color: VisualTutorColors.boardTextMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontFamilyFallback:
                              VisualTutorTypography.fontFallback,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(label: 'Key Formula:', value: formula),
                  const SizedBox(height: 4),
                  _SummaryRow(label: 'Applied:', value: rule),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Mastery praise ───────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: VisualTutorColors.blueInk,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    masteryMessage,
                    key: const Key('mastery-praise-text'),
                    style: VisualTutorTypography.masteryPraise.copyWith(
                      fontSize: compact ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String? _item(String label) {
    final target = label.trim().toLowerCase();
    for (final item in board?.items ?? const <VisualTutorBoardItemEntity>[]) {
      if (item.label.trim().toLowerCase() == target) return item.content;
    }
    return null;
  }

  String? _value(Map<String, dynamic> metadata, String key) {
    return metadata[key]?.toString();
  }

  List<String> _workedSolution(Map<String, dynamic> metadata) {
    final raw = metadata['worked_solution'];
    if (raw is List) {
      final values = raw
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (values.isNotEmpty) return values;
    }
    return [
      if (_value(metadata, 'problem') != null) _value(metadata, 'problem')!,
      if (_value(metadata, 'step_1') != null) _value(metadata, 'step_1')!,
      if (_value(metadata, 'step_2') != null) _value(metadata, 'step_2')!,
    ];
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: VisualTutorColors.boardTextMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamilyFallback: VisualTutorTypography.fontFallback,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: VisualTutorColors.boardTextDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.35,
              fontFamilyFallback: VisualTutorTypography.fontFallback,
            ),
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic> _metadataMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}
