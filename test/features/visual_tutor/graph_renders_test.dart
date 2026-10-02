/// A graph action must actually put ink on the board.
///
/// The server now sends show_graph for quadratics, limits and kinematics, and
/// the board paginated it onto a page of its own -- which came out blank. The
/// payload passes the client's own validator, so the question is whether the
/// painter draws anything when handed a real one.
///
/// The payloads here are copied from the deployed service, not invented.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/board_element_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The quadratic turn as the live service returns it.
const _quadraticGraph = <String, dynamic>{
  'x_min': 0.8,
  'x_max': 4.2,
  'y_min': -0.548,
  'y_max': 2.488,
  'function_expression': 'x^2-5x+6',
  'points': [
    {'x': 2.0, 'y': 0.0},
    {'x': 3.0, 'y': 0.0},
  ],
};

Future<int> _inkPixels(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  final bytes = data!.buffer.asUint8List();
  return _countInk(bytes);
}

/// Anything meaningfully darker than the board's pale panel counts as drawn.
int _countInk(Uint8List bytes) {
  var count = 0;
  for (var index = 0; index < bytes.length; index += 4) {
    final r = bytes[index];
    final g = bytes[index + 1];
    final b = bytes[index + 2];
    final a = bytes[index + 3];
    if (a > 180 && (r + g + b) / 3 < 170) count++;
  }
  return count;
}

void main() {
  testWidgets('a graph action paints a curve rather than an empty panel', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 400),
      value: 1,
    );
    addTearDown(controller.dispose);
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 420,
              height: 280,
              child: Stack(
                children: [
                  BoardElementRenderer(
                    action: const VisualTutorBoardActionEntity(
                      id: 'ws-graph-1',
                      type: 'show_graph',
                      x: 0,
                      y: 0,
                      width: 420,
                      height: 280,
                      graph: _quadraticGraph,
                    ),
                    progress: controller,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final ink = (await tester.runAsync(() => _inkPixels(key)))!;
    expect(
      ink,
      greaterThan(200),
      reason: 'the graph panel rendered with no curve, axes or points on it',
    );
  });

  /// Every CustomPaint-based primitive shared the same fault: the painter had
  /// no child and no explicit size, so under the loose constraints that
  /// Align(widthFactor:) hands down it collapsed to nothing. The existing
  /// primitive tests all passed because they assert on the widget tree, which
  /// was correct -- only the pixels were missing.
  Future<int> paintAction(
    WidgetTester tester,
    VisualTutorBoardActionEntity action,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 400),
      value: 1,
    );
    addTearDown(controller.dispose);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 420,
              height: 280,
              child: Stack(
                children: [
                  BoardElementRenderer(action: action, progress: controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    return (await tester.runAsync(() => _inkPixels(key)))!;
  }

  testWidgets('axes paint', (tester) async {
    final ink = await paintAction(
      tester,
      const VisualTutorBoardActionEntity(
        id: 'a',
        type: 'draw_axes',
        x: 0,
        y: 0,
        width: 420,
        height: 280,
      ),
    );
    expect(ink, greaterThan(100), reason: 'draw_axes painted nothing');
  });

  testWidgets('plot_function paints', (tester) async {
    final ink = await paintAction(
      tester,
      const VisualTutorBoardActionEntity(
        id: 'a',
        type: 'plot_function',
        x: 0,
        y: 0,
        width: 420,
        height: 280,
        graph: _quadraticGraph,
      ),
    );
    expect(ink, greaterThan(200), reason: 'plot_function painted nothing');
  });

  testWidgets('a number line paints', (tester) async {
    final ink = await paintAction(
      tester,
      const VisualTutorBoardActionEntity(
        id: 'a',
        type: 'show_number_line',
        x: 0,
        y: 0,
        width: 420,
        height: 120,
        graph: {'x_min': -5.0, 'x_max': 5.0, 'y_min': -1.0, 'y_max': 1.0},
      ),
    );
    expect(ink, greaterThan(50), reason: 'show_number_line painted nothing');
  });
}
