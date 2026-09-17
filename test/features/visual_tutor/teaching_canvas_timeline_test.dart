import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCanvas(
    List<VisualTutorBoardActionEntity> actions, {
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
            reducedMotion: reducedMotion,
            restored: restored,
          ),
        ),
      ),
    );
  }

  Finder action(String id) => find.byKey(Key('teaching-board-action-$id'));

  testWidgets('plays visible actions by sequence index and waits at a pause', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCanvas(const [
        VisualTutorBoardActionEntity(
          id: 'third',
          type: 'write_text',
          text: 'Third action',
          sequenceIndex: 30,
          durationMs: 160,
        ),
        VisualTutorBoardActionEntity(
          id: 'pause',
          type: 'pause_marker',
          sequenceIndex: 20,
          durationMs: 420,
        ),
        VisualTutorBoardActionEntity(
          id: 'first',
          type: 'write_text',
          text: 'First action',
          sequenceIndex: 10,
          durationMs: 160,
        ),
      ]),
    );
    await tester.pump();

    expect(action('first'), findsOneWidget);
    expect(action('third'), findsNothing);

    // The first action completes, then the pause marker holds the timeline.
    await tester.pump(const Duration(milliseconds: 200));
    expect(action('third'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(action('third'), findsNothing);

    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(action('third'), findsOneWidget);
  });

  testWidgets('a new board turn cancels pending playback from the old turn', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCanvas(const [
        VisualTutorBoardActionEntity(
          id: 'old-first',
          type: 'write_text',
          text: 'Old first',
          sequenceIndex: 0,
          durationMs: 160,
        ),
        VisualTutorBoardActionEntity(
          id: 'old-pause',
          type: 'pause_marker',
          sequenceIndex: 1,
          durationMs: 900,
        ),
        VisualTutorBoardActionEntity(
          id: 'old-late',
          type: 'write_text',
          text: 'Old late',
          sequenceIndex: 2,
          durationMs: 160,
        ),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(
      buildCanvas(const [
        VisualTutorBoardActionEntity(
          id: 'new-first',
          type: 'write_text',
          text: 'New first',
          sequenceIndex: 0,
          durationMs: 160,
        ),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(action('new-first'), findsOneWidget);
    expect(action('old-first'), findsNothing);
    expect(action('old-late'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a speech marker gates the next action when the contract asks it to',
    (tester) async {
      await tester.pumpWidget(
        buildCanvas(const [
          VisualTutorBoardActionEntity(
            id: 'speech',
            type: 'speak_marker',
            sequenceIndex: 0,
            durationMs: 420,
            waitForSpeechMarker: true,
          ),
          VisualTutorBoardActionEntity(
            id: 'after-speech',
            type: 'write_text',
            text: 'After speech',
            sequenceIndex: 1,
            durationMs: 160,
          ),
        ]),
      );
      await tester.pump();

      expect(action('after-speech'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(action('after-speech'), findsNothing);
      await tester.pump(const Duration(milliseconds: 160));
      await tester.pump();
      expect(action('after-speech'), findsOneWidget);
    },
  );

  testWidgets(
    'mounts the first final visual immediately after a zero-duration speak marker',
    (tester) async {
      await tester.pumpWidget(
        buildCanvas(const [
          VisualTutorBoardActionEntity(
            id: 'speak',
            type: 'speak_marker',
            sequenceIndex: 0,
            durationMs: 0,
          ),
          VisualTutorBoardActionEntity(
            id: 'authoritative-equation',
            type: 'write_equation',
            latex: '2x = 30',
            x: 40,
            y: 178,
            width: 560,
            height: 56,
            sequenceIndex: 1,
            durationMs: 420,
          ),
          VisualTutorBoardActionEntity(
            id: 'pause',
            type: 'pause_marker',
            sequenceIndex: 2,
            durationMs: 650,
          ),
          VisualTutorBoardActionEntity(
            id: 'task',
            type: 'student_task',
            text: 'What operation should we apply?',
            requiresStudentResponse: true,
            sequenceIndex: 3,
          ),
        ]),
      );
      await tester.pump();

      expect(action('authoritative-equation'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(action('task'), findsOneWidget);
    },
  );

  testWidgets('disposing the board safely cancels a pending pause', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCanvas(const [
        VisualTutorBoardActionEntity(
          id: 'pause',
          type: 'pause_marker',
          durationMs: 1000,
        ),
        VisualTutorBoardActionEntity(
          id: 'late',
          type: 'write_text',
          text: 'Must not render after dispose',
          sequenceIndex: 1,
        ),
      ]),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1200));

    expect(action('late'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replay restarts the current board turn from its first action', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCanvas(const [
        VisualTutorBoardActionEntity(
          id: 'first',
          type: 'write_text',
          text: 'First action',
          sequenceIndex: 0,
          durationMs: 160,
        ),
        VisualTutorBoardActionEntity(
          id: 'second',
          type: 'write_text',
          text: 'Second action',
          sequenceIndex: 1,
          durationMs: 160,
        ),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 200));
    expect(action('first'), findsOneWidget);
    expect(action('second'), findsOneWidget);

    await tester.tap(find.byKey(const Key('visual-tutor-board-replay')));
    await tester.pump();

    expect(action('first'), findsOneWidget);
    expect(action('second'), findsNothing);
  });

  testWidgets(
    'a restored board is instantly visible and only replays after student request',
    (tester) async {
      await tester.pumpWidget(
        buildCanvas(
          const [
            VisualTutorBoardActionEntity(
              id: 'saved-first',
              type: 'write_text',
              text: 'Saved first action',
              sequenceIndex: 0,
              durationMs: 400,
            ),
            VisualTutorBoardActionEntity(
              id: 'saved-second',
              type: 'write_text',
              text: 'Saved second action',
              sequenceIndex: 1,
              durationMs: 400,
            ),
          ],
          restored: true,
        ),
      );
      await tester.pump();

      expect(action('saved-first'), findsOneWidget);
      expect(action('saved-second'), findsOneWidget);

      await tester.tap(find.byKey(const Key('visual-tutor-board-replay')));
      await tester.pump();

      expect(action('saved-first'), findsOneWidget);
      expect(
        action('saved-second'),
        findsNothing,
        reason: 'Restore must be instant, but an explicit replay starts the saved turn over.',
      );
      await tester.pump(const Duration(milliseconds: 450));
      expect(action('saved-second'), findsOneWidget);
    },
  );

  testWidgets('play/pause freezes and resumes the current board timeline', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCanvas(const [
        VisualTutorBoardActionEntity(
          id: 'first',
          type: 'write_text',
          text: 'First action',
          sequenceIndex: 0,
          durationMs: 700,
        ),
        VisualTutorBoardActionEntity(
          id: 'second',
          type: 'write_text',
          text: 'Second action',
          sequenceIndex: 1,
          durationMs: 160,
        ),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('visual-tutor-board-play-pause')));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    expect(action('second'), findsNothing);

    await tester.tap(find.byKey(const Key('visual-tutor-board-play-pause')));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    expect(action('second'), findsOneWidget);
  });

  testWidgets('reduced motion makes the entire timeline immediately visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCanvas(const [
        VisualTutorBoardActionEntity(
          id: 'first',
          type: 'write_text',
          text: 'First action',
          sequenceIndex: 0,
        ),
        VisualTutorBoardActionEntity(
          id: 'pause',
          type: 'pause_marker',
          sequenceIndex: 1,
          durationMs: 1800,
        ),
        VisualTutorBoardActionEntity(
          id: 'last',
          type: 'write_text',
          text: 'Last action',
          sequenceIndex: 2,
        ),
      ], reducedMotion: true),
    );
    await tester.pump();

    expect(action('first'), findsOneWidget);
    expect(action('last'), findsOneWidget);
  });
}
