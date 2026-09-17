import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCanvas({
    required List<VisualTutorBoardActionEntity> actions,
    required ValueChanged<BoardStudentInteraction> onStudentInteraction,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 420,
          child: TeachingCanvasBoard(
            actions: actions,
            finalAnswerLocked: true,
            reducedMotion: true,
            onStudentInteraction: onStudentInteraction,
          ),
        ),
      ),
    );
  }

  const equation = VisualTutorBoardActionEntity(
    id: 'equation-step',
    type: 'write_equation',
    latex: '2x - 5 = 10',
    x: 36,
    y: 54,
    width: 230,
    height: 52,
  );

  testWidgets(
    'tapping an equation selects it and exposes an explanation action',
    (tester) async {
      final interactions = <BoardStudentInteraction>[];
      await tester.pumpWidget(
        buildCanvas(
          actions: const [equation],
          onStudentInteraction: interactions.add,
        ),
      );

      await tester.tap(
        find.byKey(const Key('teaching-board-action-equation-step-tap-target')),
      );
      await tester.pump();

      expect(
        interactions
            .where((event) => event.kind == 'selection')
            .map((event) => event.actionId),
        contains('equation-step'),
      );
      expect(
        find.byKey(const Key('teaching-board-explain-equation-step')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('teaching-board-explain-equation-step')),
      );
      await tester.pump();
      expect(
        interactions
            .where((event) => event.kind == 'explain')
            .map((event) => event.actionId),
        contains('equation-step'),
      );
    },
  );

  testWidgets('create_blank and student_task submit only typed student input', (
    tester,
  ) async {
    final interactions = <BoardStudentInteraction>[];
    await tester.pumpWidget(
      buildCanvas(
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'operation-blank',
            type: 'create_blank',
            x: 36,
            y: 72,
            width: 190,
            height: 46,
            requiresStudentResponse: true,
          ),
          VisualTutorBoardActionEntity(
            id: 'reason-task',
            type: 'student_task',
            text: 'Why do we apply the inverse operation?',
            x: 36,
            y: 150,
            width: 300,
            height: 60,
            requiresStudentResponse: true,
          ),
        ],
        onStudentInteraction: interactions.add,
      ),
    );

    await tester.enterText(
      find.byKey(const Key('teaching-board-answer-operation-blank')),
      'add 5',
    );
    await tester.tap(
      find.byKey(const Key('teaching-board-answer-submit-operation-blank')),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('teaching-board-answer-reason-task')),
      'It cancels negative five.',
    );
    await tester.tap(
      find.byKey(const Key('teaching-board-answer-submit-reason-task')),
    );
    await tester.pump();

    final answers = interactions.where((event) => event.kind == 'answer');
    expect(
      answers.map((event) => (event.actionId, event.value)),
      containsAll(<(String, String)>[
        ('operation-blank', 'add 5'),
        ('reason-task', 'It cancels negative five.'),
      ]),
    );
  });

  testWidgets(
    'student ink supports undo then redo without mutating AI actions',
    (tester) async {
      final interactions = <BoardStudentInteraction>[];
      await tester.pumpWidget(
        buildCanvas(
          actions: const [equation],
          onStudentInteraction: interactions.add,
        ),
      );

      await tester.tap(find.byKey(const Key('student-ink-pen')));
      await tester.pump();
      final canvas = find.byKey(const Key('student-ink-canvas'));
      await tester.dragFrom(
        tester.getCenter(canvas),
        const Offset(48, 30),
        touchSlopX: 0,
        touchSlopY: 0,
      );
      await tester.pump();

      IconButton control(String key) =>
          tester.widget<IconButton>(find.byKey(Key(key)));
      expect(control('student-ink-undo').onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('student-ink-undo')));
      await tester.pump();
      expect(control('student-ink-redo').onPressed, isNotNull);
      expect(
        find.byKey(const Key('teaching-board-action-equation-step')),
        findsOneWidget,
        reason: 'Undo must affect student ink only, never the tutor board.',
      );

      await tester.tap(find.byKey(const Key('student-ink-redo')));
      await tester.pump();
      expect(control('student-ink-undo').onPressed, isNotNull);
    },
  );

  testWidgets('reset to fit restores the board after a student pan', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCanvas(actions: const [equation], onStudentInteraction: (_) {}),
    );

    final equationFinder = find.byKey(
      const Key('teaching-board-action-equation-step'),
    );
    final initialPosition = tester.getTopLeft(equationFinder);

    final firstFinger = await tester.startGesture(const Offset(150, 250));
    final secondFinger = await tester.startGesture(const Offset(270, 250));
    await firstFinger.moveBy(const Offset(-42, 0));
    await secondFinger.moveBy(const Offset(42, 0));
    await firstFinger.up();
    await secondFinger.up();
    await tester.pumpAndSettle();
    final pannedPosition = tester.getTopLeft(equationFinder);
    expect(pannedPosition, isNot(initialPosition));

    await tester.tap(find.byKey(const Key('visual-tutor-board-reset-fit')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(equationFinder), initialPosition);
  });
}
