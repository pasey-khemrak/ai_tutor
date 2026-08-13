import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const learningContext = LearningContext(
    grade: 10,
    subject: 'Mathematics',
    topic: 'Linear Equations',
  );

  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(body: TutorScreen(context: learningContext)),
    );
  }

  Widget buildBoard({
    required List<VisualTutorBoardActionEntity> actions,
    String? variant,
    VisualTutorBoardEntity? board,
    bool animate = false,
    bool restored = false,
    bool finalAnswerLocked = true,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 360,
          child: TeachingCanvasBoard(
            variant: variant,
            board: board,
            actions: actions,
            finalAnswerLocked: finalAnswerLocked,
            animate: animate,
            restored: restored,
            actionInterval: const Duration(milliseconds: 120),
          ),
        ),
      ),
    );
  }

  VisualTutorTurnResponseEntity turnFor({
    VisualTutorInteractionEntity interaction =
        const VisualTutorInteractionEntity(
          type: 'text_response',
          prompt: 'What is your next step?',
        ),
    List<String> allowedActions = const [
      'request_hint',
      'stuck',
      'check_work',
      'explain_differently',
      'request_answer',
    ],
    bool finalAnswerLocked = true,
    String stageState = 'waiting_for_student',
  }) {
    return VisualTutorTurnResponseEntity(
      sessionId: 'test-session',
      turnId: 'test-turn',
      spokenText: 'Try one step.',
      displayText: 'Try one step.',
      teachingMode: 'guided_question',
      finalAnswerLocked: finalAnswerLocked,
      studentTask: interaction.prompt,
      board: const VisualTutorBoardEntity(type: 'teaching_stage'),
      teachingStage: VisualTutorTeachingStageEntity(stageState: stageState),
      interaction: interaction,
      allowedActions: allowedActions,
    );
  }

  Widget buildInteractionPanel({
    required VisualTutorTurnResponseEntity turn,
    required TextEditingController controller,
    required ValueChanged<VisualTutorStudentSubmission> onSubmit,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: StudentInteractionPanel(
            controller: controller,
            turn: turn,
            latestStudentMessage: null,
            onSubmit: onSubmit,
            onReset: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('canvas is the primary tutor area', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutor-presence-bar')), findsOneWidget);
    expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);
    expect(find.byKey(const Key('student-interaction-panel')), findsOneWidget);
    expect(find.byKey(const Key('tutor-speech-quote-panel')), findsOneWidget);
    expect(find.text('Teaching Board'), findsNothing);
    expect(find.text('Step 1: Find the Slope'), findsNothing);
  });

  testWidgets('header status changes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: TutorPresenceBar(
            learningContext: learningContext,
            stageState: 'drawing',
          ),
        ),
      ),
    );

    expect(find.textContaining('Writing...'), findsOneWidget);
    expect(find.textContaining('កំពុងសរសេរ...'), findsOneWidget);
  });

  testWidgets('tutor speech is visible in quote panel', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutor-speech-text')), findsOneWidget);
    expect(
      find.text('"What lesson or problem do you want to explore today?"'),
      findsOneWidget,
    );
  });

  testWidgets('board renders text equation and highlight actions', (
    tester,
  ) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'equation',
        type: 'write_equation',
        sequenceIndex: 0,
        latex: '2x + 5 = 15',
      ),
      VisualTutorBoardActionEntity(
        id: 'note',
        type: 'write_text',
        sequenceIndex: 1,
        text: 'Step 1: subtract 5 from both sides',
      ),
      VisualTutorBoardActionEntity(
        id: 'highlight',
        type: 'highlight',
        sequenceIndex: 2,
        x: 30,
        y: 30,
        width: 80,
        height: 40,
      ),
    ];

    await tester.pumpWidget(buildBoard(actions: actions));
    await tester.pump();

    expect(find.text('2x + 5 = 15'), findsOneWidget);
    expect(find.text('Step 1: subtract 5 from both sides'), findsOneWidget);
    expect(find.byKey(const Key('teaching-board-highlight')), findsOneWidget);
  });

  testWidgets(
    'top-level screen state selects graph board with action overlay',
    (tester) async {
      await tester.pumpWidget(
        buildBoard(
          variant: 'graph_based',
          board: const VisualTutorBoardEntity(
            type: 'graph_hint',
            metadata: {
              'equation_title': 'f(x) = sin(x)',
              'graph_elements': {
                'axes': true,
                'labels': {
                  'peak': 'Peak',
                  'trough': 'Trough',
                  'amplitude': 'Amplitude = 1',
                },
                'instruction': 'Drag the point to change the frequency',
              },
            },
          ),
          actions: const [
            VisualTutorBoardActionEntity(
              id: 'stale-equation',
              type: 'write_equation',
              latex: '2x + 5 = 15',
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('graph-based-board')), findsOneWidget);
      expect(find.text('f(x) = sin(x)'), findsOneWidget);
      expect(find.text('2x + 5 = 15'), findsOneWidget);
    },
  );

  testWidgets('mobile layout has no visible overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);
  });

  testWidgets('actions render in order', (tester) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'first',
        type: 'write_text',
        sequenceIndex: 0,
        text: 'First',
      ),
      VisualTutorBoardActionEntity(
        id: 'pause',
        type: 'pause_marker',
        sequenceIndex: 1,
        durationMs: 120,
      ),
      VisualTutorBoardActionEntity(
        id: 'second',
        type: 'write_equation',
        sequenceIndex: 2,
        latex: 'x = 5',
      ),
      VisualTutorBoardActionEntity(
        id: 'focus',
        type: 'highlight',
        sequenceIndex: 3,
        x: 30,
        y: 30,
        width: 80,
        height: 40,
      ),
    ];

    await tester.pumpWidget(buildBoard(actions: actions, animate: true));
    await tester.pump();

    expect(
      find.byKey(const Key('teaching-board-action-first')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('teaching-board-action-second')), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const Key('teaching-board-action-second')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 160));
    expect(find.byKey(const Key('teaching-board-highlight')), findsOneWidget);
  });

  testWidgets('animation disabled renders all actions immediately', (
    tester,
  ) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'one',
        type: 'write_text',
        sequenceIndex: 0,
        text: 'One',
      ),
      VisualTutorBoardActionEntity(
        id: 'two',
        type: 'write_equation',
        sequenceIndex: 1,
        latex: '2x = 10',
      ),
      VisualTutorBoardActionEntity(
        id: 'three',
        type: 'draw_line',
        sequenceIndex: 2,
        x: 20,
        y: 80,
        width: 160,
      ),
    ];

    await tester.pumpWidget(buildBoard(actions: actions));
    await tester.pump();

    expect(find.byKey(const Key('teaching-board-action-one')), findsOneWidget);
    expect(find.byKey(const Key('teaching-board-action-two')), findsOneWidget);
    expect(
      find.byKey(const Key('teaching-board-draw_line-three')),
      findsOneWidget,
    );
  });

  testWidgets('write text animation completes after parent rebuild', (
    tester,
  ) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'linear-step-2-question',
        type: 'write_text',
        sequenceIndex: 0,
        durationMs: 420,
        text: 'Step 2: divide both sides by 2',
        x: 40,
        y: 250,
        width: 520,
        height: 40,
      ),
    ];

    await tester.pumpWidget(
      const _BoardRebuildHarness(actions: actions, animate: true),
    );
    await tester.pump(const Duration(milliseconds: 16));

    tester
        .state<_BoardRebuildHarnessState>(find.byType(_BoardRebuildHarness))
        .rebuild();
    await tester.pump();

    expect(find.text('Step 2: divide both sides by 2'), findsNothing);

    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Step 2: divide both sides by 2'), findsOneWidget);
    expect(find.text('S'), findsNothing);
  });

  testWidgets('restored state does not replay old actions', (tester) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'restored-one',
        type: 'write_text',
        sequenceIndex: 0,
        text: 'Restored note',
      ),
      VisualTutorBoardActionEntity(
        id: 'restored-two',
        type: 'write_equation',
        sequenceIndex: 1,
        latex: '2x = 10',
      ),
    ];

    await tester.pumpWidget(
      buildBoard(actions: actions, animate: true, restored: true),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('teaching-board-action-restored-one')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('teaching-board-action-restored-two')),
      findsOneWidget,
    );
  });

  testWidgets('locked final answer remains hidden', (tester) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'hint',
        type: 'write_text',
        sequenceIndex: 0,
        text: 'Divide both sides by 2.',
      ),
      VisualTutorBoardActionEntity(
        id: 'final-answer',
        type: 'write_equation',
        sequenceIndex: 1,
        latex: 'x = 5',
        locked: true,
      ),
    ];

    await tester.pumpWidget(buildBoard(actions: actions));
    await tester.pump();

    expect(find.text('Divide both sides by 2.'), findsOneWidget);
    expect(find.text('x = 5'), findsNothing);

    await tester.pumpWidget(
      buildBoard(actions: actions, finalAnswerLocked: false),
    );
    await tester.pump();

    expect(find.text('x = 5'), findsOneWidget);
  });

  testWidgets('stuck quick action is routed correctly', (tester) async {
    final submissions = <VisualTutorStudentSubmission>[];
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildInteractionPanel(
        turn: turnFor(allowedActions: const ['stuck']),
        controller: controller,
        onSubmit: submissions.add,
      ),
    );

    await tester.tap(find.byKey(const Key('quick-action-stuck')));
    await tester.pump();

    expect(submissions.single.intent, 'stuck');
    expect(submissions.single.action, 'stuck');
    expect(submissions.single.inputType, 'quick_action');
  });

  testWidgets('numeric answer is submitted as numeric input', (tester) async {
    final submissions = <VisualTutorStudentSubmission>[];
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildInteractionPanel(
        turn: turnFor(
          interaction: const VisualTutorInteractionEntity(
            type: 'numeric_input',
            prompt: 'What is x?',
          ),
        ),
        controller: controller,
        onSubmit: submissions.add,
      ),
    );

    await tester.enterText(find.byKey(const Key('tutor-message-field')), '5');
    await tester.tap(find.byKey(const Key('tutor-send-button')));
    await tester.pump();

    expect(submissions.single.message, '5');
    expect(submissions.single.inputType, 'numeric_input');
    expect(submissions.single.intent, 'student_message');
    expect(submissions.single.action, 'student_message');
  });

  testWidgets('yes no answer is submitted', (tester) async {
    final submissions = <VisualTutorStudentSubmission>[];
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildInteractionPanel(
        turn: turnFor(
          interaction: const VisualTutorInteractionEntity(
            type: 'yes_no',
            prompt: 'Does this check?',
          ),
        ),
        controller: controller,
        onSubmit: submissions.add,
      ),
    );

    await tester.tap(find.byKey(const Key('choice-yes')));
    await tester.pump();

    expect(submissions.single.message, 'Yes');
    expect(submissions.single.inputType, 'yes_no');
  });

  testWidgets('quick actions are shown and hidden by allowed actions', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildInteractionPanel(
        turn: turnFor(allowedActions: const ['request_hint', 'request_answer']),
        controller: controller,
        onSubmit: (_) {},
      ),
    );

    expect(find.byKey(const Key('quick-action-hint')), findsOneWidget);
    expect(find.byKey(const Key('quick-action-show-answer')), findsOneWidget);
    expect(find.byKey(const Key('quick-action-stuck')), findsNothing);
    expect(find.byKey(const Key('quick-action-check-step')), findsNothing);
    expect(
      find.byKey(const Key('quick-action-explain-differently')),
      findsNothing,
    );
  });

  testWidgets('answer request submits to backend for adaptive reveal', (
    tester,
  ) async {
    final submissions = <VisualTutorStudentSubmission>[];
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildInteractionPanel(
        turn: turnFor(allowedActions: const ['request_answer']),
        controller: controller,
        onSubmit: submissions.add,
      ),
    );

    await tester.tap(find.byKey(const Key('quick-action-show-answer')));
    await tester.pump();

    expect(find.byKey(const Key('answer-locked-explanation')), findsNothing);
    expect(submissions.single.intent, 'request_answer');
    expect(submissions.single.action, 'request_answer');
    expect(submissions.single.message, 'Show answer');
  });

  testWidgets('same problem appends board writing instead of erasing', (
    tester,
  ) async {
    final repository = _QueuedTutorRepository([
      _askingQuestionTurn,
      _correctStepTurn,
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: TutorScreen(
            context: learningContext,
            repository: repository,
            initialSubmission: const VisualTutorStudentSubmission(
              message: '2x + 10 = 20',
              intent: 'student_message',
              action: 'student_message',
              inputType: 'text_response',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2x + 10 = 20'), findsOneWidget);
    expect(find.text('What number cancels 10?'), findsOneWidget);
    expect(find.text('Subtract ?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('tutor-message-field')),
      'subtract 10',
    );
    await tester.tap(find.byKey(const Key('tutor-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('2x + 10 = 20'), findsOneWidget);
    expect(find.text('What number cancels 10?'), findsOneWidget);
    expect(find.text('Subtract ?'), findsOneWidget);
    expect(find.text('Student: subtract 10'), findsOneWidget);
    expect(find.text('Yes, correct: subtract 10.'), findsOneWidget);
    expect(find.text('2x + 10 - 10 = 20 - 10'), findsOneWidget);
    expect(find.text('2x = 10'), findsOneWidget);
    expect(find.text('Step 2: divide both sides by 2'), findsOneWidget);

    final promptTop = tester
        .getTopLeft(find.text('What number cancels 10?'))
        .dy;
    final confirmationTop = tester
        .getTopLeft(find.text('Yes, correct: subtract 10.'))
        .dy;
    expect(confirmationTop, greaterThan(promptTop));
  });

  testWidgets('board grows beyond viewport and can scroll to later writing', (
    tester,
  ) async {
    final actions = [
      for (var i = 0; i < 18; i++)
        VisualTutorBoardActionEntity(
          id: 'line-$i',
          type: i.isEven ? 'write_equation' : 'write_text',
          sequenceIndex: i,
          y: 36.0 + i * 72,
          text: i.isEven ? null : 'Teaching note $i',
          latex: i.isEven ? 'line $i' : null,
          width: 760,
          height: 44,
        ),
    ];
    final repository = _QueuedTutorRepository([
      VisualTutorTurnResponseEntity(
        sessionId: 'test-session',
        turnId: 'long-board',
        spokenText: 'Keep going.',
        displayText: 'Keep going.',
        teachingMode: 'guided_question',
        finalAnswerLocked: true,
        studentTask: 'Continue.',
        board: const VisualTutorBoardEntity(type: 'equation_steps'),
        boardActions: actions,
        interaction: const VisualTutorInteractionEntity(
          type: 'text_response',
          prompt: 'Continue.',
        ),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: TutorScreen(
            context: learningContext,
            repository: repository,
            initialSubmission: const VisualTutorStudentSubmission(
              message: 'start',
              intent: 'student_message',
              action: 'student_message',
              inputType: 'text_response',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byKey(
      const Key('visual-tutor-board-vertical-scroll'),
    );
    expect(scrollable, findsOneWidget);
    final state = tester.state<ScrollableState>(
      find.descendant(of: scrollable, matching: find.byType(Scrollable)).first,
    );
    expect(state.position.maxScrollExtent, greaterThan(0));
  });
}

class _BoardRebuildHarness extends StatefulWidget {
  const _BoardRebuildHarness({required this.actions, required this.animate});

  final List<VisualTutorBoardActionEntity> actions;
  final bool animate;

  @override
  State<_BoardRebuildHarness> createState() => _BoardRebuildHarnessState();
}

class _BoardRebuildHarnessState extends State<_BoardRebuildHarness> {
  int rebuildCount = 0;

  void rebuild() {
    setState(() => rebuildCount++);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Column(
          children: [
            Text('rebuild-$rebuildCount'),
            SizedBox(
              width: 420,
              height: 360,
              child: TeachingCanvasBoard(
                actions: widget.actions,
                finalAnswerLocked: true,
                animate: widget.animate,
                actionInterval: const Duration(milliseconds: 120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuedTutorRepository implements VisualTutorRepository {
  _QueuedTutorRepository(this._responses);

  final List<VisualTutorTurnResponseEntity> _responses;
  int _index = 0;

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    return VisualTutorSessionEntity(
      sessionId: 'test-session',
      userId: request.userId,
      subject: request.subject,
      topic: request.topic,
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    return const VisualTutorSessionEntity(
      sessionId: 'test-session',
      userId: 'demo-user',
      subject: 'Mathematics',
      topic: 'Linear Equations',
    );
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) async {
    final response = _responses[_index.clamp(0, _responses.length - 1)];
    _index++;
    return response;
  }
}

const _askingQuestionTurn = VisualTutorTurnResponseEntity(
  sessionId: 'test-session',
  turnId: 'turn-1',
  screenState: 'asking_question',
  tutorStatus: 'Waiting for you',
  spokenText: 'Look at the constant 10. What operation cancels it?',
  displayText: 'Focus on the constant 10. Use the inverse operation.',
  teachingMode: 'guided_question',
  studentIntent: 'new_problem',
  finalAnswerLocked: true,
  studentTask: 'What first operation should we use?',
  board: VisualTutorBoardEntity(
    type: 'equation_steps',
    items: [
      VisualTutorBoardItemEntity(label: 'Problem', content: '2x + 10 = 20'),
      VisualTutorBoardItemEntity(
        label: 'Step 1',
        content: 'Subtract 10.',
        status: 'locked',
        metadata: {'operation': 'subtract 10'},
      ),
    ],
    metadata: {
      'screen_state': 'asking_question',
      'board_type': 'asking_question',
      'problem': '2x + 10 = 20',
      'normalized_problem': '2*x + 10 = 20',
      'coefficient': '2',
      'constant': '10',
      'current_step_index': 0,
      'handwritten_question': 'What number cancels 10?',
      'equation_with_blank': 'Subtract ?',
    },
  ),
  interaction: VisualTutorInteractionEntity(
    type: 'numeric_input',
    prompt: 'What number cancels 10?',
  ),
  allowedActions: ['submit_answer', 'request_hint', 'stuck'],
);

const _correctStepTurn = VisualTutorTurnResponseEntity(
  sessionId: 'test-session',
  turnId: 'turn-2',
  screenState: 'speaking_writing',
  tutorStatus: 'Waiting for you',
  spokenText: 'Yes. That gives 2x = 10. Now undo the 2 beside x.',
  displayText: '2x = 10. Next, use the inverse operation on 2x.',
  teachingMode: 'step_check',
  studentIntent: 'submitted_step',
  finalAnswerLocked: true,
  studentTask: 'What operation should we apply to both sides of 2x = 10?',
  board: VisualTutorBoardEntity(
    type: 'equation_steps',
    items: [
      VisualTutorBoardItemEntity(
        label: 'Problem',
        content: '2x + 10 = 20',
        status: 'complete',
      ),
      VisualTutorBoardItemEntity(
        label: 'Step 1',
        content: '2x = 10',
        status: 'complete',
        metadata: {'operation': 'subtract 10'},
      ),
    ],
    metadata: {
      'problem_type': 'linear_equation_one_variable',
      'normalized_problem': '2*x + 10 = 20',
      'coefficient': '2',
      'constant': '10',
      'current_step_index': 1,
      'feedback': 'correct_step',
    },
  ),
  metadata: {'board_update_mode': 'replace'},
  interaction: VisualTutorInteractionEntity(
    type: 'numeric_input',
    prompt: 'What operation should we apply to both sides of 2x = 10?',
  ),
  allowedActions: ['submit_answer', 'request_hint', 'stuck'],
);
