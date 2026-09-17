import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/board_element_renderer.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCanvas({
    required List<VisualTutorBoardActionEntity> actions,
    bool reducedMotion = false,
    bool restored = false,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 360,
          child: TeachingCanvasBoard(
            actions: actions,
            finalAnswerLocked: true,
            actionInterval: Duration.zero,
            reducedMotion: reducedMotion,
            restored: restored,
          ),
        ),
      ),
    );
  }

  const textAction = VisualTutorBoardActionEntity(
    id: 'progressive-text',
    type: 'write_text',
    text: 'Live writing',
    x: 28,
    y: 72,
    width: 260,
    durationMs: 600,
  );

  testWidgets('writes text progressively before revealing the full sentence', (
    tester,
  ) async {
    await tester.pumpWidget(buildCanvas(actions: const [textAction]));
    await tester.pump();

    expect(find.text('Live writing'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data ?? '').isNotEmpty &&
            widget.data != 'Live writing',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Live writing'), findsNothing);

    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('Live writing'), findsOneWidget);
  });

  testWidgets('progressively draws a line and a circle as progress advances', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 400),
      value: 0,
    );
    addTearDown(controller.dispose);
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 320,
              height: 180,
              child: Stack(
                children: [
                  BoardElementRenderer(
                    action: const VisualTutorBoardActionEntity(
                      id: 'line',
                      type: 'draw_line',
                      x: 28,
                      y: 36,
                      width: 180,
                      height: 0,
                    ),
                    progress: controller,
                  ),
                  BoardElementRenderer(
                    action: const VisualTutorBoardActionEntity(
                      id: 'circle',
                      type: 'circle',
                      x: 48,
                      y: 82,
                      width: 110,
                      height: 48,
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

    final atStart = (await tester.runAsync(
      () => _darkInkPixels(boundaryKey),
    ))!;
    controller.value = .5;
    await tester.pump();
    final atHalf = (await tester.runAsync(
      () => _darkInkPixels(boundaryKey),
    ))!;
    controller.value = 1;
    await tester.pump();
    final atEnd = (await tester.runAsync(
      () => _darkInkPixels(boundaryKey),
    ))!;

    expect(atHalf, greaterThan(atStart));
    expect(atEnd, greaterThan(atHalf));
  });

  testWidgets('reduced-motion mode renders a full board immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCanvas(actions: const [textAction], reducedMotion: true),
    );
    await tester.pump();

    expect(find.text('Live writing'), findsOneWidget);
  });

  testWidgets('restored sessions render a full board immediately', (tester) async {
    await tester.pumpWidget(
      buildCanvas(actions: const [textAction], restored: true),
    );
    await tester.pump();

    expect(find.text('Live writing'), findsOneWidget);
  });
}

Future<int> _darkInkPixels(GlobalKey boundaryKey) async {
  final boundary = boundaryKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  final bytes = data!.buffer.asUint8List();
  return _countDarkPixels(bytes);
}

int _countDarkPixels(Uint8List bytes) {
  var count = 0;
  for (var index = 0; index < bytes.length; index += 4) {
    final red = bytes[index];
    final green = bytes[index + 1];
    final blue = bytes[index + 2];
    final alpha = bytes[index + 3];
    if (alpha > 180 && red < 80 && green < 80 && blue < 80) {
      count++;
    }
  }
  return count;
}
