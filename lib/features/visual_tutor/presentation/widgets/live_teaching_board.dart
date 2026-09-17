import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/entities/visual_tutor_entities.dart';
import '../live_board_state.dart';
import '../semantic_board_layout.dart';
import '../visual_tutor_design.dart';
import 'board_element_renderer.dart';

class BoardStudentInteraction {
  const BoardStudentInteraction({
    required this.kind,
    required this.actionId,
    this.value,
  });

  final String kind;
  final String actionId;
  final String? value;
}

class LiveTeachingBoard extends StatefulWidget {
  const LiveTeachingBoard({
    super.key,
    this.board,
    this.actions = const [],
    this.variant,
    this.finalAnswerLocked = true,
    this.compact = false,
    this.useLogicalCanvasScale = false,
    this.activeActionId,
    this.activeProgress = const AlwaysStoppedAnimation(1),
    this.reducedMotion = false,
    this.restored = false,
    this.transitionsEnabled = true,
    this.selectedActionId,
    this.onStudentInteraction,
    this.onActionDiagnostic,
  });

  final VisualTutorBoardEntity? board;
  final List<VisualTutorBoardActionEntity> actions;
  final String? variant;
  final bool finalAnswerLocked;
  final bool compact;

  /// Keeps legacy callers that already provide logical canvas coordinates from
  /// being scaled a second time.
  final bool useLogicalCanvasScale;

  /// Presentation-only playback state. Board truth remains in LiveBoardState.
  final String? activeActionId;
  final Animation<double> activeProgress;
  final bool reducedMotion;
  final bool restored;

  /// Timeline playback already owns reveal/replay motion, so it can suppress
  /// patch transitions while rebuilding its visible action window.
  final bool transitionsEnabled;
  final String? selectedActionId;
  final ValueChanged<BoardStudentInteraction>? onStudentInteraction;
  final BoardActionDiagnosticListener? onActionDiagnostic;

  // A turn normally contains only a few actions. This guard keeps a malformed
  // or unusually large replay payload from building hundreds of positioned
  // widgets on a small phone. The complete recent replay remains server-side.
  static const _maxRenderedActions = 64;

  @override
  State<LiveTeachingBoard> createState() => _LiveTeachingBoardState();
}

enum _BoardTransition { steady, entering, exiting }

class _LiveTeachingBoardState extends State<LiveTeachingBoard> {
  final Map<String, VisualTutorBoardActionEntity> _exitingActions = {};
  final Set<String> _enteringActionIds = {};
  List<VisualTutorBoardActionEntity> _previousActions = const [];
  int _transitionGeneration = 0;

  bool get _renderImmediately => widget.reducedMotion || widget.restored;

  @override
  void initState() {
    super.initState();
    _previousActions = _renderableActions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reportSkippedActions();
      _reportRendered(_previousActions);
    });
  }

  @override
  void didUpdateWidget(covariant LiveTeachingBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextActions = _renderableActions();
    final previousById = {
      for (final action in _previousActions) action.id: action,
    };
    final nextIds = nextActions.map((action) => action.id).toSet();
    _transitionGeneration++;
    final generation = _transitionGeneration;

    if (_renderImmediately || !widget.transitionsEnabled) {
      _exitingActions.clear();
      _enteringActionIds.clear();
    } else {
      _enteringActionIds
        ..clear()
        ..addAll(
          nextActions
              .where(
                (action) =>
                    !previousById.containsKey(action.id) &&
                    !(action.type == 'transform_equation' &&
                        action.targetId != null &&
                        previousById.containsKey(action.targetId)),
              )
              .map((action) => action.id),
        );
      for (final entry in previousById.entries) {
        if (nextIds.contains(entry.key)) continue;
        _exitingActions[entry.key] = entry.value;
        Future<void>.delayed(const Duration(milliseconds: 220), () {
          if (!mounted || generation != _transitionGeneration) return;
          setState(() => _exitingActions.remove(entry.key));
        });
      }
      for (final id in nextIds) {
        _exitingActions.remove(id);
      }
    }
    _previousActions = nextActions;
    final newlyRenderable = nextActions
        .where((action) => !previousById.containsKey(action.id))
        .toList(growable: false);
    if (newlyRenderable.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _reportSkippedActions();
        _reportRendered(newlyRenderable);
      });
    }
  }

  void _reportRendered(List<VisualTutorBoardActionEntity> actions) {
    final listener = widget.onActionDiagnostic;
    if (listener == null) return;
    for (final action in actions) {
      listener(
        BoardActionDiagnostic(
          actionId: action.id,
          lifecycle: BoardActionLifecycle.rendered,
        ),
      );
    }
  }

  void _reportSkippedActions() {
    final listener = widget.onActionDiagnostic;
    if (listener == null) return;
    for (final action in widget.actions) {
      if (isRenderableBoardAction(
        action,
        finalAnswerLocked: widget.finalAnswerLocked,
      )) {
        continue;
      }
      listener(
        BoardActionDiagnostic(
          actionId: action.id,
          lifecycle: BoardActionLifecycle.skipped,
          reason: isValidBoardAction(action)
              ? 'control_or_locked_action'
              : 'unsupported_or_invalid_action',
        ),
      );
    }
  }

  List<VisualTutorBoardActionEntity> _renderableActions() {
    final renderableActions =
        widget.actions
            .where(
              (action) => isRenderableBoardAction(
                action,
                finalAnswerLocked: widget.finalAnswerLocked,
              ),
            )
            .toList()
          ..sort((a, b) {
            final sequence = a.sequenceIndex.compareTo(b.sequenceIndex);
            return sequence != 0 ? sequence : a.id.compareTo(b.id);
          });
    if (renderableActions.length <= LiveTeachingBoard._maxRenderedActions) {
      return renderableActions;
    }

    // Preserve the active teaching section even when a resumed or malformed
    // payload is very large. Older steps are intentionally collapsed, not
    // silently discarded; the canvas replay control retains the full lesson.
    final activeId = widget.activeActionId;
    final activeAction = activeId == null
        ? renderableActions.lastWhere(
            (action) => action.metadata['current_step'] == true,
            orElse: () => renderableActions.last,
          )
        : renderableActions.firstWhere(
            (action) => action.id == activeId,
            orElse: () => renderableActions.last,
          );
    final activeSectionId = activeAction.sectionId;
    final activeGroupId = activeAction.groupId;
    final pinned = renderableActions
        .where(
          (action) =>
              action.id == activeAction.id ||
              (activeSectionId != null &&
                  action.sectionId == activeSectionId) ||
              (activeSectionId == null &&
                  activeGroupId != null &&
                  action.groupId == activeGroupId),
        )
        .toList(growable: false);
    final pinnedIds = pinned.map((action) => action.id).toSet();
    final remainingSlots = math.max(
      0,
      LiveTeachingBoard._maxRenderedActions - pinned.length,
    );
    final recentContext = renderableActions
        .where((action) => !pinnedIds.contains(action.id))
        .toList(growable: false)
        .reversed
        .take(remainingSlots)
        .toList(growable: false)
        .reversed;
    return [...recentContext, ...pinned]
      ..sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
  }

  int _collapsedActionCount() {
    final validCount = widget.actions
        .where(
          (action) => isRenderableBoardAction(
            action,
            finalAnswerLocked: widget.finalAnswerLocked,
          ),
        )
        .length;
    return math.max(0, validCount - _renderableActions().length);
  }

  @override
  Widget build(BuildContext context) {
    final renderableActions = _renderableActions();
    if (widget.actions.isNotEmpty && renderableActions.isEmpty) {
      return const _BoardRecovery();
    }
    // Paging lives in the board's chrome (TeachingCanvasBoard), not here: this
    // widget sits inside a pan/zoom ink canvas that swallows taps, so a
    // switcher drawn here could not be pressed.
    return _buildBoard(renderableActions);
  }

  Widget _buildBoard(List<VisualTutorBoardActionEntity> boundedActions) {
    return _ActionBoard(
      actions: boundedActions,
      exitingActions: _exitingActions,
      enteringActionIds: _enteringActionIds,
      reducedMotion: _renderImmediately || !widget.transitionsEnabled,
      finalAnswerLocked: widget.finalAnswerLocked,
      compact: widget.compact,
      useLogicalCanvasScale: widget.useLogicalCanvasScale,
      activeActionId: widget.activeActionId,
      activeProgress: widget.activeProgress,
      hasUnsupportedActions: widget.actions.any(
        (action) => !isValidBoardAction(action),
      ),
      collapsedActionCount: _collapsedActionCount(),
      selectedActionId: widget.selectedActionId,
      onStudentInteraction: widget.onStudentInteraction,
    );
  }
}

/// Lets a student page back through earlier boards, like flipping back through
/// the pages of their notebook.
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
    required this.exitingActions,
    required this.enteringActionIds,
    required this.reducedMotion,
    required this.selectedActionId,
    required this.onStudentInteraction,
    required this.finalAnswerLocked,
    required this.compact,
    required this.useLogicalCanvasScale,
    required this.hasUnsupportedActions,
    required this.collapsedActionCount,
    required this.activeActionId,
    required this.activeProgress,
  });

  final List<VisualTutorBoardActionEntity> actions;
  final Map<String, VisualTutorBoardActionEntity> exitingActions;
  final Set<String> enteringActionIds;
  final bool reducedMotion;
  final String? selectedActionId;
  final ValueChanged<BoardStudentInteraction>? onStudentInteraction;
  final bool finalAnswerLocked;
  final bool compact;
  final bool useLogicalCanvasScale;
  final bool hasUnsupportedActions;
  final int collapsedActionCount;
  final String? activeActionId;
  final Animation<double> activeProgress;

  @override
  Widget build(BuildContext context) {
    return BoardPaperScaffold(
      key: const Key('speaking-writing-board'),
      compact: compact,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.clamp(320.0, 900.0);
          final scale = useLogicalCanvasScale ? 1.0 : width / 390;
          final visibleActions = _withFallbackLayout(
            SemanticBoardLayout.resolve(
              actions: actions,
              viewport: constraints.biggest,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            ),
          );
          final exitingActions = _withFallbackLayout(
            this.exitingActions.values.toList(),
          );
          final activeIndex = visibleActions.indexWhere(
            (action) => action.id == activeActionId,
          );
          return Stack(
            children: [
              for (var i = 0; i < visibleActions.length; i++)
                Positioned.fill(
                  key: Key('teaching-board-transition-${visibleActions[i].id}'),
                  child: _CalmBoardActionTransition(
                    transition: enteringActionIds.contains(visibleActions[i].id)
                        ? _BoardTransition.entering
                        : _BoardTransition.steady,
                    reducedMotion: reducedMotion,
                    child: Opacity(
                      opacity: activeIndex >= 0 && i < activeIndex ? .62 : 1,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (visibleActions[i].id == activeActionId)
                            _ActiveTeachingActionHighlight(
                              action: visibleActions[i],
                              scale: visibleActions[i].layoutZone == null
                                  ? scale
                                  : 1,
                              reducedMotion: reducedMotion,
                            ),
                          BoardElementRenderer(
                            action: visibleActions[i],
                            scale: visibleActions[i].layoutZone == null
                                ? scale
                                : 1,
                            faded: visibleActions[i].metadata['faded'] == true,
                            progress: visibleActions[i].id == activeActionId
                                ? activeProgress
                                : const AlwaysStoppedAnimation(1),
                            reducedMotion: reducedMotion,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (final action in exitingActions)
                Positioned.fill(
                  key: Key('teaching-board-removing-${action.id}'),
                  child: _CalmBoardActionTransition(
                    transition: _BoardTransition.exiting,
                    reducedMotion: reducedMotion,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        BoardElementRenderer(
                          action: action,
                          scale: action.layoutZone == null ? scale : 1,
                          faded: action.metadata['faded'] == true,
                          reducedMotion: reducedMotion,
                        ),
                      ],
                    ),
                  ),
                ),
              if (onStudentInteraction != null)
                for (final action in visibleActions)
                  _StudentActionOverlay(
                    action: action,
                    scale: action.layoutZone == null ? scale : 1,
                    selected: action.id == selectedActionId,
                    onInteraction: onStudentInteraction!,
                  ),
              if (hasUnsupportedActions)
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _InlineBoardRecovery(),
                ),
              if (collapsedActionCount > 0)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: hasUnsupportedActions ? 68 : 16,
                  child: _BoardHistorySummary(count: collapsedActionCount),
                ),
            ],
          );
        },
      ),
    );
  }

  List<VisualTutorBoardActionEntity> _withFallbackLayout(
    List<VisualTutorBoardActionEntity> source,
  ) {
    final indexed = source.indexed.toList()
      ..sort((a, b) {
        final sequence = a.$2.sequenceIndex.compareTo(b.$2.sequenceIndex);
        return sequence != 0 ? sequence : a.$1.compareTo(b.$1);
      });
    var nextY = 28.0;
    return [
      for (final entry in indexed)
        () {
          final action = entry.$2;
          if (action.layoutZone != null) return action;
          final isTextOrEquation =
              action.type == 'write_text' ||
              action.type == 'write_equation' ||
              action.type == 'transform_equation' ||
              action.type == 'student_task';
          // If the AI provides overlapping Y coordinates for text, enforce spacing by taking the max
          final y = isTextOrEquation
              ? math.max(action.y ?? nextY, nextY)
              : (action.y ?? nextY);
          final height = action.height ?? 44.0;
          nextY = (y + height + 18).clamp(nextY, double.infinity).toDouble();
          // Coordinates supplied by the plan are authoritative. Only absent
          // geometry receives a deterministic, non-overlapping fallback.
          return action.copyWith(x: action.x ?? 28, y: y);
        }(),
    ];
  }
}

class _ActiveTeachingActionHighlight extends StatelessWidget {
  const _ActiveTeachingActionHighlight({
    required this.action,
    required this.scale,
    required this.reducedMotion,
  });

  final VisualTutorBoardActionEntity action;
  final double scale;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Positioned(
    left: ((action.x ?? 24) * scale) - 5,
    top: (action.y ?? 28) - 5,
    width: ((action.width ?? 260) * scale) + 10,
    height: (action.height ?? 48) + 10,
    child: Semantics(
      container: true,
      liveRegion: true,
      label:
          'Current teaching action: ${action.text ?? action.latex ?? action.type}',
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: VisualTutorColors.cyan.withValues(alpha: .78),
              width: 2,
            ),
            color: VisualTutorColors.cyan.withValues(alpha: .06),
          ),
        ),
      ),
    ),
  );
}

class _CalmBoardActionTransition extends StatefulWidget {
  const _CalmBoardActionTransition({
    required this.transition,
    required this.reducedMotion,
    required this.child,
  });

  final _BoardTransition transition;
  final bool reducedMotion;
  final Widget child;

  @override
  State<_CalmBoardActionTransition> createState() =>
      _CalmBoardActionTransitionState();
}

class _CalmBoardActionTransitionState extends State<_CalmBoardActionTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value:
          widget.transition == _BoardTransition.entering &&
              !widget.reducedMotion
          ? 0
          : 1,
    );
    _runTransition();
  }

  @override
  void didUpdateWidget(covariant _CalmBoardActionTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transition != widget.transition ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _runTransition();
    }
  }

  void _runTransition() {
    if (widget.reducedMotion) {
      _controller.value = widget.transition == _BoardTransition.exiting ? 0 : 1;
      return;
    }
    switch (widget.transition) {
      case _BoardTransition.entering:
        _controller.forward(from: 0);
      case _BoardTransition.exiting:
        _controller.reverse(from: 1);
      case _BoardTransition.steady:
        _controller.forward(from: _controller.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_controller.value);
        final offset = widget.transition == _BoardTransition.exiting
            ? Offset(0, -.012 * (1 - progress))
            : Offset(0, .018 * (1 - progress));
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, offset.dy * 420),
            child: child,
          ),
        );
      },
    );
  }
}

class _StudentActionOverlay extends StatelessWidget {
  const _StudentActionOverlay({
    required this.action,
    required this.scale,
    required this.selected,
    required this.onInteraction,
  });

  final VisualTutorBoardActionEntity action;
  final double scale;
  final bool selected;
  final ValueChanged<BoardStudentInteraction> onInteraction;

  bool get _isAnswerField =>
      action.type == 'create_blank' ||
      (action.type == 'student_task' && action.requiresStudentResponse);

  bool get _isSelectable =>
      action.type == 'write_equation' ||
      action.type == 'transform_equation' ||
      action.type == 'write_text' ||
      action.type == 'student_task';

  @override
  Widget build(BuildContext context) {
    final left = (action.x ?? 28) * scale;
    final top = action.y ?? 32;
    final width = (action.width ?? 260) * scale;
    final height = action.height ?? 42;
    if (_isAnswerField) {
      return Positioned(
        left: left,
        top: action.type == 'student_task' ? top + height + 6 : top,
        width: width.clamp(130, 360),
        height: 44,
        child: _StudentAnswerField(
          action: action,
          onInteraction: onInteraction,
        ),
      );
    }
    if (!_isSelectable) return const SizedBox.shrink();
    final content = (action.text ?? action.latex ?? 'teaching step')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return Positioned(
      key: Key('teaching-board-action-${action.id}-tap-target'),
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        selected: selected,
        label:
            'Select board step: ${content.isEmpty ? 'teaching step' : content}',
        hint: selected
            ? 'Use the Explain button for another explanation.'
            : 'Press Enter to focus this teaching step.',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onInteraction(
              BoardStudentInteraction(kind: 'selection', actionId: action.id),
            ),
            borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
            child: selected
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton.icon(
                        key: Key('teaching-board-explain-${action.id}'),
                        onPressed: () => onInteraction(
                          BoardStudentInteraction(
                            kind: 'explain',
                            actionId: action.id,
                            value: action.text ?? action.latex,
                          ),
                        ),
                        icon: const Icon(Icons.lightbulb_outline, size: 15),
                        label: const Text('Explain'),
                      ),
                    ),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _StudentAnswerField extends StatefulWidget {
  const _StudentAnswerField({
    required this.action,
    required this.onInteraction,
  });

  final VisualTutorBoardActionEntity action;
  final ValueChanged<BoardStudentInteraction> onInteraction;

  @override
  State<_StudentAnswerField> createState() => _StudentAnswerFieldState();
}

class _StudentAnswerFieldState extends State<_StudentAnswerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final answer = _controller.text.trim();
    if (answer.isEmpty) return;
    widget.onInteraction(
      BoardStudentInteraction(
        kind: 'answer',
        actionId: widget.action.id,
        value: answer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Student answer for ${widget.action.id}',
      textField: true,
      child: TextField(
        key: Key('teaching-board-answer-${widget.action.id}'),
        controller: _controller,
        onSubmitted: (_) => _submit(),
        textInputAction: TextInputAction.send,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Your answer',
          filled: true,
          fillColor: Colors.white.withValues(alpha: .92),
          suffixIcon: IconButton(
            key: Key('teaching-board-answer-submit-${widget.action.id}'),
            tooltip: 'Submit board answer',
            icon: const Icon(Icons.send_rounded, size: 18),
            onPressed: _submit,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
          ),
        ),
      ),
    );
  }
}

class _InlineBoardRecovery extends StatelessWidget {
  const _InlineBoardRecovery();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Some unsupported visual details were safely skipped.',
    child: Container(
      key: const Key('visual-tutor-board-inline-recovery'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: VisualTutorColors.shellElevated.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      ),
      child: const Text(
        'Some visual details could not be shown safely. The tutor explanation is still available.',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
    ),
  );
}

class _BoardHistorySummary extends StatelessWidget {
  const _BoardHistorySummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label:
        '$count earlier board actions are collapsed. Replay the board to review them.',
    child: Container(
      key: const Key('visual-tutor-board-history-summary'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: VisualTutorColors.shellElevated.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(VisualTutorRadius.md),
      ),
      child: Text(
        '$count earlier board actions are collapsed. Use Replay to review the lesson.',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    ),
  );
}
