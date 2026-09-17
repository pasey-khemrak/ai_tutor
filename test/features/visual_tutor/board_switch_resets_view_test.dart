/// Switching boards must show the new board, not the old view of it.
///
/// The board sits inside a pan/zoom viewport. After reading down one board,
/// that offset stayed put when the next board arrived — and the next board,
/// drawn from its first line, sat off-screen. To a student that is a blank
/// board, which is exactly what was reported for "Board 2 of 3".
import 'dart:convert';
import 'dart:io';

import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/data/models/visual_tutor_models.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pagination.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The size that reproduced the reported split: Steps 1-2, Steps 3-4, answer.
  const boardWidth = 640.0;
  const boardHeight = 1000.0;

  VisualTutorTurnResponseModel loadTurn() {
    return VisualTutorTurnResponseModel.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File(
                'test/features/visual_tutor/fixtures/infinity_turn.json',
              ).readAsStringSync(),
            )
            as Map,
      ),
    );
  }

  testWidgets('board 2 is visible after reading down board 1', (tester) async {
    tester.view.physicalSize = const Size(boardWidth, boardHeight + 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final actions = loadTurn().boardActions;
    final pages = paginateBoardActions(
      actions: actions,
      viewportHeight: boardHeight - boardTabsHeight,
      viewportWidth: boardWidth,
    );
    expect(pages.length, greaterThan(1));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: TeachingCanvasBoard(
              variant: 'speaking_writing',
              actions: actions,
              finalAnswerLocked: false,
              reducedMotion: true,
              restored: true,
              useLogicalCanvasScale: true,
              pageViewportHeight: boardHeight,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // The student drags the board up to read the bottom of board 1.
    await tester.drag(
      find.byKey(const Key('visual-tutor-board-viewport')),
      const Offset(0, -420),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
    await tester.pump(const Duration(milliseconds: 500));

    // Every line of the new board must be on screen, not above its top edge.
    final screen = Rect.fromLTWH(0, 0, boardWidth, boardHeight);
    for (final action in pages[1].actions) {
      final finder = action.type == 'show_table'
          ? find.byKey(Key('teaching-board-table-${action.id}'))
          : find.byKey(Key('teaching-board-action-${action.id}'));
      expect(finder, findsOneWidget, reason: '${action.id} must be drawn');
      final rect = tester.getRect(finder);
      expect(
        rect.top,
        greaterThanOrEqualTo(screen.top - 1),
        reason: '${action.id} is above the top of the board (${rect.top})',
      );
    }
  });
}
