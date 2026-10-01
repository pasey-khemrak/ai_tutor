import 'package:ai_tutor/app/tutor_shell.dart';
import 'package:ai_tutor/core/localization/app_language_controller.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_screen.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _limitsLesson = StudentLesson(
  lessonId: 'math.g12.lesson1.limits-of-functions',
  curriculumVersionId: 'g12-stem-math-v1',
  gradeLevelId: 'grade-12',
  grade: 12,
  subjectId: 'math',
  subject: 'Mathematics',
  topicId: 'limits-of-functions-g12',
  topic: 'Limits of Functions',
  title: 'លីមីតនៃអនុគមន៍',
  englishTitle: 'Limits of Functions',
  description: 'Evaluate finite limits and resolve 0/0 indeterminate forms.',
  khmerDescription: 'គណនាលីមីតកំណត់ និងរាងមិនកំណត់ 0/0។',
  difficulty: 'advanced',
  starterProblem: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
  isAvailable: true,
  problemCount: 4,
);

class _MockLessonsRepository implements StudentLessonsRepository {
  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  }) async {
    return [_limitsLesson];
  }

  @override
  Future<LessonDetailedContent> loadLessonContent(String lessonId) async {
    return const LessonDetailedContent(
      lessonId: 'math.g12.lesson1.limits-of-functions',
      title: 'លីមីតនៃអនុគមន៍ (Limits of Functions)',
      topicId: 'limits-of-functions-g12',
      topicName: 'Limits of Functions',
      topicKhmerName: 'លីមីតនៃអនុគមន៍',
      subjectId: 'math',
      subjectName: 'Mathematics',
      gradeNumber: 12,
      gradeName: 'Grade 12',
      learningObjectives: ['Evaluate finite limits'],
      concepts: [
        LessonConceptItem(
          title: 'Direct Substitution',
          summary: 'Evaluate f(a) directly',
          body: 'If f is continuous at x = a, lim_{x->a} f(x) = f(a).',
        ),
      ],
      formulas: [
        LessonFormulaItem(
          name: 'Indeterminate Form 0/0',
          expression: r'\lim_{x \to a} \frac{P(x)}{Q(x)}',
          explanation: 'Factor common factor (x - a)',
        ),
      ],
      examples: [
        LessonExampleItem(
          problem: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
          solution: '6',
          steps: [
            'Factor numerator: (x - 3)(x + 3)',
            'Cancel common factor (x - 3)',
            'Substitute x = 3: 3 + 3 = 6',
          ],
        ),
      ],
      commonMisconceptions: ['Assuming 0/0 is 1 or 0'],
      khmerTerms: {'limit': 'លីមីត'},
      starterProblem: r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
    );
  }
}

class _DemonstrationRepository implements VisualTutorRepository {
  final List<VisualTutorTurnRequestEntity> requests = [];

  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    return VisualTutorSessionEntity(
      sessionId: 'demo-session-1',
      userId: request.userId,
      subject: request.subject,
      topic: request.topic,
      problemText: request.problemText,
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    return VisualTutorSessionEntity(
      sessionId: sessionId,
      userId: 'student-1',
      subject: 'Mathematics',
      topic: 'Limits of Functions',
    );
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) async {
    requests.add(request);
    final isKhmer = request.languageMode == 'khmer';
    final invitation = isKhmer
        ? 'តើអ្នកមានសំណួរអ្វីខ្លះអំពីជំហាននេះ ឬចង់សាកល្បងដោយខ្លួនឯង?'
        : 'Do you have any questions about this step, or would you like to try one yourself?';
    return VisualTutorTurnResponseEntity(
      turnId: 'turn-${requests.length}',
      sessionId: 'demo-session-1',
      spokenText: invitation,
      displayText: invitation,
      teachingMode: 'full_solution',
      finalAnswerLocked: false,
      studentTask: invitation,
      board: const VisualTutorBoardEntity(
        type: 'equation_steps',
        title: 'Worked solution',
        items: [],
        metadata: {'worked_solution': true},
      ),
      boardActions: [
        const VisualTutorBoardActionEntity(
          id: 'ws-step-factor-0',
          type: 'write_text',
          sequenceIndex: 0,
          durationMs: 100,
          layoutZone: 'working',
          layoutFlow: 'vertical',
          sectionId: 'step-factor',
          text: 'Step 1 · Factor numerator and cancel common factor (x - 3).',
        ),
        const VisualTutorBoardActionEntity(
          id: 'ws-step-factor-1',
          type: 'write_equation',
          sequenceIndex: 1,
          durationMs: 100,
          layoutZone: 'working',
          layoutFlow: 'vertical',
          sectionId: 'step-factor',
          latex: r'\lim_{x \to 3} (x + 3) = 6',
        ),
        VisualTutorBoardActionEntity(
          id: 'ws-next-2',
          type: 'student_task',
          sequenceIndex: 2,
          durationMs: 0,
          layoutZone: 'student_task',
          layoutFlow: 'vertical',
          sectionId: 'next',
          text: invitation,
          requiresStudentResponse: true,
        ),
      ],
      interaction: VisualTutorInteractionEntity(
        type: 'text_response',
        prompt: invitation,
        expectedAnswerLocked: false,
        inputEnabled: true,
      ),
      metadata: const {
        'board_version': 1,
        'base_board_version': 0,
      },
    );
  }
}

void _silenceMediaPlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> handle(MethodCall call) async {
    final playerId = call.arguments is Map
        ? (call.arguments as Map)['playerId']
        : null;
    if (playerId is String) {
      messenger.setMockStreamHandler(
        EventChannel('xyz.luan/audioplayers/events/$playerId'),
        MockStreamHandler.inline(onListen: (arguments, sink) {}),
      );
    }
    return null;
  }

  for (final channel in const [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers',
    'com.llfbandit.record/messages',
  ]) {
    messenger.setMockMethodCallHandler(MethodChannel(channel), handle);
  }
  messenger.setMockStreamHandler(
    const EventChannel('xyz.luan/audioplayers.global/events'),
    MockStreamHandler.inline(onListen: (arguments, sink) {}),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _silenceMediaPlugins();
    AppLanguageController.setLanguage('en');
  });

  Widget wrap(Widget child, {Locale locale = const Locale('en')}) =>
      MaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('km')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      );

  void useDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  test(
    'demonstrationSubmissionForLesson builds submission with exact required contract',
    () {
      const example = r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}';
      final context = learningContextForLesson(_limitsLesson);
      final submission = demonstrationSubmissionForLesson(
        _limitsLesson,
        example,
      );

      expect(context.isCurriculumScoped, isTrue);
      expect(context.lessonId, _limitsLesson.lessonId);
      expect(context.topicId, _limitsLesson.topicId);
      expect(context.subjectId, _limitsLesson.subjectId);
      expect(context.grade, _limitsLesson.grade);

      expect(submission.message, example);
      expect(submission.action, 'submit_problem');
      expect(submission.intent, 'new_problem');
      expect(submission.metadata['entry_point'], 'lesson_demonstration');
      expect(submission.metadata['auto_start'], isTrue);
    },
  );

  testWidgets(
    'clicking Watch on Whiteboard in lesson walkthrough triggers onWatchDemonstration',
    (tester) async {
      useDesktopSurface(tester);
      StudentLesson? watchedLesson;
      String? watchedProblem;

      await tester.pumpWidget(
        wrap(
          StudentLessonsScreen(
            repository: _MockLessonsRepository(),
            onOpenLesson: (_) {},
            onPractice: (_) {},
            onWatchDemonstration: (lesson, problem) {
              watchedLesson = lesson;
              watchedProblem = problem;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the lesson card
      await tester.tap(
        find.byKey(Key('lesson-card-${_limitsLesson.lessonId}')),
      );
      await tester.pumpAndSettle();

      // Navigate to Tab 2 (Step-by-Step Example)
      await tester.tap(
        find.byKey(const Key('tab-examples')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Click "Watch on Whiteboard"
      final watchBtn = find.byKey(const Key('lesson-watch-whiteboard-button'));
      expect(watchBtn, findsOneWidget);
      await tester.ensureVisible(watchBtn);
      await tester.tap(watchBtn);
      await tester.pumpAndSettle();

      expect(watchedLesson, _limitsLesson);
      expect(watchedProblem, r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}');
    },
  );

  testWidgets(
    'TutorScreen auto-starts lesson demonstration, plays worked solution, invites student, and keeps voice & chat active',
    (tester) async {
      useDesktopSurface(tester);
      final repository = _DemonstrationRepository();
      const example = r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}';

      await tester.pumpWidget(
        wrap(
          TutorScreen(
            repository: repository,
            userId: 'student-1',
            context: learningContextForLesson(_limitsLesson),
            initialSubmission: demonstrationSubmissionForLesson(
              _limitsLesson,
              example,
            ),
          ),
        ),
      );

      // Let post-frame callback and async turn submission execute without user input
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      // Verify auto-submission happened without typing or pressing Send
      expect(repository.requests, hasLength(1));
      final firstReq = repository.requests.first;
      expect(firstReq.message, example);
      expect(firstReq.action, 'submit_problem');
      expect(firstReq.metadata['entry_point'], 'lesson_demonstration');
      expect(firstReq.metadata['auto_start'], isTrue);

      // Verify worked solution and invitation prompt are rendered
      expect(
        find.textContaining(
          'Do you have any questions about this step, or would you like to try one yourself?',
        ),
        findsWidgets,
      );

      // Verify chat input and voice input remain active for follow-up questions
      final messageFieldFinder = find.byKey(const Key('tutor-message-field'));
      expect(messageFieldFinder, findsOneWidget);
      final messageField = tester.widget<TextField>(messageFieldFinder);
      expect(messageField.enabled, isTrue);

      final voiceButtonFinder = find.byKey(const Key('voice-response-button'));
      expect(voiceButtonFinder, findsOneWidget);
      final voiceButton = tester.widget<FilledButton>(voiceButtonFinder);
      expect(voiceButton.onPressed, isNotNull);

      // Student can type a follow-up question and send it
      await tester.enterText(messageFieldFinder, 'Why can we cancel (x - 3)?');
      await tester.pump();
      final sendButtonFinder = find.byKey(const Key('tutor-send-button'));
      await tester.tap(sendButtonFinder);
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.requests, hasLength(2));
      expect(repository.requests[1].message, 'Why can we cancel (x - 3)?');
    },
  );

  testWidgets(
    'TutorScreen renders Khmer invitation at the end of a Khmer lesson demonstration',
    (tester) async {
      useDesktopSurface(tester);
      AppLanguageController.setLanguage('km');
      final repository = _DemonstrationRepository();
      final khmerLesson = _limitsLesson.copyWith(languageMode: 'khmer');
      const example = r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}';

      await tester.pumpWidget(
        wrap(
          TutorScreen(
            repository: repository,
            userId: 'student-1',
            context: learningContextForLesson(khmerLesson),
            initialSubmission: demonstrationSubmissionForLesson(
              khmerLesson,
              example,
            ),
          ),
          locale: const Locale('km'),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));

      expect(repository.requests, hasLength(1));
      expect(
        find.textContaining(
          'តើអ្នកមានសំណួរអ្វីខ្លះអំពីជំហាននេះ ឬចង់សាកល្បងដោយខ្លួនឯង?',
        ),
        findsWidgets,
      );
    },
  );
}
