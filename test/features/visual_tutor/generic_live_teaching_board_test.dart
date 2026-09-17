import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildBoard({
    required String variant,
    required List<VisualTutorBoardActionEntity> actions,
    bool finalAnswerLocked = true,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 720,
          height: 760,
          child: LiveTeachingBoard(
            // These special states used to replace current-turn actions with
            // fixed lesson widgets. They must now use the generic renderer.
            variant: variant,
            finalAnswerLocked: finalAnswerLocked,
            board: const VisualTutorBoardEntity(
              type: 'equation_steps',
              metadata: {
                'handwritten_question': 'Fixed template text must not appear',
                'final_answer': 'Fixed template answer must not appear',
              },
            ),
            actions: actions,
          ),
        ),
      ),
    );
  }

  const graph = <String, dynamic>{
    'x_min': -4,
    'x_max': 4,
    'y_min': -4,
    'y_max': 8,
    'function_expression': 'x^2 - 1',
    'domain': [-4, 4],
    'points': [
      {'x': 0, 'y': -1, 'label': 'vertex'},
    ],
  };

  testWidgets(
    'asking-question state renders every safe current-turn action instead of a template',
    (tester) async {
      const actions = [
        VisualTutorBoardActionEntity(
          id: 'equation',
          type: 'write_equation',
          latex: '2x + 10 = 20',
          sequenceIndex: 0,
          x: 24,
          y: 24,
          width: 280,
        ),
        VisualTutorBoardActionEntity(
          id: 'explanation',
          type: 'write_text',
          text: 'Let us keep both sides balanced.',
          sequenceIndex: 1,
          x: 24,
          y: 92,
          width: 360,
        ),
        VisualTutorBoardActionEntity(
          id: 'transform',
          type: 'transform_equation',
          latex: '2x + 10 - 10 = 20 - 10',
          sequenceIndex: 2,
          x: 24,
          y: 152,
          width: 420,
        ),
        VisualTutorBoardActionEntity(
          id: 'highlight',
          type: 'highlight',
          sequenceIndex: 3,
          x: 20,
          y: 146,
          width: 250,
          height: 46,
        ),
        VisualTutorBoardActionEntity(
          id: 'arrow',
          type: 'draw_arrow',
          sequenceIndex: 4,
          x: 220,
          y: 172,
          width: 80,
          height: 32,
        ),
        VisualTutorBoardActionEntity(
          id: 'hint',
          type: 'show_hint',
          text: 'Use the inverse of adding 10.',
          sequenceIndex: 5,
          x: 24,
          y: 222,
          width: 360,
        ),
        VisualTutorBoardActionEntity(
          id: 'feedback',
          type: 'show_feedback',
          text: 'You are ready for one small step.',
          sequenceIndex: 6,
          x: 24,
          y: 274,
          width: 360,
        ),
        VisualTutorBoardActionEntity(
          id: 'task',
          type: 'student_task',
          text: 'Write the equation after subtracting 10 from both sides.',
          sequenceIndex: 7,
          x: 24,
          y: 334,
          width: 460,
          requiresStudentResponse: true,
        ),
        VisualTutorBoardActionEntity(
          id: 'number-line',
          type: 'show_number_line',
          sequenceIndex: 8,
          x: 24,
          y: 406,
          width: 340,
          height: 60,
        ),
        VisualTutorBoardActionEntity(
          id: 'axes',
          type: 'draw_axes',
          sequenceIndex: 9,
          x: 380,
          y: 406,
          width: 220,
          height: 160,
        ),
        VisualTutorBoardActionEntity(
          id: 'graph',
          type: 'show_graph',
          sequenceIndex: 10,
          x: 24,
          y: 490,
          width: 220,
          height: 160,
          graph: graph,
        ),
        VisualTutorBoardActionEntity(
          id: 'function',
          type: 'plot_function',
          sequenceIndex: 11,
          x: 272,
          y: 490,
          width: 220,
          height: 160,
          graph: graph,
        ),
        VisualTutorBoardActionEntity(
          id: 'annotation',
          type: 'graph_annotation',
          text: 'Vertex at (0, -1)',
          sequenceIndex: 12,
          x: 500,
          y: 510,
          width: 180,
        ),
        VisualTutorBoardActionEntity(
          id: 'table',
          type: 'show_table',
          sequenceIndex: 13,
          x: 500,
          y: 560,
          width: 180,
          height: 100,
          metadata: {
            'rows': [
              ['x', 'y'],
              [0, -1],
            ],
          },
        ),
      ];

      await tester.pumpWidget(
        buildBoard(variant: 'asking_question', actions: actions),
      );

      // Equations and transformations can use Math.tex; their action keys are
      // the stable renderer contract. Other current-turn actions remain text.
      expect(
        find.byKey(const Key('teaching-board-action-equation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('teaching-board-action-transform')),
        findsOneWidget,
      );
      for (final text in const [
        'Let us keep both sides balanced.',
        'Use the inverse of adding 10.',
        'You are ready for one small step.',
        'Write the equation after subtracting 10 from both sides.',
        'Vertex at (0, -1)',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.byKey(const Key('teaching-board-highlight')), findsOneWidget);
      expect(
        find.byKey(const Key('teaching-board-draw_arrow-arrow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('teaching-board-number-line-number-line')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('teaching-board-axes')), findsOneWidget);
      expect(
        find.byKey(const Key('teaching-board-graph-graph')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('teaching-board-function-function')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('teaching-board-table-table')),
        findsOneWidget,
      );
      expect(find.text('Fixed template text must not appear'), findsNothing);
    },
  );

  testWidgets('generic action order follows AI sequence and coordinates', (
    tester,
  ) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'later-in-list-but-first-on-board',
        type: 'write_text',
        text: 'First teaching step',
        sequenceIndex: 0,
        x: 30,
        y: 50,
        width: 250,
      ),
      VisualTutorBoardActionEntity(
        id: 'second',
        type: 'write_text',
        text: 'Second teaching step',
        sequenceIndex: 1,
        x: 30,
        y: 170,
        width: 250,
      ),
      VisualTutorBoardActionEntity(
        id: 'task',
        type: 'student_task',
        text: 'Your turn.',
        sequenceIndex: 2,
        x: 30,
        y: 280,
        width: 250,
        requiresStudentResponse: true,
      ),
    ];

    await tester.pumpWidget(
      buildBoard(variant: 'check_my_work', actions: actions),
    );

    final firstTop = tester.getTopLeft(find.text('First teaching step')).dy;
    final secondTop = tester.getTopLeft(find.text('Second teaching step')).dy;
    final taskTop = tester.getTopLeft(find.text('Your turn.')).dy;
    expect(firstTop, lessThan(secondTop));
    expect(secondTop, lessThan(taskTop));
  });

  testWidgets(
    'final reveal action is hidden while locked and rendered when policy unlocks it',
    (tester) async {
      const actions = [
        VisualTutorBoardActionEntity(
          id: 'final-answer',
          type: 'final_answer_reveal',
          text: 'x = 5',
          sequenceIndex: 0,
          x: 24,
          y: 40,
          width: 240,
          revealPolicy: 'verified_final',
        ),
        VisualTutorBoardActionEntity(
          id: 'task',
          type: 'student_task',
          text: 'Check the solution first.',
          sequenceIndex: 1,
          x: 24,
          y: 120,
          width: 260,
          requiresStudentResponse: true,
        ),
      ];

      await tester.pumpWidget(
        buildBoard(
          variant: 'final_verified_answer',
          actions: actions,
          finalAnswerLocked: true,
        ),
      );
      expect(find.text('x = 5'), findsNothing);

      await tester.pumpWidget(
        buildBoard(
          variant: 'final_verified_answer',
          actions: actions,
          finalAnswerLocked: false,
        ),
      );
      expect(find.text('x = 5'), findsOneWidget);
      expect(find.text('Fixed template answer must not appear'), findsNothing);
    },
  );

  testWidgets('hidden current-turn actions never occupy the generic board', (
    tester,
  ) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'visible',
        type: 'write_text',
        text: 'Visible teaching message',
        sequenceIndex: 0,
        x: 24,
        y: 24,
        width: 260,
      ),
      VisualTutorBoardActionEntity(
        id: 'hidden',
        type: 'write_text',
        text: 'Hidden answer',
        sequenceIndex: 1,
        x: 24,
        y: 90,
        width: 260,
        hidden: true,
      ),
      VisualTutorBoardActionEntity(
        id: 'task',
        type: 'student_task',
        text: 'Try this first.',
        sequenceIndex: 2,
        x: 24,
        y: 150,
        width: 260,
        requiresStudentResponse: true,
      ),
    ];

    await tester.pumpWidget(
      buildBoard(variant: 'final_verified_answer', actions: actions),
    );

    expect(find.text('Visible teaching message'), findsOneWidget);
    expect(find.text('Hidden answer'), findsNothing);
    expect(find.text('Try this first.'), findsOneWidget);
  });
}
