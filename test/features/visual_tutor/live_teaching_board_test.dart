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
    bool finalAnswerLocked = true,
    String? activeActionId,
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
            finalAnswerLocked: finalAnswerLocked,
            activeActionId: activeActionId,
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

    // Equations render through Math.tex, so assert the structured action node
    // instead of requiring a plain Text descendant.
    expect(
      find.byKey(const Key('teaching-board-action-equation')),
      findsOneWidget,
    );
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

  testWidgets('feedback actions render generically in check-work state', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'check_my_work',
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'mistake',
            type: 'show_feedback',
            text: 'Check your sign here!',
            x: 42,
            y: 80,
          ),
        ],
      ),
    );

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

    expect(
      find.byKey(const Key('teaching-board-action-focused-step')),
      findsOneWidget,
    );
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

    expect(
      find.byKey(const Key('teaching-board-function-quadratic')),
      findsOneWidget,
    );
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
    'control-only actions cannot leave a blank board and are diagnosed',
    (tester) async {
      final diagnostics = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 520,
            child: LiveTeachingBoard(
              actions: const [
                VisualTutorBoardActionEntity(
                  id: 'fade-only',
                  type: 'fade_previous',
                  targetId: 'earlier-action',
                ),
              ],
              onActionDiagnostic: (event) =>
                  diagnostics.add('${event.actionId}:${event.lifecycle.name}'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('visual-tutor-board-recovery')),
        findsOneWidget,
      );
      expect(diagnostics, contains('fade-only:skipped'));
    },
  );

  testWidgets(
    'invalid actions keep valid sibling content visible with recovery notice',
    (tester) async {
      await tester.pumpWidget(
        buildBoard(
          variant: 'speaking_writing',
          actions: const [
            VisualTutorBoardActionEntity(
              id: 'unsafe-sibling',
              type: 'run_javascript',
              text: '<script>alert(1)</script>',
            ),
            VisualTutorBoardActionEntity(
              id: 'valid-step',
              type: 'write_text',
              sequenceIndex: 1,
              text: 'Subtract 5 from both sides.',
            ),
          ],
        ),
      );

      expect(
        find.byKey(const Key('teaching-board-action-valid-step')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('visual-tutor-board-inline-recovery')),
        findsOneWidget,
      );
      expect(find.text('<script>alert(1)</script>'), findsNothing);
    },
  );

  testWidgets(
    'bounded history retains the active current action and exposes older work',
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
        buildBoard(
          variant: 'speaking_writing',
          actions: actions,
          activeActionId: 'action-0',
        ),
      );

      expect(find.text('Step 0'), findsOneWidget);
      expect(find.text('Step 149'), findsOneWidget);
      expect(
        find.byKey(const Key('visual-tutor-board-history-summary')),
        findsOneWidget,
      );
    },
  );

  testWidgets('asking question state does not invent a fixed board', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'asking_question',
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'ai-question',
            type: 'write_text',
            text: 'Which expression should we simplify first?',
            x: 40,
            y: 80,
          ),
        ],
      ),
    );

    expect(
      find.text('Which expression should we simplify first?'),
      findsOneWidget,
    );
    expect(find.textContaining('integral of e'), findsNothing);
  });

  testWidgets('final reveal is an explicit generic action', (tester) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'final_verified_answer',
        finalAnswerLocked: false,
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'verified-final',
            type: 'final_answer_reveal',
            text: 'x = 5',
            x: 42,
            y: 100,
          ),
        ],
      ),
    );

    expect(find.text('x = 5'), findsOneWidget);
  });

  testWidgets('final state retains historical teaching actions', (
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

    expect(find.text('What number cancels 5?'), findsOneWidget);
    expect(
      find.byKey(const Key('teaching-board-action-old-student-task')),
      findsOneWidget,
    );
  });

  testWidgets('unsupported state renders the server-provided recovery action', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBoard(
        variant: 'unsupported_problem',
        actions: const [
          VisualTutorBoardActionEntity(
            id: 'unsupported-help',
            type: 'show_feedback',
            text:
                "I can't verify this problem yet. Please clarify the notation.",
            x: 40,
            y: 80,
          ),
        ],
      ),
    );

    expect(
      find.textContaining("I can't verify this problem yet"),
      findsOneWidget,
    );
  });
}
