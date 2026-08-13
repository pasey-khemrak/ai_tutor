import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildBoard({
    required String variant,
    VisualTutorBoardEntity? board,
    List<VisualTutorBoardActionEntity> actions = const [],
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 520,
          child: LiveTeachingBoard(
            variant: variant,
            board: board,
            actions: actions,
          ),
        ),
      ),
    );
  }

  testWidgets('handwritten equation renders', (tester) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'speaking_writing',
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'equation',
            type: 'write_equation',
            latex: '2x + 5 = 15',
          ),
          VisualTutorBoardActionEntity(
            id: 'note',
            type: 'write_text',
            sequenceIndex: 1,
            text: 'Integration by Parts',
            style: {'ink': 'blue'},
          ),
        ],
      ),
    );

    expect(find.text('2x + 5 = 15'), findsOneWidget);
    expect(find.text('Integration by Parts'), findsOneWidget);
  });

  testWidgets('yellow highlight renders', (tester) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'speaking_writing',
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'highlight',
            type: 'highlight',
            x: 40,
            y: 80,
            width: 120,
            height: 48,
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('teaching-board-highlight')), findsOneWidget);
  });

  testWidgets('red mistake marker renders', (tester) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'check_my_work',
        board: const VisualTutorBoardEntity(
          type: 'check_my_work',
          metadata: {
            'problem': '2x + 5 = 15',
            'student_step': '2x = 15 + 5',
            'mistake_message': 'Check your sign here!',
          },
        ),
      ),
    );

    expect(find.byKey(const Key('check-work-board')), findsOneWidget);
    expect(find.byKey(const Key('red-mistake-marker')), findsOneWidget);
    expect(find.text('Check your sign here!'), findsOneWidget);
  });

  testWidgets('check work board renders live action overlay states', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'check_my_work',
        board: const VisualTutorBoardEntity(
          type: 'check_my_work',
          metadata: {'problem': '3x - 9 = 12', 'student_step': '3x = 3'},
        ),
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'focused-step',
            type: 'write_equation',
            latex: '3x = 21',
            x: 42,
            y: 180,
            metadata: {'highlighted': true, 'focused': true},
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('check-work-board')), findsOneWidget);
    expect(find.text('3x = 21'), findsOneWidget);
  });

  testWidgets('structured quadratic graph renders without a fabricated curve', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'graph_based',
        board: const VisualTutorBoardEntity(
          type: 'graph_hint',
          metadata: {
            'screen_state': 'graph_based',
            'equation_title': 'y = x² - 1',
            'instruction': 'Find the vertex.',
          },
        ),
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'quadratic',
            type: 'plot_function',
            width: 320,
            height: 240,
            graph: {
              'x_min': -4,
              'x_max': 4,
              'y_min': -3,
              'y_max': 8,
              'x_label': 'x',
              'y_label': 'y',
              'function_expression': 'x^2-1',
              'domain': [-4, 4],
              'points': [
                {'x': 0, 'y': -1, 'label': 'vertex'},
              ],
              'annotations': [
                {'text': 'vertex', 'x': 0, 'y': -1},
              ],
            },
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('graph-based-board')), findsOneWidget);
    expect(
      find.byKey(const Key('teaching-board-function-quadratic')),
      findsOneWidget,
    );
    expect(find.text('y = x² - 1'), findsOneWidget);
    expect(find.text('Find the vertex.'), findsOneWidget);
    expect(find.byKey(const Key('graph-instruction-chip')), findsOneWidget);
  });

  testWidgets(
    'unknown actions never render as text and use one safe recovery',
    (tester) async {
      await tester.pumpWidget(
        buildBoard(
          variant: 'speaking_writing',
          actions: const [
            VisualTutorBoardActionEntity(
              id: 'unsafe',
              type: 'run_javascript',
              text: '<script>alert(1)</script>',
            ),
          ],
        ),
      );

      expect(
        find.byKey(const Key('visual-tutor-board-recovery')),
        findsOneWidget,
      );
      expect(find.text('<script>alert(1)</script>'), findsNothing);
    },
  );

  testWidgets('board recovery has a screen-reader announcement', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildBoard(
        variant: 'speaking_writing',
        actions: const [
          VisualTutorBoardActionEntity(id: 'unsafe', type: 'run_javascript'),
        ],
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp('Visual board recovery')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets(
    'large board payload renders only the recent safe action window',
    (tester) async {
      final actions = List.generate(
        150,
        (index) => VisualTutorBoardActionEntity(
          id: 'action-$index',
          type: 'write_text',
          text: 'Step $index',
          sequenceIndex: index,
        ),
      );
      await tester.pumpWidget(
        buildBoard(variant: 'speaking_writing', actions: actions),
      );

      expect(find.text('Step 0'), findsNothing);
      expect(find.text('Step 149'), findsOneWidget);
    },
  );

  testWidgets('asking question board renders blank dashed box', (tester) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'asking_question',
        board: const VisualTutorBoardEntity(
          type: 'asking_question',
          metadata: {
            'faded_previous_equation': '∫ x e^x dx',
            'handwritten_question':
                'What is the integral of e to the power of x?',
            'equation_with_blank': '∫ e^x dx =',
          },
        ),
      ),
    );

    expect(find.byKey(const Key('asking-question-board')), findsOneWidget);
    expect(find.text('∫ x e^x dx'), findsOneWidget);
    expect(
      find.text('What is the integral of e to the power of x?'),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('asking-question-handwritten-question')),
          )
          .dy,
      lessThan(260),
    );
    expect(find.byKey(const Key('question-dashed-blank')), findsOneWidget);
  });

  testWidgets('final result card renders', (tester) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'final_verified_answer',
        board: const VisualTutorBoardEntity(
          type: 'final_verified_answer',
          title: 'Linear Equation',
          metadata: {
            'final_answer': 'x = 5',
            'worked_solution': ['2x + 5 = 15', '2x = 10', 'x = 5'],
            'summary': {
              'key_formula': 'Keep both sides balanced.',
              'applied_rule': 'Inverse operations',
            },
            'mastery_message': 'Great job! You’ve mastered this problem.',
          },
        ),
      ),
    );

    expect(find.byKey(const Key('final-answer-board')), findsOneWidget);
    expect(find.byKey(const Key('verified-pill')), findsOneWidget);
    expect(find.text('PROBLEM SOLVED'), findsOneWidget);
    expect(find.byKey(const Key('worked-solution-area')), findsOneWidget);
    expect(find.text('2x + 5 = 15'), findsOneWidget);
    expect(find.text('2x = 10'), findsOneWidget);
    expect(find.byKey(const Key('final-result-card')), findsOneWidget);
    expect(find.text('x = 5'), findsOneWidget);
    expect(find.byKey(const Key('solution-summary-card')), findsOneWidget);
    expect(find.text('Key Formula:'), findsOneWidget);
    expect(find.text('Keep both sides balanced.'), findsOneWidget);
    expect(find.text('Applied:'), findsOneWidget);
    expect(find.text('Inverse operations'), findsOneWidget);
    expect(
      find.text('Great job! You’ve mastered this problem.'),
      findsOneWidget,
    );
  });

  testWidgets('final board does not overlay historical teaching actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'final_verified_answer',
        board: const VisualTutorBoardEntity(
          type: 'final_verified_answer',
          metadata: {'final_answer': 'x = 5/2'},
        ),
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'old-teaching-prompt',
            type: 'write_text',
            text: 'What number cancels 5?',
            x: 20,
            y: 20,
          ),
          VisualTutorBoardActionEntity(
            id: 'old-student-task',
            type: 'student_task',
            text: 'Subtract 5 from both sides.',
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('final-answer-board')), findsOneWidget);
    expect(find.text('What number cancels 5?'), findsNothing);
    expect(
      find.byKey(const Key('teaching-board-action-old-student-task')),
      findsNothing,
    );
  });

  testWidgets('unsupported illustration placeholder renders', (tester) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'unsupported_problem',
        board: const VisualTutorBoardEntity(
          type: 'formula_card',
          metadata: {
            'screen_state': 'unsupported_problem',
            'board_type': 'unsupported_problem',
            'friendly_message':
                "I'm sorry, I can't solve this type of problem yet.",
            'khmer_explanation':
                'សូមសាកល្បងប្រធានបទផ្សេង ឬពិនិត្យមើលគុណភាពរូបភាព។',
          },
        ),
      ),
    );

    expect(find.byKey(const Key('unsupported-problem-board')), findsOneWidget);
    expect(find.textContaining('SYSTEM STATUS'), findsOneWidget);
    expect(find.byKey(const Key('unsupported-error-pill')), findsOneWidget);
    expect(
      find.byKey(const Key('unsupported-illustration-placeholder')),
      findsOneWidget,
    );
    expect(find.textContaining('Unsupported Problem'), findsOneWidget);
    expect(
      find.textContaining("I'm sorry, I can't solve this type of problem yet."),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('unsupported-khmer-explanation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('unsupported-suggestion-topic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('unsupported-suggestion-image-quality')),
      findsOneWidget,
    );
    expect(find.text('Try a different topic'), findsOneWidget);
    expect(find.text('Check the image quality'), findsOneWidget);
  });
}
