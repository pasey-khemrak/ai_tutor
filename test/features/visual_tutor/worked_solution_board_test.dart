/// The whole worked solution must reach the board.
///
/// The fixture is a real captured ai-service turn, so this exercises the same
/// path the app uses: public payload -> model parsing -> teaching-plan
/// validation -> board rendering. It guards the rule that matters to a
/// student: every step of the solution is shown, not just one line of it.
import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pagination.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  VisualTutorTurnResponseModel loadTurn() {
    final file = File(
      'test/features/visual_tutor/fixtures/worked_solution_turn.json',
    );
    return VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
    );
  }

  /// The board only builds what the surface can show, so the test view has to
  /// match the box under test.
  void useSurface(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget buildBoard(
    List<VisualTutorBoardActionEntity> actions, {
    Size size = const Size(900, 2400),
    bool finalAnswerLocked = false,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: LiveTeachingBoard(
            variant: 'speaking_writing',
            actions: actions,
            finalAnswerLocked: finalAnswerLocked,
          ),
        ),
      ),
    );
  }

  test('the public turn parses into a full, unlocked worked solution', () {
    final turn = loadTurn();

    expect(turn.finalAnswerLocked, isFalse);
    // A public turn carries the plan's representation here; parsing would have
    // thrown if the teaching plan itself had failed validation.
    expect(turn.teachingMode, 'worked_example');
    // Every step survives parsing: one line would mean the turn was collapsed
    // back to the old one-step-at-a-time pacing.
    final equations = turn.boardActions
        .where((action) => action.type == 'write_equation')
        .toList();
    expect(equations.length, greaterThanOrEqualTo(5));
    expect(
      turn.boardActions.where((action) => action.type == 'show_table').length,
      1,
    );
    expect(
      turn.boardActions.where((action) => action.type == 'student_task').length,
      1,
    );
  });

  test('no action is replaced by the board recovery notice', () {
    final turn = loadTurn();

    final recovered = turn.boardActions.where(
      (action) =>
          action.id.startsWith('board-recovery') ||
          (action.text ?? '').contains('could not be shown'),
    );

    expect(recovered, isEmpty);
  });

  testWidgets('every solution step is drawn across the boards', (tester) async {
    final turn = loadTurn();
    final actions = turn.boardActions
        .where((action) => action.type != 'student_task')
        .toList();
    // Tall enough that the whole solution fits on one board, so this test
    // stays about "nothing is lost" rather than about where the split falls.
    const surface = Size(900, 2400);
    useSurface(tester, surface);
    await tester.pumpWidget(buildBoard(actions, size: surface));
    await tester.pump(const Duration(seconds: 2));

    for (final action in actions) {
      // Visual primitives carry their own key prefix in BoardElementRenderer.
      final prefix = switch (action.type) {
        'show_table' => 'teaching-board-table',
        'show_graph' || 'plot_function' => 'teaching-board-graph',
        _ => 'teaching-board-action',
      };
      expect(
        find.byKey(Key('$prefix-${action.id}')),
        findsOneWidget,
        reason: 'board action ${action.id} (${action.type}) must be rendered',
      );
    }
    expect(find.textContaining('could not be shown'), findsNothing);
  });

  test('on a phone the real solution continues onto later boards', () {
    final turn = loadTurn();

    final pages = paginateBoardActions(
      actions: turn.boardActions,
      viewportHeight: 520 - 44,
    );

    expect(pages.length, greaterThan(1), reason: 'a phone board fills up');
    // Nothing is lost on the way across the boards.
    final teaching = pages
        .expand((page) => page.actions)
        .where((action) => action.type != 'student_task')
        .map((action) => action.id)
        .toList();
    expect(
      teaching,
      turn.boardActions
          .where((action) => action.type != 'student_task')
          .map((action) => action.id)
          .toList(),
    );
  });

  testWidgets('the student sees the reasoning and the answer', (tester) async {
    final turn = loadTurn();

    const surface = Size(900, 2400);
    useSurface(tester, surface);
    await tester.pumpWidget(
      buildBoard(
        turn.boardActions
            .where((action) => action.type != 'student_task')
            .toList(),
        size: surface,
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    // Why 0/0 does not mean the answer is zero -- the misconception this
    // lesson exists to correct.
    expect(find.textContaining('indeterminate form'), findsOneWidget);
    expect(find.textContaining('never equals'), findsOneWidget);
    expect(find.textContaining('Answer · The limit is 6.'), findsOneWidget);
  });
}
