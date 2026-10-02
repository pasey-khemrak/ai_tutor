/// The voice and the hand must stay on the same step.
///
/// The tutor used to speak one summary paragraph per turn, ~420ms in, while
/// the board silently wrote the entire solution underneath it. Each step of a
/// worked solution already carries its own sentence of prose, so the board now
/// reads that line while it writes it, and does not start the next step until
/// the sentence has been said.
///
/// The risk in gating playback on speech is a lesson that freezes when the
/// voice service is slow or absent, so these tests pin the escape hatches as
/// hard as they pin the feature.
library;

import 'dart:async';

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pacing.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const steps = [
    VisualTutorBoardActionEntity(
      id: 'step-1',
      type: 'write_text',
      text: 'Substitute',
      sequenceIndex: 0,
      durationMs: 160,
    ),
    VisualTutorBoardActionEntity(
      id: 'step-2',
      type: 'write_text',
      text: 'Factor',
      sequenceIndex: 1,
      durationMs: 160,
    ),
  ];

  Widget buildBoard({
    Future<void> Function(VisualTutorBoardActionEntity)? onNarrate,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 360,
          child: TeachingCanvasBoard(
            actions: steps,
            finalAnswerLocked: false,
            // Verbatim keeps these assertions about narration rather than
            // about how long the sample text takes to write.
            pacing: const BoardPacing.verbatim(),
            onNarrate: onNarrate,
          ),
        ),
      ),
    );
  }

  Finder action(String id) => find.byKey(Key('teaching-board-action-$id'));

  testWidgets('each written step is narrated, in the order it is written', (
    tester,
  ) async {
    final narrated = <String>[];
    await tester.pumpWidget(
      buildBoard(
        onNarrate: (action) async {
          narrated.add(action.id);
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(narrated, ['step-1', 'step-2']);
  });

  testWidgets('the next step waits for the current one to be spoken', (
    tester,
  ) async {
    final holdFirstStep = Completer<void>();
    await tester.pumpWidget(
      buildBoard(
        onNarrate: (action) =>
            action.id == 'step-1' ? holdFirstStep.future : Future.value(),
      ),
    );

    // Well past the 160ms the first step takes to write.
    await tester.pump(const Duration(seconds: 2));
    expect(
      action('step-2'),
      findsNothing,
      reason: 'the board ran ahead of the voice explaining step 1',
    );

    holdFirstStep.complete();
    await tester.pumpAndSettle();
    expect(action('step-2'), findsOneWidget);
  });

  testWidgets('a narrator that throws does not strand the lesson', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBoard(
        onNarrate: (action) async {
          throw StateError('voice service is down');
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(action('step-1'), findsOneWidget);
    expect(action('step-2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a board with no narrator plays exactly as before', (
    tester,
  ) async {
    await tester.pumpWidget(buildBoard());
    await tester.pumpAndSettle();

    expect(action('step-1'), findsOneWidget);
    expect(action('step-2'), findsOneWidget);
  });

  testWidgets('narration runs alongside the stroke, not after it', (
    tester,
  ) async {
    // A teacher talks while writing. If narration only started once the
    // stroke had finished, the voice would always trail the board by a full
    // action.
    DateTime? narrationStarted;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 360,
            child: TeachingCanvasBoard(
              actions: const [
                VisualTutorBoardActionEntity(
                  id: 'slow',
                  type: 'write_text',
                  text: 'A long line that takes a while to write',
                  sequenceIndex: 0,
                  durationMs: 1500,
                ),
              ],
              finalAnswerLocked: false,
              pacing: const BoardPacing.verbatim(),
              onNarrate: (action) async {
                narrationStarted ??= DateTime.now();
              },
            ),
          ),
        ),
      ),
    );
    // One frame in: the stroke is under way and nowhere near its 1500ms.
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      narrationStarted,
      isNotNull,
      reason: 'the voice waited for the hand to finish before speaking',
    );
    await tester.pumpAndSettle();
  });
}
