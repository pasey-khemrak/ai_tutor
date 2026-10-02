/// Board 1, Board 2, Board 3 — a long solution continues onto the next board
/// instead of running off the bottom, and earlier boards stay reachable.
library;
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pagination.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<VisualTutorBoardActionEntity> solution({int steps = 6}) => [
    for (var step = 0; step < steps; step++) ...[
      VisualTutorBoardActionEntity(
        id: 'step-$step-text',
        type: 'write_text',
        sequenceIndex: step * 2,
        layoutZone: 'working',
        layoutFlow: 'vertical',
        sectionId: 'step-$step',
        text:
            'Step ${step + 1} · A full sentence of teaching that takes a couple '
            'of lines on the board so the solution is realistically tall.',
      ),
      VisualTutorBoardActionEntity(
        id: 'step-$step-equation',
        type: 'write_equation',
        sequenceIndex: step * 2 + 1,
        layoutZone: 'working',
        layoutFlow: 'vertical',
        sectionId: 'step-$step',
        latex: 'x + $step = ${step + 3}',
      ),
    ],
  ];

  Widget board(
    List<VisualTutorBoardActionEntity> actions, {
    Size size = const Size(390, 520),
  }) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: TeachingCanvasBoard(
          variant: 'speaking_writing',
          actions: actions,
          finalAnswerLocked: false,
          reducedMotion: true,
          restored: true,
          useLogicalCanvasScale: true,
          pageViewportHeight: size.height,
        ),
      ),
    ),
  );

  test('a short solution stays on one board', () {
    final pages = paginateBoardActions(
      actions: solution(steps: 1),
      viewportHeight: 2000,
    );

    expect(pages.length, 1);
  });

  test('a long solution continues onto more boards', () {
    final pages = paginateBoardActions(
      actions: solution(steps: 8),
      viewportHeight: 400,
    );

    expect(pages.length, greaterThan(1));
    // Nothing is dropped on the way.
    expect(
      pages.expand((page) => page.actions).map((action) => action.id).toList(),
      solution(steps: 8).map((action) => action.id).toList(),
    );
  });

  test('a step is never split across two boards', () {
    final pages = paginateBoardActions(
      actions: solution(steps: 8),
      viewportHeight: 400,
    );

    for (final page in pages) {
      final sections = page.actions
          .map((action) => action.sectionId)
          .whereType<String>()
          .toSet();
      for (final section in sections) {
        final everywhere = pages
            .expand((other) => other.actions)
            .where((action) => action.sectionId == section)
            .length;
        final here = page.actions
            .where((action) => action.sectionId == section)
            .length;
        expect(
          here,
          everywhere,
          reason: '$section must live entirely on ${page.label}',
        );
      }
    }
  });

  test('an unbounded viewport keeps everything reachable on one board', () {
    final pages = paginateBoardActions(
      actions: solution(steps: 8),
      viewportHeight: double.infinity,
    );

    expect(pages.length, 1);
    expect(pages.single.actions.length, 16);
  });

  testWidgets('a long solution shows board tabs and opens on Board 1', (
    tester,
  ) async {
    await tester.pumpWidget(board(solution(steps: 8)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('visual-tutor-board-pages')), findsOneWidget);
    expect(find.textContaining('Board 1 of'), findsOneWidget);
    // Reading starts at the beginning of the solution.
    expect(find.byKey(const Key('teaching-board-action-step-0-text')), findsOneWidget);
  });

  testWidgets('tapping Board 2 shows later steps and keeps Board 1 reachable', (
    tester,
  ) async {
    await tester.pumpWidget(board(solution(steps: 8)));
    await tester.pump(const Duration(milliseconds: 300));

    final firstStep = find.byKey(
      const Key('teaching-board-action-step-0-text'),
    );
    expect(firstStep, findsOneWidget);

    await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(firstStep, findsNothing, reason: 'Board 2 shows its own steps');
    await tester.tap(find.byKey(const Key('visual-tutor-board-previous')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(firstStep, findsOneWidget, reason: 'the student can look back');
  });

  testWidgets('next and previous move between boards', (tester) async {
    await tester.pumpWidget(board(solution(steps: 8)));
    await tester.pump(const Duration(milliseconds: 300));

    final firstStep = find.byKey(
      const Key('teaching-board-action-step-0-text'),
    );
    expect(firstStep, findsOneWidget);

    await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(firstStep, findsNothing);

    await tester.tap(find.byKey(const Key('visual-tutor-board-previous')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(firstStep, findsOneWidget);
  });
}
