import 'package:flutter/material.dart';

import '../../domain/entities/visual_tutor_entities.dart';
import '../visual_tutor_design.dart';
import 'board_element_renderer.dart';

class CheckWorkBoard extends StatelessWidget {
  const CheckWorkBoard({
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
    final problem =
        _value(metadata, 'problem') ??
        _item('problem') ??
        'Problem unavailable';
    final studentStep =
        _value(metadata, 'student_step') ??
        _item('student_step') ??
        'Student step unavailable';
    final fadedStep =
        _value(metadata, 'faded_step') ?? _item('faded_step') ?? '';
    final message =
        _value(metadata, 'mistake_message') ?? 'Check your sign here!';

    return BoardPaperScaffold(
      key: const Key('check-work-board'),
      compact: compact,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _EquationText(problem)),
                  const Icon(
                    Icons.check_rounded,
                    color: VisualTutorColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                key: const Key('red-mistake-marker'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: ShapeDecoration(
                  color: VisualTutorColors.redInk.withValues(alpha: .07),
                  shape: const _DashedRoundedBorder(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EquationText(studentStep, muted: true),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: VisualTutorTypography.boardHandwriting.copyWith(
                        color: VisualTutorColors.redInk,
                      ),
                    ),
                  ],
                ),
              ),
              if (fadedStep.isNotEmpty) ...[
                const SizedBox(height: 18),
                Opacity(
                  opacity: .38,
                  child: _EquationText(fadedStep, muted: true),
                ),
              ],
            ],
          ),
          BoardActionOverlay(
            actions: actions,
            finalAnswerLocked: finalAnswerLocked,
          ),
        ],
      ),
    );
  }

  String? _item(String label) {
    for (final item in board?.items ?? const <VisualTutorBoardItemEntity>[]) {
      if (item.label.toLowerCase() == label) return item.content;
    }
    return null;
  }

  String? _value(Map<String, dynamic> metadata, String key) {
    return metadata[key]?.toString();
  }
}

class _EquationText extends StatelessWidget {
  const _EquationText(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: VisualTutorTypography.boardEquation.copyWith(
        color: muted
            ? VisualTutorColors.blackInk.withValues(alpha: .55)
            : VisualTutorColors.blackInk,
        fontSize: 22,
      ),
    );
  }
}

class _DashedRoundedBorder extends ShapeBorder {
  const _DashedRoundedBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(34)));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = VisualTutorColors.redInk.withValues(alpha: .7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = getOuterPath(rect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final extract = metric.extractPath(distance, distance + 8);
        canvas.drawPath(extract, paint);
        distance += 15;
      }
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}
