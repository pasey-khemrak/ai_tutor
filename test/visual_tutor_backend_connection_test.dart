import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const context = LearningContext(
    grade: 10,
    subject: 'Mathematics',
    topic: 'Linear Equations',
  );

  Future<void> pumpTutor(
    WidgetTester tester,
    _FakeTutorRepository repository, {
    String? initialSessionId,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: TutorScreen(
            context: context,
            repository: repository,
            initialSessionId: initialSessionId,
            userId: 'student-1',
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester, String message) async {
    await tester.enterText(find.byKey(const Key('tutor-message-field')), message);
    await tester.tap(find.byKey(const Key('tutor-send-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('text problem creates an authenticated session and tutor turn', (tester) async {
    final repository = _FakeTutorRepository();
    await pumpTutor(tester, repository);

    await submit(tester, '2x + 5 = 15');

    expect(repository.createdSessions, hasLength(1));
    expect(repository.createdSessions.single.userId, 'student-1');
    expect(repository.createdSessions.single.sessionMode, 'confirmed_problem');
    expect(repository.sentTurns, hasLength(1));
    expect(repository.sentTurns.single.message, '2x + 5 = 15');
    expect(repository.sentTurns.single.action, 'student_message');
    expect(repository.sentTurns.single.idempotencyKey, isNotEmpty);
    expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);
  });

  testWidgets('wrong step is sent with the persisted problem state for verification', (tester) async {
    final repository = _FakeTutorRepository();
    await pumpTutor(tester, repository);
    await submit(tester, '2x + 5 = 15');

    await submit(tester, '2x = 20');

    expect(repository.sentTurns, hasLength(2));
    expect(repository.sentTurns.last.action, 'student_message');
    expect(repository.sentTurns.last.currentState.problemText, '2x + 5 = 15');
  });

  testWidgets('hint and stuck actions are sent as explicit tutor intents', (tester) async {
    final repository = _FakeTutorRepository();
    await pumpTutor(tester, repository);
    await submit(tester, '2x + 5 = 15');

    await tester.tap(find.byKey(const Key('quick-action-hint')));
    await tester.pumpAndSettle();
    expect(repository.sentTurns.last.action, 'request_hint');

    await tester.tap(find.byKey(const Key('quick-action-stuck')));
    await tester.pumpAndSettle();
    expect(repository.sentTurns.last.action, 'request_stuck_help');
  });

  testWidgets('retry resends a failed tutor turn through the injected repository', (tester) async {
    final repository = _FakeTutorRepository(failFirstTurn: true);
    await pumpTutor(tester, repository);
    await submit(tester, '2x + 5 = 15');

    expect(find.byKey(const Key('visual-tutor-api-error')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(repository.sentTurns, hasLength(2));
    expect(find.byKey(const Key('visual-tutor-api-error')), findsNothing);
  });

  testWidgets('restores an existing session through the injected repository', (tester) async {
    final repository = _FakeTutorRepository();
    await pumpTutor(tester, repository, initialSessionId: 'session-resume-1');
    await tester.pumpAndSettle();

    expect(repository.restoredSessionIds, ['session-resume-1']);
    expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);
  });

  testWidgets('strict graph payload renders safely on a mobile board', (tester) async {
    final repository = _FakeTutorRepository(response: _response(graph: true));
    await pumpTutor(tester, repository);
    await submit(tester, 'Graph y = x²');

    expect(repository.sentTurns.single.message, 'Graph y = x²');
    expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);
  });

  testWidgets('controlled final reveal offers next practice only after tutor response', (tester) async {
    final repository = _FakeTutorRepository(response: _finalResponse());
    await pumpTutor(tester, repository);
    await submit(tester, 'x = 5');

    expect(find.byKey(const Key('final-answer-board')), findsOneWidget);
    expect(find.byKey(const Key('verified-pill')), findsOneWidget);
    await tester.tap(find.byKey(const Key('final-next-practice-button')));
    await tester.pumpAndSettle();
    expect(repository.sentTurns.last.metadata['mode'], 'next_practice');
  });

  testWidgets('unsupported problem has a friendly recovery path', (tester) async {
    final repository = _FakeTutorRepository(response: _unsupportedResponse());
    await pumpTutor(tester, repository);
    await submit(tester, 'prove a geometry theorem');

    expect(find.byKey(const Key('unsupported-problem-board')), findsOneWidget);
    await tester.tap(find.byKey(const Key('unsupported-try-another-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('unsupported-problem-board')), findsNothing);
  });
}

class _FakeTutorRepository implements VisualTutorRepository {
  _FakeTutorRepository({VisualTutorTurnResponseEntity? response, this.failFirstTurn = false})
      : response = response ?? _response();

  final VisualTutorTurnResponseEntity response;
  final bool failFirstTurn;
  final createdSessions = <VisualTutorSessionCreateRequestEntity>[];
  final restoredSessionIds = <String>[];
  final sentTurns = <VisualTutorTurnRequestEntity>[];

  @override
  Future<VisualTutorSessionEntity> createSession(VisualTutorSessionCreateRequestEntity request) async {
    createdSessions.add(request);
    return VisualTutorSessionEntity(
      sessionId: 'session-1', userId: request.userId, subject: request.subject, topic: request.topic,
      metadata: request.metadata,
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    restoredSessionIds.add(sessionId);
    return const VisualTutorSessionEntity(
      sessionId: 'session-resume-1', userId: 'student-1', subject: 'Mathematics',
      topic: 'Linear Equations', problemText: '2x + 5 = 15', currentStepIndex: 1,
    );
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(VisualTutorTurnRequestEntity request) async {
    sentTurns.add(request);
    if (failFirstTurn && sentTurns.length == 1) throw StateError('backend unavailable');
    return response;
  }
}

VisualTutorTurnResponseEntity _response({bool graph = false}) => VisualTutorTurnResponseEntity(
  sessionId: 'session-1', turnId: 'turn-1', spokenText: 'Let us take one small step.',
  displayText: 'Let us take one small step.', teachingMode: 'guided_question',
  finalAnswerLocked: true, studentTask: 'What should we do first?',
  board: const VisualTutorBoardEntity(type: 'teaching_stage', items: [
    VisualTutorBoardItemEntity(label: 'Problem', content: '2x + 5 = 15'),
  ], metadata: {'problem_text': '2x + 5 = 15', 'current_step_index': 0}),
  speech: const VisualTutorSpeechEntity(text: 'Let us take one small step.'),
  teachingStage: const VisualTutorTeachingStageEntity(stageState: 'waiting_for_student', lessonState: 'ask'),
  boardActions: [
    VisualTutorBoardActionEntity(
      id: graph ? 'graph-1' : 'equation-1', type: graph ? 'show_graph' : 'write_equation',
      sequenceIndex: 0, x: 24, y: 64, width: 300, height: 220,
      text: graph ? null : '2x + 5 = 15', latex: graph ? null : '2x + 5 = 15',
      graph: graph ? const {
        'x_min': -5.0, 'x_max': 5.0, 'y_min': -5.0, 'y_max': 5.0,
        'function_expression': 'x^2', 'domain': [-5.0, 5.0],
      } : null,
    ),
  ],
  interaction: const VisualTutorInteractionEntity(type: 'text_response', prompt: 'What should we do first?'),
  allowedActions: const ['request_hint', 'stuck', 'check_work', 'request_answer', 'explain_differently'],
  metadata: const {'board_schema_version': 1, 'board_version': 1, 'base_board_version': 0},
);

VisualTutorTurnResponseEntity _finalResponse() => VisualTutorTurnResponseEntity(
  sessionId: 'session-1', turnId: 'turn-final',
  spokenText: 'Excellent work. The verified answer is x = 5.',
  displayText: 'Excellent work. The verified answer is x = 5.',
  teachingMode: 'step_check', finalAnswerLocked: false, masterySignal: 'mastered',
  studentTask: 'Ready for the next practice problem?',
  board: const VisualTutorBoardEntity(type: 'equation_steps', items: [
    VisualTutorBoardItemEntity(label: 'Problem', content: '2x + 5 = 15'),
    VisualTutorBoardItemEntity(label: 'Final', content: 'x = 5'),
  ], metadata: {'screen_state': 'final_verified_answer', 'problem_text': '2x + 5 = 15'}),
  speech: const VisualTutorSpeechEntity(text: 'Excellent work. The verified answer is x = 5.'),
  teachingStage: const VisualTutorTeachingStageEntity(stageState: 'waiting_for_student', lessonState: 'complete'),
  interaction: const VisualTutorInteractionEntity(type: 'text_response', prompt: 'Ready for the next practice problem?'),
  allowedActions: const ['request_hint'],
  metadata: const {'board_schema_version': 1, 'board_version': 1, 'base_board_version': 0},
);

VisualTutorTurnResponseEntity _unsupportedResponse() => VisualTutorTurnResponseEntity(
  sessionId: 'session-1', turnId: 'turn-unsupported',
  spokenText: 'This problem is not supported yet.', displayText: 'This problem is not supported yet.',
  teachingMode: 'guided_question', finalAnswerLocked: true, studentTask: 'Try another problem.',
  board: const VisualTutorBoardEntity(type: 'formula_card', title: 'Unsupported Problem', metadata: {
    'screen_state': 'unsupported_problem',
    'friendly_message': 'This problem is not supported yet.',
  }),
  speech: const VisualTutorSpeechEntity(text: 'This problem is not supported yet.'),
  teachingStage: const VisualTutorTeachingStageEntity(stageState: 'waiting_for_student', lessonState: 'understand_request'),
  interaction: const VisualTutorInteractionEntity(type: 'text_response', prompt: 'Try another problem.', inputEnabled: false),
  metadata: const {'screen_state': 'unsupported_problem', 'board_schema_version': 1, 'board_version': 1, 'base_board_version': 0},
);
