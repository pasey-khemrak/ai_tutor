import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget board(
    List<VisualTutorBoardActionEntity> actions, {
    bool reducedMotion = false,
    bool restored = false,
  }) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 440,
        child: LiveTeachingBoard(
          actions: actions,
          finalAnswerLocked: true,
          reducedMotion: reducedMotion,
          restored: restored,
        ),
      ),
    ),
  );

  Finder transition(String id) =>
      find.byKey(Key('teaching-board-transition-$id'));
  Finder removing(String id) =>
      find.byKey(Key('teaching-board-removing-$id'));
  Finder action(String id) => find.byKey(Key('teaching-board-action-$id'));

  double transitionOpacity(WidgetTester tester, String id) => tester
      .widgetList<Opacity>(
        find.descendant(of: transition(id), matching: find.byType(Opacity)),
      )
      .first
      .opacity;

  const focusedHighlightedEquation = VisualTutorBoardActionEntity(
    id: 'focused-equation',
    type: 'write_equation',
    latex: '2x = 10',
    x: 36,
    y: 64,
    width: 220,
    height: 52,
    metadata: {'highlighted': true, 'focused': true},
  );

  testWidgets('highlight draw-on and focus receive calm transition wrappers', (
    tester,
  ) async {
    await tester.pumpWidget(
      board(const [
        VisualTutorBoardActionEntity(
          id: 'highlight-marker',
          type: 'highlight',
          x: 36,
          y: 64,
          width: 220,
          height: 52,
        ),
        focusedHighlightedEquation,
      ]),
    );
    await tester.pump();

    expect(transition('highlight-marker'), findsOneWidget);
    expect(
      find.byKey(const Key('teaching-board-highlight-highlight-marker')),
      findsOneWidget,
    );
    expect(transition('focused-equation'), findsOneWidget);
    expect(action('focused-equation'), findsOneWidget);

    // The effect settles rather than continually pulsing, which keeps the
    // board readable during a teaching pause.
    await tester.pump(const Duration(milliseconds: 700));
    expect(transition('focused-equation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('faded history and revealed next step transition independently', (
    tester,
  ) async {
    const previous = VisualTutorBoardActionEntity(
      id: 'previous-step',
      type: 'write_text',
      text: 'Subtract 5 from both sides.',
      x: 28,
      y: 52,
      metadata: {'faded': true},
    );
    const next = VisualTutorBoardActionEntity(
      id: 'next-step',
      type: 'write_text',
      text: 'Now divide both sides by 2.',
      x: 28,
      y: 122,
      metadata: {'reveal': true},
    );

    await tester.pumpWidget(board(const [previous]));
    await tester.pump();
    await tester.pumpWidget(board(const [previous, next]));
    await tester.pump();

    expect(transition('previous-step'), findsOneWidget);
    expect(transition('next-step'), findsOneWidget);
    expect(find.text('Subtract 5 from both sides.'), findsOneWidget);
    expect(find.text('Now divide both sides by 2.'), findsOneWidget);
  });

  testWidgets('erase retains an outgoing action until its exit completes', (
    tester,
  ) async {
    const original = VisualTutorBoardActionEntity(
      id: 'old-work',
      type: 'write_equation',
      latex: '2x - 5 = 10',
      x: 36,
      y: 64,
      width: 240,
      height: 52,
    );

    await tester.pumpWidget(board(const [original]));
    await tester.pump();
    expect(action('old-work'), findsOneWidget);

    await tester.pumpWidget(board(const []));
    await tester.pump();
    expect(removing('old-work'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(removing('old-work'), findsNothing);
    expect(action('old-work'), findsNothing);
  });

  testWidgets('transform equation keeps its teaching position while changing', (
    tester,
  ) async {
    const before = VisualTutorBoardActionEntity(
      id: 'equation-before',
      type: 'write_equation',
      latex: '2x - 5 = 10',
      x: 36,
      y: 64,
      width: 260,
      height: 52,
    );
    const after = VisualTutorBoardActionEntity(
      id: 'equation-after',
      type: 'transform_equation',
      targetId: 'equation-before',
      latex: '2x = 15',
      x: 36,
      y: 64,
      width: 260,
      height: 52,
    );

    await tester.pumpWidget(board(const [before]));
    await tester.pump();
    final originalTopLeft = tester.getTopLeft(action('equation-before'));

    await tester.pumpWidget(board(const [after]));
    await tester.pump();

    expect(transition('equation-after'), findsOneWidget);
    expect(tester.getTopLeft(action('equation-after')), originalTopLeft);
    await tester.pump(const Duration(milliseconds: 500));
    expect(action('equation-before'), findsNothing);
    expect(action('equation-after'), findsOneWidget);
  });

  testWidgets('reduced motion and restored boards skip transition staging', (
    tester,
  ) async {
    await tester.pumpWidget(
      board(const [focusedHighlightedEquation], reducedMotion: true),
    );
    await tester.pump();
    expect(action('focused-equation'), findsOneWidget);
    expect(transition('focused-equation'), findsOneWidget);
    expect(transitionOpacity(tester, 'focused-equation'), 1);

    await tester.pumpWidget(board(const [focusedHighlightedEquation]));
    await tester.pump();
    await tester.pumpWidget(board(const [], restored: true));
    await tester.pump();
    expect(removing('focused-equation'), findsNothing);
    expect(action('focused-equation'), findsNothing);
  });
}
