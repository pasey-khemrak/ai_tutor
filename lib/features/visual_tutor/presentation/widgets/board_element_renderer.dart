import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../domain/entities/visual_tutor_entities.dart';
import '../live_board_state.dart';
import '../visual_tutor_design.dart';

class BoardPaperScaffold extends StatelessWidget {
  const BoardPaperScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.showLines = true,
    this.compact = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showLines;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('live-teaching-board-paper'),
      width: double.infinity,
      decoration: VisualTutorDecorations.boardPaper(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (showLines) const Positioned.fill(child: _PaperLines()),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class BoardElementRenderer extends StatelessWidget {
  const BoardElementRenderer({
    super.key,
    required this.action,
    this.scale = 1,
    this.faded = false,
    this.progress = const AlwaysStoppedAnimation(1),
    this.reducedMotion = false,
  });

  final VisualTutorBoardActionEntity action;
  final double scale;
  final bool faded;
  final Animation<double> progress;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    if (action.hidden) return const SizedBox.shrink();
    final effectiveFaded = faded || action.metadata['faded'] == true;

    final left = (action.x ?? 28) * scale;
    final top = action.y ?? 32;
    final width = (action.width ?? 260) * scale;
    final height = action.height ?? 42;

    return switch (action.type) {
      'highlight' => Positioned(
        key: const Key('teaching-board-highlight'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: _HighlightStrip(
          actionId: action.id,
          reducedMotion: reducedMotion,
        ),
      ),
      'circle' ||
      'cross_out' ||
      'draw_line' ||
      'draw_rectangle' ||
      'draw_arrow' => Positioned.fill(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Semantics(
              image: true,
              label: _visualSemanticLabel(action),
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) => CustomPaint(
                    key: Key('teaching-board-${action.type}-${action.id}'),
                    painter: _ShapeActionPainter(
                      action: action,
                      scale: scale,
                      progress: progress.value,
                    ),
                  ),
                ),
              ),
            ),
            if (action.type == 'draw_arrow' &&
                (action.metadata['label']?.toString().trim().isNotEmpty ??
                    false))
              Positioned(
                left: ((action.x ?? 40) + (action.width ?? 120) / 2) * scale,
                top: (action.y ?? 40) + (action.height ?? 0) / 2 - 24,
                child: Text(
                  action.metadata['label'].toString(),
                  key: Key('teaching-board-arrow-label-${action.id}'),
                  style: const TextStyle(
                    color: VisualTutorColors.blueInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamilyFallback: VisualTutorTypography.fontFallback,
                  ),
                ),
              ),
          ],
        ),
      ),
      'draw_axes' => Positioned(
        key: Key('teaching-board-axes-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: _ProgressiveVisualReveal(
          progress: progress,
          reducedMotion: reducedMotion,
          child: Semantics(
            image: true,
            label: 'Coordinate axes',
            child: RepaintBoundary(
              // Stable key for the board-level axes primitive; the positioned
              // parent remains action-specific for multiple graph regions.
              child: CustomPaint(
                key: const Key('teaching-board-axes'),
                painter: _AxesPainter(),
              ),
            ),
          ),
        ),
      ),
      'draw_point' => Positioned(
        key: Key('teaching-board-point-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: _PointLabel(action: action),
      ),
      'show_table' => Positioned(
        key: Key('teaching-board-table-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: _ProgressiveVisualReveal(
          progress: progress,
          reducedMotion: reducedMotion,
          child: _TableView(
            action: action,
            progress: progress,
            reducedMotion: reducedMotion,
          ),
        ),
      ),
      'create_blank' => Positioned(
        key: Key('teaching-board-blank-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .58),
            borderRadius: BorderRadius.circular(VisualTutorRadius.md),
            border: Border.all(
              color: VisualTutorColors.textMuted,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
        ),
      ),
      'show_graph' => Positioned(
        key: Key('teaching-board-graph-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: _ProgressiveVisualReveal(
          progress: progress,
          reducedMotion: reducedMotion,
          child: Semantics(
            image: true,
            label: _visualSemanticLabel(action),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .58),
                borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
                border: Border.all(color: VisualTutorColors.blueInk),
              ),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StructuredGraphPainter(action.graph!),
                ),
              ),
            ),
          ),
        ),
      ),
      'plot_function' => Positioned(
        key: Key('teaching-board-function-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: _ProgressiveVisualReveal(
          progress: progress,
          reducedMotion: reducedMotion,
          child: Semantics(
            image: true,
            label: _visualSemanticLabel(action),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _StructuredGraphPainter(action.graph!),
              ),
            ),
          ),
        ),
      ),
      'show_number_line' => Positioned(
        key: Key('teaching-board-number-line-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: Semantics(
          image: true,
          label: _visualSemanticLabel(action),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _DynamicNumberLinePainter(action: action),
            ),
          ),
        ),
      ),
      'write_text' ||
      'write_equation' ||
      'transform_equation' ||
      'show_hint' ||
      'show_feedback' ||
      'student_task' ||
      'graph_annotation' ||
      'final_answer_reveal' => _PositionedTextAction(
        action: action,
        left: left,
        top: top,
        width: width,
        height: height,
        faded: effectiveFaded,
        progress: progress,
        scale: scale,
        reducedMotion: reducedMotion,
      ),
      // Physics: free body diagram — box with labeled force arrows
      'draw_free_body_diagram' => Positioned(
        key: Key('teaching-board-fbd-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: Semantics(
          image: true,
          label:
              action.metadata['alt']?.toString() ??
              'Free body diagram showing forces',
          child: _ProgressiveVisualReveal(
            progress: progress,
            reducedMotion: reducedMotion,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FreeBodyDiagramPainter(action: action),
              ),
            ),
          ),
        ),
      ),
      // Chemistry: molecule / bond diagram
      'draw_molecule' => Positioned(
        key: Key('teaching-board-molecule-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: Semantics(
          image: true,
          label:
              action.metadata['alt']?.toString() ??
              'Molecular structure diagram',
          child: _ProgressiveVisualReveal(
            progress: progress,
            reducedMotion: reducedMotion,
            child: RepaintBoundary(
              child: CustomPaint(painter: _MoleculePainter(action: action)),
            ),
          ),
        ),
      ),
      // Physics: wave diagram (sinusoidal wave with labeled amplitude/wavelength)
      'draw_wave' => Positioned(
        key: Key('teaching-board-wave-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: Semantics(
          image: true,
          label: action.metadata['alt']?.toString() ?? 'Wave diagram',
          child: _ProgressiveVisualReveal(
            progress: progress,
            reducedMotion: reducedMotion,
            child: RepaintBoundary(
              child: CustomPaint(painter: _WavePainter(action: action)),
            ),
          ),
        ),
      ),
      'draw_atom_model' => _diagramPositioned(
        action,
        left,
        top,
        width,
        height,
        progress,
        reducedMotion,
        'Atom model for ${action.metadata['atom_model'] is Map ? action.metadata['atom_model']['symbol'] : 'an element'}',
        _AtomModelPainter(action: action),
      ),
      'draw_particle_diagram' => _diagramPositioned(
        action,
        left,
        top,
        width,
        height,
        progress,
        reducedMotion,
        'Particle diagram showing ${action.metadata['particle_diagram'] is Map ? action.metadata['particle_diagram']['state'] : 'matter'}',
        _ParticleDiagramPainter(action: action),
      ),
      'draw_circuit_diagram' => _diagramPositioned(
        action,
        left,
        top,
        width,
        height,
        progress,
        reducedMotion,
        'Series circuit diagram',
        _CircuitDiagramPainter(action: action),
      ),
      'show_reaction_layout' => _diagramPositioned(
        action,
        left,
        top,
        width,
        height,
        progress,
        reducedMotion,
        'Chemical reaction balancing layout',
        _ReactionLayoutPainter(action: action),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _diagramPositioned(
    VisualTutorBoardActionEntity action,
    double left,
    double top,
    double width,
    double height,
    Animation<double> progress,
    bool reducedMotion,
    String label,
    CustomPainter painter,
  ) => Positioned(
    key: Key('teaching-board-${action.type}-${action.id}'),
    left: left,
    top: top,
    width: width,
    height: height,
    child: Semantics(
      image: true,
      label: label,
      child: _ProgressiveVisualReveal(
        progress: progress,
        reducedMotion: reducedMotion,
        child: RepaintBoundary(child: CustomPaint(painter: painter)),
      ),
    ),
  );

  static String _visualSemanticLabel(VisualTutorBoardActionEntity action) {
    return switch (action.type) {
      'draw_line' => 'Line on the teaching board',
      'draw_rectangle' => 'Rectangle on the teaching board',
      'draw_arrow' =>
        action.metadata['label'] is String
            ? 'Labelled arrow: ${action.metadata['label']}'
            : 'Arrow on the teaching board',
      'circle' => 'Circle on the teaching board',
      'cross_out' => 'Crossed out working',
      'show_number_line' => 'Number line',
      'show_graph' ||
      'plot_function' => 'Mathematical graph${_graphDescription(action)}',
      _ => 'Teaching visual',
    };
  }

  static String _graphDescription(VisualTutorBoardActionEntity action) {
    final graph = action.graph;
    final expression = graph?['function_expression']?.toString().trim();
    return expression == null || expression.isEmpty ? '' : ' of $expression';
  }
}

/// Reveals declarative graphs from left to right, matching how a teacher
/// traces axes and curves. Path-based shapes use their own painters instead.
class _ProgressiveVisualReveal extends StatelessWidget {
  const _ProgressiveVisualReveal({
    required this.progress,
    required this.reducedMotion,
    required this.child,
  });

  final Animation<double> progress;
  final bool reducedMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    child: child,
    builder: (context, child) => ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: reducedMotion ? 1 : progress.value.clamp(0.001, 1),
        child: child,
      ),
    ),
  );
}

class _DynamicNumberLinePainter extends CustomPainter {
  const _DynamicNumberLinePainter({required this.action});

  final VisualTutorBoardActionEntity action;

  @override
  void paint(Canvas canvas, Size size) {
    // Extract range from graph metadata or fall back to sensible defaults.
    final graph = action.graph ?? {};
    final numberLine = action.metadata['number_line'] is Map
        ? action.metadata['number_line'] as Map
        : const <Object?, Object?>{};
    final xMin =
        (numberLine['min'] as num?)?.toDouble() ??
        (graph['x_min'] as num?)?.toDouble() ??
        -5.0;
    final xMax =
        (numberLine['max'] as num?)?.toDouble() ??
        (graph['x_max'] as num?)?.toDouble() ??
        5.0;
    final range = xMax - xMin;
    if (range <= 0) return;

    final y = size.height / 2;
    final margin = 14.0;
    final lineStart = margin;
    final lineEnd = size.width - margin;

    final linePaint = Paint()
      ..color = VisualTutorColors.blackInk
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = VisualTutorColors.cyan
      ..strokeWidth = 2;

    // Draw main axis line.
    canvas.drawLine(Offset(lineStart, y), Offset(lineEnd, y), linePaint);

    // Draw arrow caps.
    final arrowPaint = Paint()
      ..color = VisualTutorColors.blackInk
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(lineEnd, y), Offset(lineEnd - 8, y - 5), arrowPaint);
    canvas.drawLine(Offset(lineEnd, y), Offset(lineEnd - 8, y + 5), arrowPaint);
    canvas.drawLine(
      Offset(lineStart, y),
      Offset(lineStart + 8, y - 5),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(lineStart, y),
      Offset(lineStart + 8, y + 5),
      arrowPaint,
    );

    // Calculate sensible tick interval.
    final tickCount = (range.abs().clamp(4.0, 20.0)).round();
    final tickInterval = range / tickCount;

    double xToPixel(double x) =>
        lineStart + (x - xMin) / range * (lineEnd - lineStart);

    // Draw ticks and labels.
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= tickCount; i++) {
      final xVal = xMin + i * tickInterval;
      final px = xToPixel(xVal);
      // Major tick.
      canvas.drawLine(Offset(px, y - 8), Offset(px, y + 8), linePaint);
      // Label.
      final suppliedLabels = action.metadata['number_line'] is Map
          ? (action.metadata['number_line'] as Map)['labels']
          : null;
      final label = suppliedLabels is List && i < suppliedLabels.length
          ? suppliedLabels[i].toString()
          : xVal == xVal.roundToDouble()
          ? xVal.toInt().toString()
          : xVal.toStringAsFixed(1);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: VisualTutorColors.boardTextDark,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(px - textPainter.width / 2, y + 11));
    }

    // Draw highlighted points from action.points.
    final points = action.points;
    for (final point in points) {
      final xVal = (point['x'] as num?)?.toDouble();
      final label = point['label']?.toString() ?? point['y']?.toString() ?? '';
      if (xVal == null) continue;
      final px = xToPixel(xVal);
      // Draw filled circle.
      final open = point['open'] == true;
      if (open) {
        canvas.drawCircle(
          Offset(px, y),
          5,
          highlightPaint..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawCircle(
          Offset(px, y),
          5,
          highlightPaint..style = PaintingStyle.fill,
        );
      }
      // Label above.
      if (label.isNotEmpty) {
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(
            color: VisualTutorColors.cyan,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(px - textPainter.width / 2, y - 22));
      }
    }

    // Draw shaded region if metadata specifies one.
    final regionStart = (action.metadata['region_start'] as num?)?.toDouble();
    final regionEnd = (action.metadata['region_end'] as num?)?.toDouble();
    if (regionStart != null && regionEnd != null) {
      final rx1 = xToPixel(math.min(regionStart, regionEnd));
      final rx2 = xToPixel(math.max(regionStart, regionEnd));
      canvas.drawRect(
        Rect.fromLTWH(rx1, y - 10, rx2 - rx1, 20),
        Paint()..color = VisualTutorColors.cyan.withValues(alpha: .18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicNumberLinePainter oldDelegate) =>
      oldDelegate.action != action;
}

class BoardActionOverlay extends StatelessWidget {
  const BoardActionOverlay({
    super.key,
    required this.actions,
    required this.finalAnswerLocked,
  });

  final List<VisualTutorBoardActionEntity> actions;
  final bool finalAnswerLocked;

  @override
  Widget build(BuildContext context) {
    final visible =
        actions
            .where(
              (action) => isRenderableBoardAction(
                action,
                finalAnswerLocked: finalAnswerLocked,
              ),
            )
            .toList()
          ..sort((a, b) {
            final sequence = a.sequenceIndex.compareTo(b.sequenceIndex);
            if (sequence != 0) return sequence;
            return a.id.compareTo(b.id);
          });
    if (visible.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(320.0, 900.0);
            final scale = width / 390;
            return Stack(
              children: [
                for (final action in visible)
                  BoardElementRenderer(
                    action: action,
                    scale: scale,
                    faded: action.metadata['faded'] == true,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PositionedTextAction extends StatelessWidget {
  const _PositionedTextAction({
    required this.action,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.faded,
    required this.progress,
    required this.scale,
    required this.reducedMotion,
  });

  final VisualTutorBoardActionEntity action;
  final double left;
  final double top;
  final double width;
  final double height;
  final bool faded;
  final Animation<double> progress;
  final double scale;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final isEquation =
        action.type == 'write_equation' || action.type == 'transform_equation';
    final ink = _inkFor(action);
    final highlighted = action.metadata['highlighted'] == true;
    final focused = action.metadata['focused'] == true;
    final baseFontSize =
        ((action.style['size'] as num?)?.toDouble() ?? (isEquation ? 27 : 19)) *
        scale.clamp(.86, 1.1);
    // Respect device accessibility settings. Khmer combines glyphs vertically,
    // so the text remains unconstrained rather than being ellipsized mid-word.
    final fontSize = MediaQuery.textScalerOf(
      context,
    ).scale(baseFontSize).clamp(12.0, 42.0);

    // Keep the full spoken content as the accessible label. This preserves
    // Khmer word order for screen readers; the concise role is supplied as a
    // hint rather than being prepended to the learner-facing text.
    final semanticLabel = action.latex ?? action.text ?? 'Teaching board text';
    final semanticHint = switch (action.type) {
      'write_equation' ||
      'transform_equation' => 'Equation on the teaching board',
      'student_task' => 'Student task. Enter your answer below.',
      _ => null,
    };
    return Positioned(
      key: Key('teaching-board-action-${action.id}'),
      left: left,
      top: top,
      width: width,
      height: height,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: semanticLabel,
        hint: semanticHint,
        readOnly: true,
        child: AnimatedOpacity(
          key: Key('teaching-board-fade-${action.id}'),
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          opacity: faded ? .52 : 1,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              key: focused ? Key('teaching-board-focus-${action.id}') : null,
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: highlighted
                    ? VisualTutorColors.yellowHighlight.withValues(alpha: .45)
                    : (isEquation
                          ? Colors.transparent
                          : VisualTutorColors.boardPaperLine.withValues(
                              alpha: .35,
                            )),
                borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
                border: focused
                    ? Border.all(color: VisualTutorColors.cyan, width: 2.4)
                    : (highlighted
                          ? Border.all(
                              color: VisualTutorColors.orange,
                              width: 1.2,
                            )
                          : null),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: VisualTutorColors.cyan.withValues(alpha: .2),
                          blurRadius: 8,
                          spreadRadius: .4,
                        ),
                      ]
                    : const [],
              ),
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  final content = _visibleTextFor(action, progress.value);
                  final useLatex =
                      isEquation && (action.latex ?? '').trim().isNotEmpty;
                  final child = useLatex
                      ? ClipRect(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: reducedMotion
                                ? 1.0
                                : progress.value.clamp(0.02, 1.0),
                            child: _LatexEquation(
                              latex: content,
                              color: ink,
                              fontSize: fontSize,
                            ),
                          ),
                        )
                      : Text(
                          content,
                          softWrap: true,
                          maxLines: null,
                          overflow: TextOverflow.visible,
                          textDirection: Directionality.of(context),
                          style:
                              (isEquation
                                      ? VisualTutorTypography.boardEquation
                                      : VisualTutorTypography.boardHandwriting)
                                  .copyWith(
                                    color: ink,
                                    fontSize: fontSize,
                                    height: 1.3,
                                    fontStyle: isEquation
                                        ? FontStyle.normal
                                        : null,
                                  ),
                        );
                  if (!isEquation) return child;
                  return AnimatedSwitcher(
                    key: Key('teaching-board-transform-${action.id}'),
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previousChildren, ?currentChild],
                    ),
                    transitionBuilder: (switchChild, animation) =>
                        FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .06),
                              end: Offset.zero,
                            ).animate(animation),
                            child: switchChild,
                          ),
                        ),
                    child: KeyedSubtree(
                      key: ValueKey(
                        action.type == 'transform_equation'
                            ? '$content-${action.id}'
                            : action.id,
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _visibleTextFor(VisualTutorBoardActionEntity action, double progress) {
    final fullContent = action.latex ?? action.text ?? '';
    if (fullContent.isEmpty) return '';
    // An equation is revealed by clipping the drawn result, never by cutting
    // its LaTeX source: half of "\quad" is not valid LaTeX, and the renderer
    // would fall back to printing the raw command on the board.
    if (action.type != 'write_text') {
      return fullContent;
    }
    if (progress <= 0) return '';
    final visibleCharacters = (fullContent.length * progress)
        .ceil()
        .clamp(1, fullContent.length)
        .toInt();
    return fullContent.substring(0, visibleCharacters);
  }

  Color _inkFor(VisualTutorBoardActionEntity action) {
    final ink = action.style['ink']?.toString().toLowerCase();
    if (ink == 'blue') return VisualTutorColors.blueInk;
    if (ink == 'red') return VisualTutorColors.redInk;
    if (ink == 'green') return VisualTutorColors.success;
    return VisualTutorColors.blackInk;
  }
}

/// Preprocesses raw LaTeX equation strings to ensure clean rendering:
/// 1. Strips accidental outer delimiters: $$, $, \[, \], \(, \).
/// 2. Converts chemical reaction arrows: <=> and <-> to \rightleftharpoons, --> and -> to \rightarrow.
/// 3. Normalizes physics vectors and unit vectors: \vec v -> \vec{v}, \hat i -> \hat{i}.
String preprocessLatexEquation(String raw) {
  var s = raw.trim();

  // 1. Clean outer delimiters
  if (s.startsWith(r'$$') && s.endsWith(r'$$') && s.length >= 4) {
    s = s.substring(2, s.length - 2).trim();
  } else if (s.startsWith(r'$') && s.endsWith(r'$') && s.length >= 2) {
    s = s.substring(1, s.length - 1).trim();
  } else if (s.startsWith(r'\[') && s.endsWith(r'\]') && s.length >= 4) {
    s = s.substring(2, s.length - 2).trim();
  } else if (s.startsWith(r'\(') && s.endsWith(r'\)') && s.length >= 4) {
    s = s.substring(2, s.length - 2).trim();
  }

  // 2. Chemical reaction arrows
  s = s.replaceAll('<=>', r'\rightleftharpoons');
  s = s.replaceAll('<->', r'\rightleftharpoons');
  s = s.replaceAll('-->', r'\rightarrow');
  s = s.replaceAllMapped(
    RegExp(r'(?<!\\(?:right|left|long))-(?:-)?>(?![a-zA-Z])'),
    (_) => r'\rightarrow ',
  );

  // 3. Physics vectors and unit vectors
  s = s.replaceAllMapped(
    RegExp(r'\\vec\s+([a-zA-Z0-9])'),
    (m) => '\\vec{${m[1]}}',
  );
  s = s.replaceAllMapped(
    RegExp(r'\\hat\s+([a-zA-Z0-9])'),
    (m) => '\\hat{${m[1]}}',
  );

  return s;
}

class _LatexEquation extends StatelessWidget {
  const _LatexEquation({
    required this.latex,
    required this.color,
    required this.fontSize,
  });

  final String latex;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cleanLatex = preprocessLatexEquation(latex);
    // Attempt to render as proper LaTeX; fall back to plain text on parse failure.
    // flutter_math_fork's Math.tex() is the entry point. The onErrorFallback
    // receives a FlutterMathException and returns a fallback widget.
    try {
      final equation = Math.tex(
        cleanLatex,
        textStyle: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
        onErrorFallback: (_) => Text(
          cleanLatex,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            fontFamilyFallback: VisualTutorTypography.fontFallback,
          ),
        ),
      );
      // Math's inline renderer does not wrap equations. Scale down only when
      // necessary so universal chemistry notation and long formulae remain
      // within the semantic board slot on narrow phones.
      return LayoutBuilder(
        builder: (context, constraints) => FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: equation,
        ),
      );
    } catch (_) {
      return Text(
        cleanLatex,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamilyFallback: VisualTutorTypography.fontFallback,
        ),
      );
    }
  }
}

class _HighlightStrip extends StatefulWidget {
  const _HighlightStrip({required this.actionId, required this.reducedMotion});

  final String actionId;
  final bool reducedMotion;

  @override
  State<_HighlightStrip> createState() => _HighlightStripState();
}

class _HighlightStripState extends State<_HighlightStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.reducedMotion ? 1 : 0,
    );
    if (!widget.reducedMotion) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HighlightStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion == widget.reducedMotion) return;
    if (widget.reducedMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = Curves.easeOut.transform(_controller.value);
        return Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress,
            heightFactor: 1,
            child: DecoratedBox(
              key: Key('teaching-board-highlight-${widget.actionId}'),
              decoration: BoxDecoration(
                color: VisualTutorColors.yellowHighlight.withValues(
                  alpha: .3 + (.12 * progress),
                ),
                borderRadius: BorderRadius.circular(VisualTutorRadius.md),
                border: Border.all(
                  color: VisualTutorColors.orange,
                  width: 1.1 + (.2 * progress),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PointLabel extends StatelessWidget {
  const _PointLabel({required this.action});

  final VisualTutorBoardActionEntity action;

  @override
  Widget build(BuildContext context) {
    final label =
        action.text ??
        action.metadata['label']?.toString() ??
        action.id.replaceAll('-', ' ');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: const BoxDecoration(
            color: VisualTutorColors.blueInk,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: VisualTutorColors.blackInk,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamilyFallback: VisualTutorTypography.fontFallback,
            ),
          ),
        ),
      ],
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({
    required this.action,
    required this.progress,
    required this.reducedMotion,
  });

  final VisualTutorBoardActionEntity action;
  final Animation<double> progress;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final table = action.metadata['table'] is Map
        ? action.metadata['table'] as Map
        : const <Object?, Object?>{};
    final columns =
        (action.metadata['columns'] as List?) ??
        (table['columns'] as List?) ??
        const [];
    final rows =
        (action.metadata['rows'] as List?) ??
        (table['rows'] as List?) ??
        const [];
    final displayRows = <List<Object?>>[
      if (columns.isNotEmpty) columns.cast<Object?>(),
      ...rows.whereType<List>().map((row) => row.cast<Object?>()),
    ];
    final visibleRowCount = reducedMotion
        ? displayRows.length
        : (displayRows.length * progress.value).ceil().clamp(
            0,
            displayRows.length,
          );
    final summary = displayRows.map((row) => row.take(4).join(', ')).join('; ');
    return Semantics(
      container: true,
      label: 'Table: $summary',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .74),
          borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
          border: Border.all(color: VisualTutorColors.boardBorder),
        ),
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => Column(
            children: [
              for (var rowIndex = 0; rowIndex < visibleRowCount; rowIndex++)
                Expanded(
                  child: Row(
                    children: [
                      for (final cell in displayRows[rowIndex].take(4))
                        Expanded(
                          child: Center(
                            child: Text(
                              cell.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: VisualTutorColors.blackInk,
                                fontSize: 12,
                                fontWeight: rowIndex == 0 && columns.isNotEmpty
                                    ? FontWeight.w900
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperLines extends StatelessWidget {
  const _PaperLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PaperPainter());
  }
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = VisualTutorColors.boardPaperLine.withValues(alpha: .64)
      ..strokeWidth = 1;
    final dotPaint = Paint()
      ..color = VisualTutorColors.boardPaperDot.withValues(alpha: .45)
      ..strokeWidth = 1;
    for (double y = 42; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (double x = 24; x < size.width; x += 36) {
      for (double y = 22; y < size.height; y += 36) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AxesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * .18, size.height * .72);
    final paint = Paint()
      ..color = VisualTutorColors.blackInk.withValues(alpha: .78)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .08, origin.dy),
      Offset(size.width * .9, origin.dy),
      paint,
    );
    canvas.drawLine(
      Offset(origin.dx, size.height * .18),
      Offset(origin.dx, size.height * .86),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShapeActionPainter extends CustomPainter {
  const _ShapeActionPainter({
    required this.action,
    required this.scale,
    required this.progress,
  });

  final VisualTutorBoardActionEntity action;
  final double scale;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final isRed = action.type == 'cross_out' || action.style['ink'] == 'red';
    final paint = Paint()
      ..color = isRed ? VisualTutorColors.redInk : VisualTutorColors.blackInk
      ..strokeWidth = isRed ? 2.8 : 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (action.type == 'circle') {
      final rect = Rect.fromLTWH(
        (action.x ?? 40) * scale,
        action.y ?? 40,
        (action.width ?? 90) * scale,
        action.height ?? 46,
      );
      canvas.drawArc(rect, 0, math.pi * 2 * progress.clamp(0, 1), false, paint);
      return;
    }

    if (action.type == 'draw_rectangle') {
      final rect = Rect.fromLTWH(
        (action.x ?? 40) * scale,
        action.y ?? 40,
        (action.width ?? 90) * scale,
        action.height ?? 46,
      );
      final path = Path()..addRect(rect);
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * progress.clamp(0, 1)),
          paint,
        );
      }
      return;
    }

    if (action.type == 'cross_out') {
      final rect = Rect.fromLTWH(
        (action.x ?? 40) * scale,
        action.y ?? 40,
        (action.width ?? 120) * scale,
        action.height ?? 44,
      );
      _line(canvas, rect.topLeft, rect.bottomRight, paint);
      _line(canvas, rect.bottomLeft, rect.topRight, paint);
      return;
    }

    final arrowPoints = action.type == 'draw_arrow' && action.points.length >= 2
        ? action.points.take(2).toList(growable: false)
        : null;
    final start = arrowPoints == null
        ? Offset((action.x ?? 40) * scale, action.y ?? 40)
        : Offset(
            (arrowPoints.first['x'] as num).toDouble() * scale,
            (arrowPoints.first['y'] as num).toDouble(),
          );
    final end = arrowPoints == null
        ? Offset(
            ((action.x ?? 40) + (action.width ?? 120)) * scale,
            (action.y ?? 40) + (action.height ?? 0),
          )
        : Offset(
            (arrowPoints.last['x'] as num).toDouble() * scale,
            (arrowPoints.last['y'] as num).toDouble(),
          );
    _line(canvas, start, end, paint);
    if (action.type == 'draw_arrow' && progress >= .82) {
      final direction = (end - start);
      final length = direction.distance;
      if (length > 1) {
        final unit = direction / length;
        final tip = Offset.lerp(start, end, progress.clamp(0, 1).toDouble())!;
        final wing = math.min(10.0, length * .18);
        final left = Offset(
          tip.dx - unit.dx * wing - unit.dy * wing * .58,
          tip.dy - unit.dy * wing + unit.dx * wing * .58,
        );
        final right = Offset(
          tip.dx - unit.dx * wing + unit.dy * wing * .58,
          tip.dy - unit.dy * wing - unit.dx * wing * .58,
        );
        canvas.drawLine(tip, left, paint);
        canvas.drawLine(tip, right, paint);
      }
    }
  }

  void _line(Canvas canvas, Offset start, Offset end, Paint paint) {
    final current = Offset.lerp(start, end, progress.clamp(0, 1).toDouble())!;
    canvas.drawLine(start, current, paint);
  }

  @override
  bool shouldRepaint(covariant _ShapeActionPainter oldDelegate) {
    return oldDelegate.action != action ||
        oldDelegate.scale != scale ||
        oldDelegate.progress != progress;
  }
}

class _StructuredGraphPainter extends CustomPainter {
  const _StructuredGraphPainter(this.graph);

  final Map<String, dynamic> graph;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = VisualTutorColors.blackInk.withValues(alpha: .72)
      ..strokeWidth = 1.5;
    final curvePaint = Paint()
      ..color = VisualTutorColors.blueInk
      ..strokeWidth = 2.3
      ..style = PaintingStyle.stroke;
    final xMin = (graph['x_min'] as num).toDouble();
    final xMax = (graph['x_max'] as num).toDouble();
    final yMin = (graph['y_min'] as num).toDouble();
    final yMax = (graph['y_max'] as num).toDouble();
    double sx(double x) => (x - xMin) / (xMax - xMin) * size.width;
    double sy(double y) =>
        size.height - (y - yMin) / (yMax - yMin) * size.height;
    if (xMin <= 0 && xMax >= 0) {
      canvas.drawLine(Offset(0, sy(0)), Offset(size.width, sy(0)), axisPaint);
    }
    if (yMin <= 0 && yMax >= 0) {
      canvas.drawLine(Offset(sx(0), 0), Offset(sx(0), size.height), axisPaint);
    }

    final points = graph['points'];
    if (points is List) {
      final pointPaint = Paint()..color = VisualTutorColors.cyan;
      for (final point in points.whereType<Map>()) {
        final x = point['x'];
        final y = point['y'];
        if (x is num && y is num) {
          canvas.drawCircle(
            Offset(sx(x.toDouble()), sy(y.toDouble())),
            4,
            pointPaint,
          );
        }
      }
    }
    final annotations = graph['annotations'];
    if (annotations is List) {
      for (final annotation in annotations.whereType<Map>()) {
        final text = annotation['text'];
        final x = annotation['x'];
        final y = annotation['y'];
        if (text is! String || x is! num || y is! num) continue;
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              color: VisualTutorColors.blueInk,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: size.width * .45);
        painter.paint(
          canvas,
          Offset(sx(x.toDouble()) + 5, sy(y.toDouble()) - 16),
        );
      }
    }
    final expression = graph['function_expression']?.toString();
    final evaluator = _safePolynomialEvaluator(expression);
    if (evaluator == null) return;
    final path = Path();
    var drawing = false;
    for (var i = 0; i <= 80; i++) {
      final x = xMin + (xMax - xMin) * i / 80;
      final y = evaluator(x);
      if (!y.isFinite || y < yMin - (yMax - yMin) || y > yMax + (yMax - yMin)) {
        drawing = false;
        continue;
      }
      final point = Offset(sx(x), sy(y));
      if (!drawing) {
        path.moveTo(point.dx, point.dy);
        drawing = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(covariant _StructuredGraphPainter oldDelegate) =>
      oldDelegate.graph != graph;
}

double Function(double)? _safePolynomialEvaluator(String? expression) {
  if (expression == null) return null;
  final compact = expression
      .toLowerCase()
      .replaceAll(' ', '')
      .replaceFirst('y=', '');
  // Deliberately small allow-list: straight lines and parabolas are sufficient
  // for the graph actions this renderer claims to support. Other functions still
  // retain axes/points rather than being guessed or evaluated as code.
  final quadratic = RegExp(
    r'^([+-]?(?:\d+(?:\.\d+)?)?)\*?x\^2(?:([+-]\d+(?:\.\d+)?)\*?x)?(?:([+-]\d+(?:\.\d+)?))?$',
  ).firstMatch(compact);
  if (quadratic != null) {
    double coefficient(String? value, {double empty = 1}) =>
        value == null || value.isEmpty || value == '+'
        ? empty
        : value == '-'
        ? -empty
        : double.parse(value);
    final a = coefficient(quadratic.group(1));
    final b = quadratic.group(2) == null
        ? 0
        : double.parse(quadratic.group(2)!);
    final c = quadratic.group(3) == null
        ? 0
        : double.parse(quadratic.group(3)!);
    return (x) => a * x * x + b * x + c;
  }
  final line = RegExp(
    r'^([+-]?(?:\d+(?:\.\d+)?)?)\*?x(?:([+-]\d+(?:\.\d+)?))?$',
  ).firstMatch(compact);
  if (line != null) {
    final raw = line.group(1);
    final slope = raw == null || raw.isEmpty || raw == '+'
        ? 1
        : raw == '-'
        ? -1
        : double.parse(raw);
    final intercept = line.group(2) == null ? 0 : double.parse(line.group(2)!);
    return (x) => slope * x + intercept;
  }
  return null;
}

// ── Physics: Free Body Diagram ────────────────────────────────────────────────

/// Renders a simple free body diagram: a square "object" box with labeled
/// force arrows pointing in the directions specified by `action.metadata`.
///
/// Expected metadata shape:
/// ```json
/// {
///   "object_label": "Block",
///   "forces": [
///     {"direction": "up",    "label": "N",  "magnitude": 20},
///     {"direction": "down",  "label": "mg", "magnitude": 20},
///     {"direction": "right", "label": "F",  "magnitude": 10},
///     {"direction": "left",  "label": "f",  "magnitude": 5}
///   ]
/// }
/// ```
class _FreeBodyDiagramPainter extends CustomPainter {
  const _FreeBodyDiagramPainter({required this.action});

  final VisualTutorBoardActionEntity action;

  static const _boxFraction = 0.25;
  static const _arrowHead = 8.0;
  static const _lineWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VisualTutorColors.blueInk
      ..strokeWidth = _lineWidth
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final boxSide = math.min(size.width, size.height) * _boxFraction;
    final halfBox = boxSide / 2;

    // Draw object box
    final boxRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: boxSide,
      height: boxSide,
    );
    canvas.drawRect(boxRect, paint..style = PaintingStyle.stroke);

    // Label the object
    final objectLabel = action.metadata['object_label']?.toString() ?? '';
    if (objectLabel.isNotEmpty) {
      _drawLabel(canvas, objectLabel, Offset(cx, cy), size, bold: true);
    }

    // Draw forces
    final forces = action.metadata['forces'];
    if (forces is List) {
      for (final force in forces) {
        if (force is! Map) continue;
        final dir = force['direction']?.toString() ?? '';
        final label = force['label']?.toString() ?? '';
        final magnitude = (force['magnitude'] as num?)?.toDouble() ?? 1.0;
        final arrowLen =
            math.min(size.width, size.height) *
            0.25 *
            magnitude.clamp(0.5, 2.0);
        Offset start;
        Offset end;
        switch (dir) {
          case 'up':
            start = Offset(cx, cy - halfBox);
            end = Offset(cx, cy - halfBox - arrowLen);
          case 'down':
            start = Offset(cx, cy + halfBox);
            end = Offset(cx, cy + halfBox + arrowLen);
          case 'right':
            start = Offset(cx + halfBox, cy);
            end = Offset(cx + halfBox + arrowLen, cy);
          case 'left':
            start = Offset(cx - halfBox, cy);
            end = Offset(cx - halfBox - arrowLen, cy);
          default:
            continue;
        }
        _drawArrow(canvas, start, end, paint..color = VisualTutorColors.cyan);
        _drawLabel(canvas, label, end, size);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final p1 = Offset(
      to.dx - _arrowHead * math.cos(angle - 0.4),
      to.dy - _arrowHead * math.sin(angle - 0.4),
    );
    final p2 = Offset(
      to.dx - _arrowHead * math.cos(angle + 0.4),
      to.dy - _arrowHead * math.sin(angle + 0.4),
    );
    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset pos,
    Size size, {
    bool bold = false,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: VisualTutorColors.blueInk,
        fontSize: 12,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        fontFamilyFallback: VisualTutorTypography.fontFallback,
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(pos.dx + 4, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_FreeBodyDiagramPainter old) => old.action.id != action.id;
}

// ── Chemistry: Molecule Diagram ───────────────────────────────────────────────

/// Renders a simple molecule bond diagram.
///
/// Expected metadata shape:
/// ```json
/// {
///   "atoms": [
///     {"symbol": "C", "x": 0.5, "y": 0.5},
///     {"symbol": "H", "x": 0.2, "y": 0.5}
///   ],
///   "bonds": [
///     {"from": 0, "to": 1, "order": 1}
///   ]
/// }
/// ```
/// Coordinates are fractions of the widget size (0–1).
class _MoleculePainter extends CustomPainter {
  const _MoleculePainter({required this.action});

  final VisualTutorBoardActionEntity action;

  static const _atomRadius = 14.0;
  static const _bondWidth = 2.0;
  static const _bondGap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rawAtoms = action.metadata['atoms'];
    final rawBonds = action.metadata['bonds'];
    if (rawAtoms is! List) return;

    final atomPositions = <Offset>[];
    for (final atom in rawAtoms) {
      if (atom is! Map) continue;
      final fx = (atom['x'] as num?)?.toDouble() ?? 0.5;
      final fy = (atom['y'] as num?)?.toDouble() ?? 0.5;
      atomPositions.add(Offset(fx * size.width, fy * size.height));
    }

    // Draw bonds first (under atoms)
    final bondPaint = Paint()
      ..color = VisualTutorColors.blueInk
      ..strokeWidth = _bondWidth
      ..style = PaintingStyle.stroke;

    if (rawBonds is List) {
      for (final bond in rawBonds) {
        if (bond is! Map) continue;
        final fromIdx = (bond['from'] as num?)?.toInt() ?? 0;
        final toIdx = (bond['to'] as num?)?.toInt() ?? 0;
        final order = (bond['order'] as num?)?.toInt() ?? 1;
        if (fromIdx >= atomPositions.length || toIdx >= atomPositions.length) {
          continue;
        }
        final p1 = atomPositions[fromIdx];
        final p2 = atomPositions[toIdx];
        if (order >= 2) {
          // Double / triple bond: parallel lines
          final dx = p2.dx - p1.dx;
          final dy = p2.dy - p1.dy;
          final len = math.sqrt(dx * dx + dy * dy);
          final nx = -dy / len * _bondGap;
          final ny = dx / len * _bondGap;
          canvas.drawLine(
            p1.translate(nx, ny),
            p2.translate(nx, ny),
            bondPaint,
          );
          canvas.drawLine(
            p1.translate(-nx, -ny),
            p2.translate(-nx, -ny),
            bondPaint,
          );
          if (order >= 3) {
            canvas.drawLine(p1, p2, bondPaint);
          }
        } else {
          canvas.drawLine(p1, p2, bondPaint);
        }
      }
    }

    // Draw atom circles + labels
    final circlePaint = Paint()..style = PaintingStyle.fill;
    int i = 0;
    for (final atom in rawAtoms) {
      if (atom is! Map || i >= atomPositions.length) break;
      final pos = atomPositions[i++];
      final symbol = atom['symbol']?.toString() ?? 'X';
      final color = _atomColor(symbol);
      circlePaint.color = color;
      canvas.drawCircle(pos, _atomRadius, circlePaint);
      final span = TextSpan(
        text: symbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  Color _atomColor(String symbol) {
    return switch (symbol.toUpperCase()) {
      'C' => const Color(0xFF2D2D2D),
      'H' => const Color(0xFF757575),
      'O' => const Color(0xFFD32F2F),
      'N' => const Color(0xFF1565C0),
      'S' => const Color(0xFFF9A825),
      'CL' => const Color(0xFF2E7D32),
      'NA' => const Color(0xFF6A1B9A),
      _ => VisualTutorColors.cyan,
    };
  }

  @override
  bool shouldRepaint(_MoleculePainter old) => old.action.id != action.id;
}

// ── Physics: Wave Diagram ─────────────────────────────────────────────────────

/// Renders a sinusoidal wave with optional amplitude/wavelength labels.
///
/// Expected metadata shape:
/// ```json
/// {
///   "amplitude_label": "A",
///   "wavelength_label": "λ",
///   "cycles": 2,
///   "wave_type": "transverse"
/// }
/// ```
class _WavePainter extends CustomPainter {
  const _WavePainter({required this.action});

  final VisualTutorBoardActionEntity action;

  @override
  void paint(Canvas canvas, Size size) {
    final meta = action.metadata;
    final cycles = (meta['cycles'] as num?)?.toDouble() ?? 1.5;
    final ampLabel = meta['amplitude_label']?.toString() ?? '';
    final waveLabel = meta['wavelength_label']?.toString() ?? '';

    final cx = size.width / 2;
    final cy = size.height / 2;
    final amplitude = size.height * 0.32;
    final wavelength = size.width / cycles;

    final wavePaint = Paint()
      ..color = VisualTutorColors.cyan
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw the sine wave
    final path = Path();
    bool first = true;
    for (double x = 0; x <= size.width; x += 1) {
      final y = cy - amplitude * math.sin(2 * math.pi * x / wavelength);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);

    // Draw horizontal axis
    final axisPaint = Paint()
      ..color = VisualTutorColors.blueInk.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), axisPaint);

    // Amplitude annotation
    if (ampLabel.isNotEmpty) {
      final labelPaint = Paint()
        ..color = VisualTutorColors.blueInk
        ..strokeWidth = 1;
      // Vertical brace arrow for amplitude
      canvas.drawLine(Offset(8, cy), Offset(8, cy - amplitude), labelPaint);
      _drawText(canvas, ampLabel, Offset(12, cy - amplitude / 2 - 8));
    }

    // Wavelength annotation
    if (waveLabel.isNotEmpty) {
      final labelPaint = Paint()
        ..color = VisualTutorColors.blueInk
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(cx, cy + amplitude + 10),
        Offset(cx + wavelength, cy + amplitude + 10),
        labelPaint,
      );
      _drawText(
        canvas,
        waveLabel,
        Offset(cx + wavelength / 2 - 8, cy + amplitude + 14),
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos) {
    final span = TextSpan(
      text: text,
      style: const TextStyle(
        color: VisualTutorColors.blueInk,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.action.id != action.id;
}

// ── Bounded STEM primitives ─────────────────────────────────────────────────
// These painters consume only fields validated in the public teaching-plan
// contract. They intentionally provide a small, teachable vocabulary rather
// than accepting SVG, paths, HTML, JavaScript, or generated widget code.

class _AtomModelPainter extends CustomPainter {
  const _AtomModelPainter({required this.action});
  final VisualTutorBoardActionEntity action;

  @override
  void paint(Canvas canvas, Size size) {
    final atom = Map<String, dynamic>.from(
      action.metadata['atom_model'] as Map,
    );
    final center = Offset(size.width / 2, size.height / 2);
    final shells = List<dynamic>.from(atom['electrons_per_shell'] as List);
    final orbit = Paint()
      ..color = VisualTutorColors.blueInk.withValues(alpha: .45)
      ..style = PaintingStyle.stroke;
    final electron = Paint()..color = VisualTutorColors.cyan;
    for (var shell = 0; shell < shells.length; shell++) {
      final radius = 20.0 + shell * math.min(size.width, size.height) * .10;
      canvas.drawCircle(center, radius, orbit);
      final count = shells[shell] as int;
      for (var index = 0; index < count; index++) {
        final angle = 2 * math.pi * index / math.max(1, count);
        canvas.drawCircle(
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
          3.5,
          electron,
        );
      }
    }
    canvas.drawCircle(center, 16, Paint()..color = VisualTutorColors.blueInk);
    _paintCenteredLabel(
      canvas,
      '${atom['symbol']}\n${atom['protons']}p ${atom['neutrons']}n',
      center,
      Colors.white,
    );
  }

  @override
  bool shouldRepaint(_AtomModelPainter old) => old.action.id != action.id;
}

class _ParticleDiagramPainter extends CustomPainter {
  const _ParticleDiagramPainter({required this.action});
  final VisualTutorBoardActionEntity action;
  @override
  void paint(Canvas canvas, Size size) {
    final spec = Map<String, dynamic>.from(
      action.metadata['particle_diagram'] as Map,
    );
    final count = spec['particle_count'] as int;
    final state = spec['state'] as String;
    final columns = math.min(6, math.max(1, math.sqrt(count).ceil()));
    final rows = (count / columns).ceil();
    final particle = Paint()..color = VisualTutorColors.cyan;
    for (var index = 0; index < count; index++) {
      final column = index % columns;
      final row = index ~/ columns;
      final baseX = (column + .5) * size.width / columns;
      final baseY = (row + .5) * size.height / rows;
      final offset = switch (state) {
        'solid' => Offset.zero,
        'liquid' => Offset(
          (index * 7 % 9 - 4).toDouble(),
          (index * 11 % 7 - 3).toDouble(),
        ),
        _ => Offset(
          (index * 19 % 23 - 11).toDouble(),
          (index * 13 % 17 - 8).toDouble(),
        ),
      };
      canvas.drawCircle(Offset(baseX, baseY) + offset, 5, particle);
    }
  }

  @override
  bool shouldRepaint(_ParticleDiagramPainter old) => old.action.id != action.id;
}

class _CircuitDiagramPainter extends CustomPainter {
  const _CircuitDiagramPainter({required this.action});
  final VisualTutorBoardActionEntity action;
  @override
  void paint(Canvas canvas, Size size) {
    final components = List<dynamic>.from(
      (action.metadata['circuit_diagram'] as Map)['components'] as List,
    );
    final paint = Paint()
      ..color = VisualTutorColors.blueInk
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    final left = 16.0;
    final right = size.width - 16.0;
    canvas.drawLine(Offset(left, y - 28), Offset(right, y - 28), paint);
    canvas.drawLine(Offset(left, y + 28), Offset(right, y + 28), paint);
    canvas.drawLine(Offset(left, y - 28), Offset(left, y + 28), paint);
    canvas.drawLine(Offset(right, y - 28), Offset(right, y + 28), paint);
    for (var index = 0; index < components.length; index++) {
      final component = components[index] as Map;
      final x = left + (index + 1) * (right - left) / (components.length + 1);
      final kind = component['kind'] as String;
      if (kind == 'cell') {
        canvas.drawLine(Offset(x - 4, y - 38), Offset(x - 4, y - 18), paint);
        canvas.drawLine(Offset(x + 4, y - 42), Offset(x + 4, y - 14), paint);
      }
      if (kind == 'resistor') {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y - 28), width: 22, height: 12),
          paint,
        );
      }
      if (kind == 'lamp') {
        canvas.drawCircle(Offset(x, y - 28), 10, paint);
        canvas.drawLine(Offset(x - 7, y - 35), Offset(x + 7, y - 21), paint);
        canvas.drawLine(Offset(x - 7, y - 21), Offset(x + 7, y - 35), paint);
      }
      if (kind == 'switch') {
        canvas.drawCircle(
          Offset(x - 9, y - 28),
          2,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x - 7, y - 28), Offset(x + 9, y - 37), paint);
      }
      final label = component['label'];
      if (label is String && label.isNotEmpty) {
        _paintCenteredLabel(
          canvas,
          label,
          Offset(x, y + 7),
          VisualTutorColors.blueInk,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CircuitDiagramPainter old) => old.action.id != action.id;
}

class _ReactionLayoutPainter extends CustomPainter {
  const _ReactionLayoutPainter({required this.action});
  final VisualTutorBoardActionEntity action;
  @override
  void paint(Canvas canvas, Size size) {
    final spec = Map<String, dynamic>.from(
      action.metadata['reaction_layout'] as Map,
    );
    final terms = <String>[
      ...List<String>.from(spec['reactants'] as List),
      '→',
      ...List<String>.from(spec['products'] as List),
    ];
    final coefficients = spec['coefficients'] is List
        ? List<int>.from(spec['coefficients'] as List)
        : const <int>[];
    final formulaTerms = <String>[];
    var coefficientIndex = 0;
    for (final term in terms) {
      if (term == '→') {
        formulaTerms.add(term);
        continue;
      }
      final coefficient = coefficients.isEmpty
          ? 1
          : coefficients[coefficientIndex++];
      formulaTerms.add('${coefficient == 1 ? '' : coefficient}$term');
    }
    _paintCenteredLabel(
      canvas,
      formulaTerms.join(' + ').replaceFirst(' + → + ', ' → '),
      Offset(size.width / 2, size.height / 2),
      VisualTutorColors.blueInk,
      fontSize: 18,
    );
  }

  @override
  bool shouldRepaint(_ReactionLayoutPainter old) => old.action.id != action.id;
}

void _paintCenteredLabel(
  Canvas canvas,
  String text,
  Offset center,
  Color color, {
  double fontSize = 11,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: VisualTutorTypography.fontFallback,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 220);
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}
