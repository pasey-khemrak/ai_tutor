import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  });

  final VisualTutorBoardActionEntity action;
  final double scale;
  final bool faded;
  final Animation<double> progress;

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
        child: const _HighlightStrip(),
      ),
      'circle' || 'cross_out' || 'draw_line' || 'draw_arrow' => Positioned.fill(
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
      'draw_axes' => Positioned.fill(
        child: CustomPaint(
          key: const Key('teaching-board-axes'),
          painter: _AxesPainter(),
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
        child: _TableView(action: action),
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .58),
            borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
            border: Border.all(color: VisualTutorColors.blueInk),
          ),
          child: RepaintBoundary(
            child: CustomPaint(painter: _StructuredGraphPainter(action.graph!)),
          ),
        ),
      ),
      'plot_function' => Positioned(
        key: Key('teaching-board-function-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: RepaintBoundary(
          child: CustomPaint(painter: _StructuredGraphPainter(action.graph!)),
        ),
      ),
      'show_number_line' => Positioned(
        key: Key('teaching-board-number-line-${action.id}'),
        left: left,
        top: top,
        width: width,
        height: height,
        child: const CustomPaint(painter: _NumberLinePainter()),
      ),
      'write_text' ||
      'write_equation' ||
      'transform_equation' ||
      'show_hint' ||
      'show_feedback' ||
      'student_task' ||
      'graph_annotation' => _PositionedTextAction(
        action: action,
        left: left,
        top: top,
        width: width,
        height: height,
        faded: effectiveFaded,
        progress: progress,
        scale: scale,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _NumberLinePainter extends CustomPainter {
  const _NumberLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VisualTutorColors.blackInk
      ..strokeWidth = 2;
    final y = size.height / 2;
    canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), paint);
    for (var index = 0; index < 6; index++) {
      final x = 18 + (size.width - 36) * index / 5;
      canvas.drawLine(Offset(x, y - 7), Offset(x, y + 7), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NumberLinePainter oldDelegate) => false;
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
  });

  final VisualTutorBoardActionEntity action;
  final double left;
  final double top;
  final double width;
  final double height;
  final bool faded;
  final Animation<double> progress;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final isEquation = action.type == 'write_equation';
    final ink = _inkFor(action);
    final highlighted = action.metadata['highlighted'] == true;
    final focused = action.metadata['focused'] == true;
    final fontSize =
        ((action.style['size'] as num?)?.toDouble() ?? (isEquation ? 27 : 19)) *
        scale.clamp(.86, 1.1);

    return Positioned(
      key: Key('teaching-board-action-${action.id}'),
      left: left,
      top: top,
      width: width,
      height: height,
      child: Opacity(
        opacity: faded ? .52 : 1,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
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
                  ? Border.all(color: VisualTutorColors.cyan, width: 2)
                  : (highlighted
                        ? Border.all(
                            color: VisualTutorColors.orange,
                            width: 1.2,
                          )
                        : null),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) => Text(
                  _visibleTextFor(action, progress.value),
                  maxLines: 1,
                  style:
                      (isEquation
                              ? VisualTutorTypography.boardEquation
                              : VisualTutorTypography.boardHandwriting)
                          .copyWith(
                            color: ink,
                            fontSize: fontSize,
                            fontStyle: isEquation ? FontStyle.normal : null,
                          ),
                ),
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
    if (action.type != 'write_text' && action.type != 'write_equation') {
      return fullContent;
    }
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

class _HighlightStrip extends StatelessWidget {
  const _HighlightStrip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VisualTutorColors.yellowHighlight.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(VisualTutorRadius.md),
        border: Border.all(color: VisualTutorColors.orange, width: 1.3),
      ),
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
  const _TableView({required this.action});

  final VisualTutorBoardActionEntity action;

  @override
  Widget build(BuildContext context) {
    final rows = (action.metadata['rows'] as List?) ?? const [];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .74),
        borderRadius: BorderRadius.circular(VisualTutorRadius.sm),
        border: Border.all(color: VisualTutorColors.boardBorder),
      ),
      child: Column(
        children: [
          for (final row in rows.take(4))
            Expanded(
              child: Row(
                children: [
                  for (final cell in ((row as List?) ?? const []).take(4))
                    Expanded(
                      child: Center(
                        child: Text(
                          cell.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VisualTutorColors.blackInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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

    final start = Offset((action.x ?? 40) * scale, action.y ?? 40);
    final end = Offset(
      ((action.x ?? 40) + (action.width ?? 120)) * scale,
      (action.y ?? 40) + (action.height ?? 0),
    );
    _line(canvas, start, end, paint);
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
