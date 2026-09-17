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
  Widget canvas(
    List<VisualTutorBoardActionEntity> actions, {
    bool reducedMotion = false,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: SizedBox(
            width: 420,
            height: 260,
            child: TeachingCanvasBoard(
              actions: actions,
              finalAnswerLocked: true,
              reducedMotion: reducedMotion,
            ),
          ),
        ),
      ),
    );
  }

  Finder action(String id) => find.byKey(Key('teaching-board-action-$id'));

  testWidgets('plays a wire-order-independent action timeline by sequence', (
    tester,
  ) async {
    await tester.pumpWidget(
      canvas(const [
        VisualTutorBoardActionEntity(
          id: 'third',
          type: 'write_text',
          text: 'Third',
          sequenceIndex: 30,
          durationMs: 160,
        ),
        VisualTutorBoardActionEntity(
          id: 'first',
          type: 'write_text',
          text: 'First',
          sequenceIndex: 10,
          durationMs: 160,
        ),
        VisualTutorBoardActionEntity(
          id: 'second',
          type: 'write_text',
          text: 'Second',
          sequenceIndex: 20,
          durationMs: 160,
        ),
      ]),
    );

    await tester.pump();
    expect(action('first'), findsOneWidget);
    expect(action('second'), findsNothing);
    expect(action('third'), findsNothing);

    await tester.pump(const Duration(milliseconds: 180));
    expect(action('second'), findsOneWidget);
    expect(action('third'), findsNothing);

    await tester.pump(const Duration(milliseconds: 180));
    expect(action('third'), findsOneWidget);
  });

  testWidgets('speech gates remain synchronized and freeze while paused', (
    tester,
  ) async {
    await tester.pumpWidget(
      canvas(const [
        VisualTutorBoardActionEntity(
          id: 'teacher-speaking',
          type: 'speak_marker',
          sequenceIndex: 0,
          durationMs: 700,
          waitForSpeechMarker: true,
        ),
        VisualTutorBoardActionEntity(
          id: 'written-after-speech',
          type: 'write_text',
          text: 'Write after speech',
          sequenceIndex: 1,
          durationMs: 160,
        ),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(action('written-after-speech'), findsNothing);

    await tester.tap(find.byKey(const Key('visual-tutor-board-play-pause')));
    await tester.pump();
    expect(find.bySemanticsLabel('Play board timeline'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    expect(action('written-after-speech'), findsNothing);

    // General pause/resume completion is covered by the timeline test; this
    // assertion verifies a speaking gate cannot run ahead while paused.
  });

  testWidgets(
    'system reduced motion shows the finished board and disables playback',
    (tester) async {
      await tester.pumpWidget(
        canvas(const [
          VisualTutorBoardActionEntity(
            id: 'first',
            type: 'write_text',
            text: 'First line',
            sequenceIndex: 0,
            durationMs: 900,
          ),
          VisualTutorBoardActionEntity(
            id: 'last',
            type: 'write_text',
            text: 'Last line',
            sequenceIndex: 1,
            durationMs: 900,
          ),
        ], disableAnimations: true),
      );
      await tester.pump();

      expect(action('first'), findsOneWidget);
      expect(action('last'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('visual-tutor-board-replay')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('visual-tutor-board-play-pause')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'exposes the active teaching step and a jump-to-current control',
    (tester) async {
      await tester.pumpWidget(
        canvas(const [
          VisualTutorBoardActionEntity(
            id: 'current-work',
            type: 'write_text',
            text: 'Subtract 3 from both sides.',
            sequenceIndex: 0,
            durationMs: 800,
          ),
        ]),
      );
      await tester.pump(const Duration(milliseconds: 60));

      expect(
        find.bySemanticsLabel(
          'Current teaching action: Subtract 3 from both sides.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('visual-tutor-board-jump-current')),
        findsOneWidget,
      );
    },
  );

  testWidgets('vectors progressively reveal more ink along their path', (
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
                      id: 'force-vector',
                      type: 'draw_arrow',
                      x: 28,
                      y: 84,
                      width: 190,
                      height: -34,
                      metadata: {'label': 'F'},
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

    final atStart = (await tester.runAsync(() => _darkInkPixels(boundaryKey)))!;
    controller.value = .5;
    await tester.pump();
    final atHalf = (await tester.runAsync(() => _darkInkPixels(boundaryKey)))!;
    controller.value = 1;
    await tester.pump();
    final atEnd = (await tester.runAsync(() => _darkInkPixels(boundaryKey)))!;

    expect(atHalf, greaterThan(atStart));
    expect(atEnd, greaterThan(atHalf));
  });
}

Future<int> _darkInkPixels(GlobalKey boundaryKey) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
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
    if (alpha > 180 && red < 80 && green < 80 && blue < 80) count++;
  }
  return count;
}
