import 'package:flutter/material.dart';

import '../../domain/entities/visual_tutor_entities.dart';
import '../live_board_state.dart';
import '../visual_tutor_design.dart';
import 'board_element_renderer.dart';
import 'check_work_board.dart';
import 'final_answer_board.dart';
import 'unsupported_board.dart';

class LiveTeachingBoard extends StatelessWidget {
  const LiveTeachingBoard({
    super.key,
    this.board,
    this.actions = const [],
    this.variant,
    this.finalAnswerLocked = true,
    this.compact = false,
  });

  final VisualTutorBoardEntity? board;
  final List<VisualTutorBoardActionEntity> actions;
  final String? variant;
  final bool finalAnswerLocked;
  final bool compact;

  // A turn normally contains only a few actions. This guard keeps a malformed
  // or unusually large replay payload from building hundreds of positioned
  // widgets on a small phone. The complete recent replay remains server-side.
  static const _maxRenderedActions = 120;

  @override
  Widget build(BuildContext context) {
    final resolvedVariant = _variant();
    final renderableActions =
        actions
            .where(
              (action) => isRenderableBoardAction(
                action,
                finalAnswerLocked: finalAnswerLocked,
              ),
            )
            .toList()
          ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    final boundedActions = renderableActions.length > _maxRenderedActions
        ? renderableActions.sublist(
            renderableActions.length - _maxRenderedActions,
          )
        : renderableActions;
    if (actions.isNotEmpty && renderableActions.isEmpty) {
      return const _BoardRecovery();
    }
    return switch (resolvedVariant) {
      'check_my_work' => CheckWorkBoard(
        board: board,
        actions: boundedActions,
        compact: compact,
        finalAnswerLocked: finalAnswerLocked,
      ),
      'final_verified_answer' => FinalAnswerBoard(
        board: board,
        actions: boundedActions,
        compact: compact,
        finalAnswerLocked: finalAnswerLocked,
      ),
      'unsupported_problem' => UnsupportedBoard(
        board: board,
        actions: boundedActions,
        compact: compact,
        finalAnswerLocked: finalAnswerLocked,
      ),
      'graph_based' => _GraphBasedBoard(
        board: board,
        actions: boundedActions,
        compact: compact,
        finalAnswerLocked: finalAnswerLocked,
      ),
      'asking_question' => _AskingQuestionBoard(
        board: board,
        actions: boundedActions,
        compact: compact,
      ),
      _ => _ActionBoard(
        actions: boundedActions,
        finalAnswerLocked: finalAnswerLocked,
        compact: compact,
      ),
    };
  }

  String _variant() {
    final metadata = board?.metadata ?? const <String, dynamic>{};
    return (variant ??
            metadata['screen_state'] ??
            metadata['board_type'] ??
            board?.type ??
            'speaking_writing')
        .toString()
        .trim()
        .toLowerCase();
  }
}

class _BoardRecovery extends StatelessWidget {
  const _BoardRecovery();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label:
        'Visual board recovery. The visual could not be shown safely. Continue with the tutor explanation.',
    child: BoardPaperScaffold(
      child: Center(
        child: Text(
          'This visual could not be shown safely. You can still continue with the tutor explanation.',
          key: const Key('visual-tutor-board-recovery'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: VisualTutorColors.textMuted,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    ),
  );
}

class _ActionBoard extends StatelessWidget {
  const _ActionBoard({
    required this.actions,
    required this.finalAnswerLocked,
    required this.compact,
  });

  final List<VisualTutorBoardActionEntity> actions;
  final bool finalAnswerLocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BoardPaperScaffold(
      key: const Key('speaking-writing-board'),
      compact: compact,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(320.0, 900.0);
          final scale = width / 390;
          final visibleActions = actions.toList()
            ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
          return Stack(
            children: [
              for (var i = 0; i < visibleActions.length; i++)
                BoardElementRenderer(
                  action: visibleActions[i],
                  scale: scale,
                  faded: i < visibleActions.length - 1,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AskingQuestionBoard extends StatelessWidget {
  const _AskingQuestionBoard({
    required this.board,
    required this.actions,
    required this.compact,
  });

  final VisualTutorBoardEntity? board;
  final List<VisualTutorBoardActionEntity> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final metadata = board?.metadata ?? const <String, dynamic>{};
    final question =
        metadata['handwritten_question']?.toString() ??
        metadata['question']?.toString() ??
        'Choose the next operation.';
    final equation = metadata['equation_with_blank']?.toString() ?? '';
    final fadedPrevious = metadata['faded_previous_equation']?.toString() ?? '';
    final problem = metadata['problem']?.toString() ?? _problemFromBoard(board);
    final nextStepPreview = metadata['next_step_preview']?.toString() ?? '';
    return BoardPaperScaffold(
      key: const Key('asking-question-board'),
      compact: compact,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 34,
        vertical: compact ? 28 : 34,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fadedPrevious.isNotEmpty)
                Opacity(
                  opacity: .28,
                  child: Text(
                    fadedPrevious,
                    style: VisualTutorTypography.boardEquation.copyWith(
                      fontSize: 20,
                    ),
                  ),
                ),
              if (problem.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .58),
                    borderRadius: BorderRadius.circular(VisualTutorRadius.md),
                    border: Border.all(color: VisualTutorColors.boardBorder),
                  ),
                  child: Text(
                    problem,
                    style: VisualTutorTypography.boardEquation.copyWith(
                      fontSize: compact ? 23 : 28,
                    ),
                  ),
                ),
              ],
              SizedBox(height: compact ? 22 : 28),
              Padding(
                padding: EdgeInsets.only(left: compact ? 8 : 12),
                child: Text(
                  question,
                  key: const Key('asking-question-handwritten-question'),
                  textAlign: TextAlign.left,
                  style: VisualTutorTypography.boardHandwriting.copyWith(
                    fontSize: compact ? 24 : 31,
                    height: 1.12,
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              Padding(
                padding: EdgeInsets.only(left: compact ? 34 : 46),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (equation.isNotEmpty) ...[
                      Text(
                        equation,
                        key: const Key('question-equation-with-blank'),
                        textAlign: TextAlign.left,
                        style: VisualTutorTypography.boardHandwriting.copyWith(
                          color: VisualTutorColors.blueInk,
                          fontSize: compact ? 23 : 28,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Container(
                      key: const Key('question-dashed-blank'),
                      width: compact ? 64 : 76,
                      height: compact ? 56 : 66,
                      alignment: Alignment.center,
                      child: CustomPaint(
                        painter: _DashedBlankPainter(),
                        child: const Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              color: VisualTutorColors.textMuted,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (nextStepPreview.isNotEmpty) ...[
                SizedBox(height: compact ? 20 : 26),
                Padding(
                  padding: EdgeInsets.only(left: compact ? 8 : 12),
                  child: Opacity(
                    opacity: .18,
                    child: Text(
                      nextStepPreview,
                      key: const Key('question-next-step-preview'),
                      textAlign: TextAlign.left,
                      style: VisualTutorTypography.boardEquation.copyWith(
                        fontSize: compact ? 24 : 30,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _problemFromBoard(VisualTutorBoardEntity? board) {
    for (final item in board?.items ?? const <VisualTutorBoardItemEntity>[]) {
      if (item.label.toLowerCase() == 'problem') return item.content;
    }
    return '';
  }
}

class _DashedBlankPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.5),
      const Radius.circular(14),
    );
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: .44)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    final borderPaint = Paint()
      ..color = VisualTutorColors.textMuted
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 8),
          borderPaint,
        );
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GraphBasedBoard extends StatelessWidget {
  const _GraphBasedBoard({
    required this.board,
    required this.actions,
    required this.compact,
    required this.finalAnswerLocked,
  });

  final VisualTutorBoardEntity? board;
  final List<VisualTutorBoardActionEntity> actions;
  final bool compact;
  final bool finalAnswerLocked;

  @override
  Widget build(BuildContext context) {
    final metadata = board?.metadata ?? const <String, dynamic>{};
    VisualTutorBoardActionEntity? graphAction;
    for (final action in actions) {
      if ((action.type == 'show_graph' || action.type == 'plot_function') &&
          action.graph != null) {
        graphAction = action;
        break;
      }
    }
    final equationTitle =
        metadata['equation_title']?.toString() ??
        _equationTitleFromFunctionName(
          graphAction?.graph?['function_expression'] ??
              metadata['function_name'],
        );
    final instruction =
        metadata['instruction']?.toString() ??
        'Study the graph, then answer the next task.';
    return BoardPaperScaffold(
      key: const Key('graph-based-board'),
      compact: compact,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                equationTitle,
                style: VisualTutorTypography.boardEquation.copyWith(
                  fontSize: 21,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    if (graphAction != null)
                      BoardElementRenderer(action: graphAction)
                    else
                      const Center(
                        child: Text(
                          'A graph was not provided for this explanation.',
                          key: Key('graph-board-recovery'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    BoardActionOverlay(
                      actions: actions
                          .where((action) => action.id != graphAction?.id)
                          .toList(),
                      finalAnswerLocked: finalAnswerLocked,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  key: const Key('graph-instruction-chip'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(VisualTutorRadius.pill),
                  ),
                  child: Text(
                    instruction,
                    style: const TextStyle(
                      color: Color(0xFF253044),
                      fontWeight: FontWeight.w800,
                      fontFamilyFallback: VisualTutorTypography.fontFallback,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _equationTitleFromFunctionName(Object? value) {
  final functionName = value?.toString().trim();
  if (functionName == null || functionName.isEmpty) return 'Graph';
  if (functionName.contains('=')) return functionName;
  return 'f(x) = $functionName';
}
