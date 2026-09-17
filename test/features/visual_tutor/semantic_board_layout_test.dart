import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const graph = <String, dynamic>{
    'x_min': -4,
    'x_max': 4,
    'y_min': -3,
    'y_max': 8,
    'function_expression': 'x^2 - 1',
    'domain': [-4, 4],
  };

  Widget buildBoard({
    required Size size,
    required List<VisualTutorBoardActionEntity> actions,
    ValueChanged<BoardStudentInteraction>? onStudentInteraction,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: LiveTeachingBoard(
              variant: 'speaking_writing',
              actions: actions,
              onStudentInteraction: onStudentInteraction,
            ),
          ),
        ),
      ),
    );
  }

  List<VisualTutorBoardActionEntity> phoneLessonActions() => const [
    VisualTutorBoardActionEntity(
      id: 'problem',
      type: 'write_text',
      text: 'Solve 2x + 5 = 15.',
      layoutZone: 'problem',
      layoutFlow: 'vertical',
      sectionId: 'prompt',
    ),
    VisualTutorBoardActionEntity(
      id: 'working',
      type: 'write_equation',
      latex: '2x = 10',
      sequenceIndex: 1,
      layoutZone: 'working',
      layoutFlow: 'vertical',
      sectionId: 'work',
    ),
    VisualTutorBoardActionEntity(
      id: 'graph',
      type: 'show_graph',
      sequenceIndex: 2,
      layoutZone: 'visual',
      layoutFlow: 'diagram',
      sectionId: 'visual',
      graph: graph,
    ),
    VisualTutorBoardActionEntity(
      id: 'student-task',
      type: 'student_task',
      text: 'What value of x makes the equation true?',
      sequenceIndex: 3,
      layoutZone: 'student_task',
      layoutFlow: 'vertical',
      sectionId: 'try-it',
      requiresStudentResponse: true,
    ),
  ];

  Rect rectFor(WidgetTester tester, String actionId, {bool graph = false}) {
    final key = graph
        ? Key('teaching-board-graph-$actionId')
        : Key('teaching-board-action-$actionId');
    return tester.getRect(find.byKey(key));
  }

  void expectHorizontallyWithinBoard(WidgetTester tester, Rect actionRect) {
    final boardRect = tester.getRect(
      find.byKey(const Key('live-teaching-board-paper')),
    );
    expect(actionRect.left, greaterThanOrEqualTo(boardRect.left - 0.5));
    expect(actionRect.right, lessThanOrEqualTo(boardRect.right + 0.5));
  }

  void configureViewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final width in const [360.0, 390.0, 412.0]) {
    testWidgets(
      'phone width ${width.toInt()} uses a single readable semantic column',
      (tester) async {
        configureViewport(tester, Size(width, 760));
        await tester.pumpWidget(
          buildBoard(
            size: Size(width, 760),
            actions: phoneLessonActions(),
            onStudentInteraction: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        final problem = rectFor(tester, 'problem');
        final working = rectFor(tester, 'working');
        final graphRect = rectFor(tester, 'graph', graph: true);
        final task = rectFor(tester, 'student-task');
        for (final rect in [problem, working, graphRect, task]) {
          expectHorizontallyWithinBoard(tester, rect);
        }
        expect(working.top, greaterThanOrEqualTo(problem.bottom));
        expect(graphRect.top, greaterThanOrEqualTo(working.bottom));
        expect(task.top, greaterThanOrEqualTo(graphRect.bottom));
        expect(
          find.text('What value of x makes the equation true?'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('tablet gives visual and reference work a secondary column', (
    tester,
  ) async {
    configureViewport(tester, const Size(900, 720));
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'working',
        type: 'write_text',
        text: 'First isolate the variable.',
        layoutZone: 'working',
        layoutFlow: 'vertical',
      ),
      VisualTutorBoardActionEntity(
        id: 'graph',
        type: 'show_graph',
        sequenceIndex: 1,
        layoutZone: 'visual',
        layoutFlow: 'diagram',
        graph: graph,
      ),
      VisualTutorBoardActionEntity(
        id: 'reference',
        type: 'write_text',
        text: 'Remember: the vertex is the turning point.',
        sequenceIndex: 2,
        layoutZone: 'reference',
        layoutFlow: 'vertical',
      ),
    ];
    await tester.pumpWidget(
      buildBoard(size: const Size(900, 720), actions: actions),
    );
    await tester.pumpAndSettle();

    final working = rectFor(tester, 'working');
    final graphRect = rectFor(tester, 'graph', graph: true);
    final reference = rectFor(tester, 'reference');
    for (final rect in [working, graphRect, reference]) {
      expectHorizontallyWithinBoard(tester, rect);
    }
    expect(graphRect.left, greaterThan(working.left));
    expect(reference.left, greaterThan(working.left));
  });

  testWidgets('landscape keeps diagrams and student tasks on the board', (
    tester,
  ) async {
    configureViewport(tester, const Size(844, 390));
    await tester.pumpWidget(
      buildBoard(
        size: const Size(844, 390),
        actions: phoneLessonActions(),
        onStudentInteraction: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    for (final rect in [
      rectFor(tester, 'problem'),
      rectFor(tester, 'working'),
      rectFor(tester, 'graph', graph: true),
      rectFor(tester, 'student-task'),
    ]) {
      expectHorizontallyWithinBoard(tester, rect);
    }
  });

  testWidgets('long Khmer instruction wraps within its semantic working slot', (
    tester,
  ) async {
    configureViewport(tester, const Size(360, 640));
    const khmer =
        'សូមដក ៥ ចេញពីសមីការទាំងសងខាង រួចសរសេរជំហានបន្ទាប់ដោយខ្លួនឯង មុនពេលយើងបន្តទៅជំហានបន្ទាប់។';
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'khmer-working',
        type: 'write_text',
        text: khmer,
        layoutZone: 'working',
        layoutFlow: 'vertical',
        sectionId: 'work',
      ),
      VisualTutorBoardActionEntity(
        id: 'khmer-task',
        type: 'student_task',
        text: 'តើជំហានបន្ទាប់គឺអ្វី?',
        sequenceIndex: 1,
        layoutZone: 'student_task',
        layoutFlow: 'vertical',
        sectionId: 'try-it',
        requiresStudentResponse: true,
      ),
    ];
    await tester.pumpWidget(
      buildBoard(
        size: const Size(360, 640),
        actions: actions,
        onStudentInteraction: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final instruction = rectFor(tester, 'khmer-working');
    final task = rectFor(tester, 'khmer-task');
    expect(find.text(khmer), findsOneWidget);
    expectHorizontallyWithinBoard(tester, instruction);
    expectHorizontallyWithinBoard(tester, task);
    expect(instruction.height, greaterThan(48));
    expect(task.top, greaterThanOrEqualTo(instruction.bottom));
  });
}
