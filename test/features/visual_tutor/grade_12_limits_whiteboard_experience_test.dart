import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/semantic_board_layout.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/live_teaching_board.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const longKhmerTask =
      'សូមសង្កេតតម្លៃក្នុងតារាងដោយប្រុងប្រយ័ត្ន ហើយប្រាប់ថា f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1។';

  const limitsActions = <VisualTutorBoardActionEntity>[
    VisualTutorBoardActionEntity(
      id: 'limits-equation',
      type: 'write_equation',
      sequenceIndex: 0,
      durationMs: 500,
      layoutZone: 'problem',
      layoutFlow: 'vertical',
      latex: 'f(x) = (2x² + x − 3) / (x − 1)',
    ),
    VisualTutorBoardActionEntity(
      id: 'limits-table',
      type: 'show_table',
      sequenceIndex: 1,
      durationMs: 700,
      layoutZone: 'visual',
      layoutFlow: 'vertical',
      metadata: <String, dynamic>{
        'columns': <String>['x', 'f(x)'],
        'rows': <List<String>>[
          <String>['0.9', '4.8'],
          <String>['0.99', '4.98'],
          <String>['1.001', '5.002'],
        ],
      },
    ),
    VisualTutorBoardActionEntity(
      id: 'limits-graph',
      type: 'show_graph',
      sequenceIndex: 2,
      durationMs: 700,
      layoutZone: 'visual',
      layoutFlow: 'diagram',
      graph: <String, dynamic>{
        'x_min': 0,
        'x_max': 2,
        'y_min': 3,
        'y_max': 7,
        'function_expression': 'f(x)',
        'points': <Map<String, num>>[
          <String, num>{'x': 0.9, 'y': 4.8},
          <String, num>{'x': 1.1, 'y': 5.2},
        ],
      },
    ),
    VisualTutorBoardActionEntity(
      id: 'limits-student-task',
      type: 'student_task',
      sequenceIndex: 3,
      layoutZone: 'student_task',
      layoutFlow: 'vertical',
      text: longKhmerTask,
      requiresStudentResponse: true,
    ),
  ];

  Widget buildBoard({
    required Size size,
    required List<VisualTutorBoardActionEntity> actions,
    String? activeActionId,
    Animation<double> activeProgress = const AlwaysStoppedAnimation(1),
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const Key('limits-whiteboard-golden'),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: LiveTeachingBoard(
                actions: actions,
                activeActionId: activeActionId,
                activeProgress: activeProgress,
                onStudentInteraction: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void configureViewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Rect actionRect(WidgetTester tester, String id, {required String type}) {
    final key = switch (type) {
      'show_table' => Key('teaching-board-table-$id'),
      'show_graph' => Key('teaching-board-graph-$id'),
      _ => Key('teaching-board-action-$id'),
    };
    return tester.getRect(find.byKey(key));
  }

  void expectWithinBoard(WidgetTester tester, Rect rect) {
    final board = tester.getRect(
      find.byKey(const Key('live-teaching-board-paper')),
    );
    expect(rect.left, greaterThanOrEqualTo(board.left - .5));
    expect(rect.right, lessThanOrEqualTo(board.right + .5));
  }

  Finder semanticLabel(String label, {String? hint}) => find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.label == label &&
        (hint == null || widget.properties.hint == hint),
  );

  for (final width in const <double>[360, 390, 412]) {
    testWidgets(
      'Grade 12 Limits stays in one non-overlapping phone flow at ${width.toInt()}px',
      (tester) async {
        configureViewport(tester, Size(width, 780));
        await tester.pumpWidget(
          buildBoard(size: Size(width, 780), actions: limitsActions),
        );
        await tester.pumpAndSettle();

        final equation = actionRect(
          tester,
          'limits-equation',
          type: 'write_equation',
        );
        final table = actionRect(tester, 'limits-table', type: 'show_table');
        final graph = actionRect(tester, 'limits-graph', type: 'show_graph');
        final task = actionRect(
          tester,
          'limits-student-task',
          type: 'student_task',
        );
        for (final rect in <Rect>[equation, table, graph, task]) {
          expectWithinBoard(tester, rect);
        }
        expect(table.top, greaterThanOrEqualTo(equation.bottom));
        expect(graph.top, greaterThanOrEqualTo(table.bottom));
        expect(task.top, greaterThanOrEqualTo(graph.bottom));
        expect(find.text(longKhmerTask), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'semantic horizontal pairs collapse to a vertical phone reading flow',
    () {
      const pairedActions = <VisualTutorBoardActionEntity>[
        VisualTutorBoardActionEntity(
          id: 'b',
          type: 'write_text',
          text: 'Second',
          sequenceIndex: 1,
          layoutZone: 'working',
          layoutFlow: 'horizontal',
        ),
        VisualTutorBoardActionEntity(
          id: 'a',
          type: 'write_text',
          text: 'First',
          sequenceIndex: 1,
          layoutZone: 'working',
          layoutFlow: 'horizontal',
        ),
      ];
      final layout = SemanticBoardLayout.resolve(
        actions: pairedActions,
        textDirection: TextDirection.ltr,
      viewport: const Size(360, 640),
      );

      expect(layout.map((action) => action.id), <String>['a', 'b']);
      expect(layout[0].x, layout[1].x);
      expect(
        layout[1].y,
        greaterThanOrEqualTo(layout[0].y! + layout[0].height!),
      );
      for (final action in layout) {
        expect(action.x! + action.width!, lessThanOrEqualTo(360));
      }
    },
  );

  testWidgets(
    'Limits equation, table, graph, and task expose useful semantics',
    (tester) async {
      configureViewport(tester, const Size(900, 720));
      await tester.pumpWidget(
        buildBoard(
          size: const Size(900, 720),
          actions: limitsActions,
          activeActionId: 'limits-graph',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        semanticLabel(
          'f(x) = (2x² + x − 3) / (x − 1)',
          hint: 'Equation on the teaching board',
        ),
        findsOneWidget,
      );
      expect(
        semanticLabel('Table: x, f(x); 0.9, 4.8; 0.99, 4.98; 1.001, 5.002'),
        findsOneWidget,
      );
      expect(semanticLabel('Mathematical graph of f(x)'), findsOneWidget);
      expect(
        semanticLabel(
          longKhmerTask,
          hint: 'Student task. Enter your answer below.',
        ),
        findsOneWidget,
      );
      expect(
        semanticLabel('Current teaching action: show_graph'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the Limits board golden is stable in landscape and tablet layouts',
    (tester) async {
      configureViewport(tester, const Size(844, 520));
      await tester.pumpWidget(
        buildBoard(
          size: const Size(844, 520),
          actions: limitsActions.take(3).toList(growable: false),
          activeActionId: 'limits-graph',
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('limits-whiteboard-golden')),
        matchesGoldenFile('goldens/grade_12_limits_landscape.png'),
      );
    },
  );

  testWidgets(
    'large Khmer text leaves the Limits student task and answer field reachable',
    (tester) async {
      configureViewport(tester, const Size(390, 1000));
      await tester.pumpWidget(
        buildBoard(
          size: const Size(390, 1000),
          actions: limitsActions,
          textScaler: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();

      final task = actionRect(
        tester,
        'limits-student-task',
        type: 'student_task',
      );
      final answer = tester.getRect(
        find.byKey(const Key('teaching-board-answer-limits-student-task')),
      );
      final board = tester.getRect(
        find.byKey(const Key('live-teaching-board-paper')),
      );
      expect(task.height, greaterThan(72));
      expect(answer.top, greaterThanOrEqualTo(task.bottom));
      expect(answer.bottom, lessThanOrEqualTo(board.bottom));
    },
  );

  testWidgets('Limits plays equation, table, graph, then waits for the task', (
    tester,
  ) async {
    configureViewport(tester, const Size(390, 1000));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: SizedBox(
            width: 390,
            height: 1000,
            child: TeachingCanvasBoard(
              actions: limitsActions,
              finalAnswerLocked: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('teaching-board-action-limits-equation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('teaching-board-table-limits-table')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('teaching-board-graph-limits-graph')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 540));
    expect(
      find.byKey(const Key('teaching-board-table-limits-table')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('teaching-board-graph-limits-graph')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 740));
    expect(
      find.byKey(const Key('teaching-board-graph-limits-graph')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('teaching-board-action-limits-student-task')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 740));
    expect(
      find.byKey(const Key('teaching-board-action-limits-student-task')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('teaching-board-answer-limits-student-task')),
      findsOneWidget,
    );
    expect(find.text('5'), findsNothing);
  });

  testWidgets(
    'reduced motion keeps Limits controls available without replay motion',
    (tester) async {
      configureViewport(tester, const Size(390, 560));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: SizedBox(
              width: 390,
              height: 560,
              child: TeachingCanvasBoard(
                actions: limitsActions,
                finalAnswerLocked: true,
                reducedMotion: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('visual-tutor-board-replay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('visual-tutor-board-play-pause')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('visual-tutor-board-jump-current')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('visual-tutor-board-replay')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const Key('visual-tutor-board-play-pause')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(const Key('teaching-board-action-limits-equation')),
        findsOneWidget,
      );
    },
  );
}
