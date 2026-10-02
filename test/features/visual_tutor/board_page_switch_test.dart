/// Tapping "Board 2" must actually show Board 2's work.
///
/// Mirrors how the tutor screen embeds the board: TeachingCanvasBoard inside a
/// canvas that can be taller than the screen, with the visible height passed in
/// separately.
library;
import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pagination.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const surface = Size(390, 700);
  const visibleBoardHeight = 380.0;

  List<VisualTutorBoardActionEntity> solutionActions() {
    final turn = VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File(
                'test/features/visual_tutor/fixtures/worked_solution_turn.json',
              ).readAsStringSync(),
            )
            as Map,
      ),
    );
    return turn.boardActions;
  }

  Widget app(List<VisualTutorBoardActionEntity> actions) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: surface.width,
        height: visibleBoardHeight,
        child: TeachingCanvasBoard(
          variant: 'speaking_writing',
          actions: actions,
          finalAnswerLocked: false,
          reducedMotion: true,
          restored: true,
          useLogicalCanvasScale: true,
          pageViewportHeight: visibleBoardHeight,
        ),
      ),
    ),
  );

  testWidgets('board 2 shows its own steps when tapped', (tester) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final actions = solutionActions();
    final pages = paginateBoardActions(
      actions: actions,
      viewportHeight: visibleBoardHeight - 44,
    );
    expect(pages.length, greaterThan(1), reason: 'needs at least two boards');

    await tester.pumpWidget(app(actions));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('visual-tutor-board-pages')), findsOneWidget);

    await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
    await tester.pump(const Duration(milliseconds: 400));

    // Something from board 2 must be on screen.
    final secondBoard = pages[1].actions
        .where((action) => action.type != 'student_task')
        .toList();
    expect(secondBoard, isNotEmpty);
    final rendered = secondBoard.where((action) {
      final prefix = switch (action.type) {
        'show_table' => 'teaching-board-table',
        'show_graph' || 'plot_function' => 'teaching-board-graph',
        _ => 'teaching-board-action',
      };
      return find.byKey(Key('$prefix-${action.id}')).evaluate().isNotEmpty;
    }).toList();

    expect(
      rendered.length,
      secondBoard.length,
      reason:
          'board 2 drew ${rendered.length} of ${secondBoard.length} items: '
          '${secondBoard.map((a) => a.id).toList()}',
    );
  });

  testWidgets('previous and next buttons move between boards', (tester) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(solutionActions()));
    await tester.pump(const Duration(seconds: 1));

    final firstStep = find.byKey(
      const Key('teaching-board-action-ws-step-read-0'),
    );
    expect(firstStep, findsOneWidget, reason: 'starts on board 1');

    await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(firstStep, findsNothing, reason: 'next moved on');

    await tester.tap(find.byKey(const Key('visual-tutor-board-previous')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(firstStep, findsOneWidget, reason: 'previous went back');
  });

  test('the screen and the board split the solution the same way', () {
    // They must agree: if the screen thinks it all fits while the board pages
    // it, the screen keeps a tall scrolling canvas and the student scrolls
    // into blank paper below the page.
    final actions = solutionActions();
    const visible = visibleBoardHeight;

    final screenPages = paginateBoardActions(
      actions: actions,
      viewportHeight: visible - boardTabsHeight,
    );
    final boardPages = paginateBoardActions(
      actions: actions,
      viewportHeight: visible - boardTabsHeight,
    );

    expect(screenPages.length, boardPages.length);
    for (var index = 0; index < screenPages.length; index++) {
      expect(
        screenPages[index].actions.map((action) => action.id),
        boardPages[index].actions.map((action) => action.id),
      );
    }
  });


  testWidgets('the board keeps drawing while the solution is written', (
    tester,
  ) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: surface.width,
            height: visibleBoardHeight,
            child: TeachingCanvasBoard(
              variant: 'speaking_writing',
              actions: solutionActions(),
              finalAnswerLocked: false,
              // Playback on: actions arrive one at a time, as they do when a
              // solution is being written for a student.
              reducedMotion: false,
              restored: false,
              useLogicalCanvasScale: true,
              pageViewportHeight: visibleBoardHeight,
            ),
          ),
        ),
      ),
    );

    var everDrew = false;
    for (var tick = 0; tick < 60 && !everDrew; tick++) {
      await tester.pump(const Duration(milliseconds: 250));
      everDrew = find
          .byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key as ValueKey<String>).value.startsWith(
                  'teaching-board-action-',
                ),
          )
          .evaluate()
          .isNotEmpty;
    }

    expect(
      everDrew,
      isTrue,
      reason: 'the solution never appeared while it was being written',
    );
  });
}
