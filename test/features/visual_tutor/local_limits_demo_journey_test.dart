import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/features/visual_tutor/local_mvp_limits_fallback.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/live_board_state.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

const _context = LearningContext(
  grade: 12,
  subject: 'Mathematics',
  topic: 'Limits of Functions',
  gradeLevelId: 'grade-12',
  subjectId: 'math',
  topicId: 'math-g12-limits-of-functions',
  lessonId: 'math.g12.lesson1.limits-of-functions',
  curriculumVersionId: 'local-g12-math-limits-2025-10-01-v1',
  teachingMomentId: 'math.g12.lesson1.limits-of-functions.finite-at-point.01',
  languageMode: 'khmer',
);

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

class _OfflineRepository implements VisualTutorRepository {
  int createCalls = 0;
  int turnCalls = 0;

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    createCalls += 1;
    throw const ApiException(message: 'offline', statusCode: 503);
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) =>
      throw UnsupportedError('not used');

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) async {
    turnCalls += 1;
    throw const ApiException(message: 'offline', statusCode: 503);
  }
}

const _boardScrollKey = Key('visual-tutor-board-vertical-scroll');

ScrollController _boardController(WidgetTester tester) => tester
    .widget<SingleChildScrollView>(find.byKey(_boardScrollKey))
    .controller!;

Future<void> _openLimits(WidgetTester tester, _OfflineRepository repository) async {
  await tester.pumpWidget(_wrap(TutorScreen(
    context: _context,
    repository: repository,
    initialSubmission: const VisualTutorStudentSubmission(
      message: 'Start local curriculum demo.',
      intent: 'new_problem',
      action: 'submit_problem',
      inputType: 'quick_action',
    ),
  )));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'Limits first action is visible immediately and Khmer text wraps',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final offline = _OfflineRepository();
      await tester.pumpWidget(
        _wrap(
          TutorScreen(
            context: _context,
            repository: offline,
            initialSubmission: const VisualTutorStudentSubmission(
              message: 'Start local curriculum demo.',
              intent: 'new_problem',
              action: 'submit_problem',
              inputType: 'quick_action',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('teaching-board-action-limits-equation')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      final equation = find.byKey(const Key('teaching-board-action-limits-equation'));
      final viewport = tester.getRect(find.byKey(_boardScrollKey));
      expect(viewport.overlaps(tester.getRect(equation)), isTrue,
          reason: 'The first action must remain inside the visible viewport after playback.');
      expect(_boardController(tester).offset, closeTo(0, 1),
          reason: 'Already-visible semantic content must not move to canvas padding.');
      expect(find.text('តើ f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1?'), findsWidgets);
      expect(
        find.byKey(const Key('local-curriculum-demo-label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('student-interaction-panel')),
        findsOneWidget,
      );
      expect(
        find.text('5'),
        findsNothing,
        reason: 'The final limit answer is locked.',
      );
      expect(offline.createCalls, 0);
      expect(offline.turnCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tablet opening has painted content inside the teaching viewport', (tester) async {
    tester.view.physicalSize = const Size(664, 758);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _openLimits(tester, _OfflineRepository());
    await tester.pump(const Duration(seconds: 3));
    final action = find.byKey(const Key('teaching-board-action-limits-equation'));
    final rect = tester.getRect(action);
    final viewport = tester.getRect(find.byKey(_boardScrollKey));
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    expect(viewport.overlaps(rect), isTrue);
    expect(rect.top, lessThan(viewport.top + 200));
    final opacity = tester.widgetList<Opacity>(find.ancestor(of: action, matching: find.byType(Opacity)));
    expect(opacity.every((widget) => widget.opacity > 0), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('correct 5 advances one moment and refresh restores that board offline', (tester) async {
    final offline = _OfflineRepository();
    await _openLimits(tester, offline);
    await tester.enterText(find.byKey(const Key('tutor-message-field')), '5');
    await tester.tap(find.byKey(const Key('tutor-send-button')));
    await tester.pumpAndSettle();
    final board = tester.widget<TeachingCanvasBoard>(find.byType(TeachingCanvasBoard));
    expect(board.actions.map((action) => action.id),
        ['limits-symbolic-equation', 'limits-student-task']);
    expect(board.finalAnswerLocked, isTrue);
    expect(board.actions.last.text, 'ចំពោះ x ≠ 1 តើ f(x) សម្រួលបានជា​អ្វី?');
    expect(find.textContaining('ត្រឹមត្រូវ។ យើងបន្តមួយជំហានទៀត។'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await _openLimits(tester, offline);
    final restored = tester.widget<TeachingCanvasBoard>(find.byType(TeachingCanvasBoard));
    expect(restored.actions.map((action) => action.id), board.actions.map((action) => action.id));
    expect(restored.actions.last.text, board.actions.last.text);
    expect(restored.finalAnswerLocked, isTrue);
    expect(offline.createCalls, 0);
    expect(offline.turnCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrong answer reteaches one point and Hint changes representation', (tester) async {
    final offline = _OfflineRepository();
    await _openLimits(tester, offline);
    await tester.enterText(find.byKey(const Key('tutor-message-field')), '0');
    await tester.tap(find.byKey(const Key('tutor-send-button')));
    await tester.pumpAndSettle();
    var board = tester.widget<TeachingCanvasBoard>(find.byType(TeachingCanvasBoard));
    expect(board.actions.last.text, 'តើ f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1?');
    expect(board.finalAnswerLocked, isTrue);
    expect(find.textContaining('សង្កេតតម្លៃនៅជិត 1 មិនមែនតម្លៃត្រង់ x = 1 ទេ។'), findsWidgets);
    await tester.tap(find.byKey(const Key('quick-action-hint')));
    await tester.pumpAndSettle();
    board = tester.widget<TeachingCanvasBoard>(find.byType(TeachingCanvasBoard));
    expect(board.actions.first.id, 'limits-symbolic-equation');
    expect(board.actions.last.text, 'តើ f(x) ខិតជិតលេខណា នៅពេល x ខិតជិត 1?');
    expect(board.finalAnswerLocked, isTrue);
    expect(offline.turnCalls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final wheel in [false, true]) {
    testWidgets('recent manual ${wheel ? 'wheel' : 'drag'} scroll blocks auto follow on a new moment', (tester) async {
      await _openLimits(tester, _OfflineRepository());
      final scroll = find.byKey(_boardScrollKey);
      if (wheel) {
        await tester.sendEventToBinding(PointerScrollEvent(
          position: tester.getTopLeft(scroll) + const Offset(100, 90),
          scrollDelta: const Offset(0, 220),
        ));
        await tester.pumpAndSettle();
      } else {
        await tester.dragFrom(tester.getTopLeft(scroll) + const Offset(100, 160), const Offset(0, -220));
        await tester.pumpAndSettle();
      }
      final offset = _boardController(tester).offset;
      expect(offset, greaterThan(100));
      await tester.tap(find.byKey(const Key('quick-action-hint')));
      await tester.pumpAndSettle();
      expect(_boardController(tester).offset, closeTo(offset, 1),
          reason: 'A new teaching action must respect recent learner scrolling.');
      expect(tester.takeException(), isNull);
    });
  }

  test('opening fallback has a locked answer and no answer-key fields', () {
    final response = buildLocalMvpLimitsOpeningFallback(sessionId: 'local');
    expect(response.finalAnswerLocked, isTrue);
    expect(response.boardActions, hasLength(3));
    expect(response.boardActions.last.requiresStudentResponse, isTrue);
    expect(response.allowedActions, contains('request_answer'));
    expect(response.metadata.toString(), isNot(contains('accepted_answer')));
    expect(
      response.metadata.toString(),
      isNot(contains('final_answer_reveal')),
    );
  });

  testWidgets('an invalid sibling cannot blank the valid Limits action', (
    tester,
  ) async {
    const actions = [
      VisualTutorBoardActionEntity(
        id: 'limits-equation',
        type: 'write_equation',
        latex: 'f(x) = (2x² + x − 3) / (x − 1)',
      ),
      VisualTutorBoardActionEntity(
        id: 'invalid-sibling',
        type: 'remote_widget',
        text: 'not allowed',
      ),
    ];
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 390,
          height: 320,
          child: TeachingCanvasBoard(
            actions: actions,
            finalAnswerLocked: true,
            animate: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('teaching-board-recovery-notice')), findsOneWidget);
    expect(isValidBoardAction(actions.first), isTrue);
    expect(isValidBoardAction(actions.last), isFalse);
    expect(
      find.byKey(const Key('teaching-board-action-limits-equation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('teaching-board-action-invalid-sibling')),
      findsNothing,
    );
  });

  testWidgets('the typed final reveal is hidden while locked and visible only when unlocked', (
    tester,
  ) async {
    const action = VisualTutorBoardActionEntity(
      id: 'limits-final-reveal',
      type: 'final_answer_reveal',
      text: 'លីមីតនៃអនុគមន៍នេះគឺ 5។',
      layoutZone: 'feedback',
      layoutFlow: 'vertical',
    );
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 390,
          height: 320,
          child: TeachingCanvasBoard(
            actions: [action],
            finalAnswerLocked: true,
            animate: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('លីមីតនៃអនុគមន៍នេះគឺ 5។'), findsNothing);

    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 390,
          height: 320,
          child: TeachingCanvasBoard(
            actions: [action],
            finalAnswerLocked: false,
            animate: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('លីមីតនៃអនុគមន៍នេះគឺ 5។'), findsOneWidget);
  });
}
