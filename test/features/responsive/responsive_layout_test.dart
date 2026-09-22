import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/domain/repositories/visual_tutor_repository.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pagination.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/board_page_switcher.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_repository.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_screen.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_screen.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:ai_tutor/screens/tutor/visual_tutor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void _silenceMediaPlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> handle(MethodCall call) async => null;

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

class _DummyTutorRepository implements VisualTutorRepository {
  @override
  Future<VisualTutorSessionEntity> createSession(
    VisualTutorSessionCreateRequestEntity request,
  ) async {
    return VisualTutorSessionEntity(
      sessionId: 'session-test',
      userId: request.userId,
      subject: request.subject,
      topic: request.topic,
    );
  }

  @override
  Future<VisualTutorSessionEntity> restoreSession(String sessionId) async {
    return const VisualTutorSessionEntity(
      sessionId: 'session-test',
      userId: 'student-test',
      subject: 'Mathematics',
      topic: 'Limits of Functions',
    );
  }

  @override
  Future<VisualTutorTurnResponseEntity> sendTurn(
    VisualTutorTurnRequestEntity request,
  ) async {
    return const VisualTutorTurnResponseEntity(
      sessionId: 'session-test',
      turnId: 'turn-test',
      teachingMode: 'worked_solution',
      finalAnswerLocked: true,
      spokenText: 'Test speech',
      displayText: 'Test step explanation',
      studentTask: 'What is the limit value?',
      speech: VisualTutorSpeechEntity(text: 'Test speech', language: 'en'),
      board: VisualTutorBoardEntity(
        type: 'speaking_writing',
        title: 'Limit Problem',
      ),
      boardActions: [
        VisualTutorBoardActionEntity(
          id: 'step-1-text',
          type: 'write_text',
          layoutZone: 'working',
          text: 'Step 1: Simplify expression',
        ),
      ],
    );
  }
}

class _MockDashboardRepository implements DashboardRepository {
  @override
  Future<StudentDashboardData?> loadDashboard() async {
    return const StudentDashboardData(
      studentName: 'Sophea',
      gradeLabel: 'Grade 12',
      subjects: ['Mathematics', 'Physics', 'Chemistry'],
      learningStreakDays: 3,
      recentActivity: [
        DashboardActivity(
          title: 'Limits of Functions',
          subtitle: 'Completed 4 steps',
          timeLabel: '2 hours ago',
        ),
      ],
      subjectProgress: [
        SubjectProgress(
          subject: 'Mathematics',
          topic: 'Limits of Functions',
          progress: 0.85,
        ),
      ],
      weakTopic: null,
      resumeTitle: 'Limits of Functions',
      resumeSubtitle: 'Step 3 of 5',
    );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    _silenceMediaPlugins();
  });

  const sizes = {
    'phone': Size(400, 800),
    'tablet_portrait': Size(834, 1112),
    'tablet_landscape': Size(1112, 834),
    'desktop': Size(1440, 900),
  };

  group('Responsive Layout: TutorScreen', () {
    for (final entry in sizes.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('renders on $name (${size.width}x${size.height}) without overflow', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            TutorScreen(
              context: const LearningContext(
                grade: 12,
                subject: 'Mathematics',
                topic: 'Limits of Functions',
              ),
              repository: _DummyTutorRepository(),
              userId: 'student-test',
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('tutor-presence-bar')), findsOneWidget);
        expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);

        if (name == 'phone') {
          // On phone: 1-column layout, whiteboard is hero, chat dock is below the board.
          expect(find.byKey(const Key('tutor-side-panel')), findsNothing);
          expect(find.byKey(const Key('tutor-phone-dock')), findsOneWidget);

          final boardBottom = tester.getBottomLeft(
            find.byKey(const Key('visual-tutor-board-vertical-scroll')),
          ).dy;
          final dockTop = tester.getTopLeft(
            find.byKey(const Key('tutor-phone-dock')),
          ).dy;
          expect(
            dockTop,
            greaterThanOrEqualTo(boardBottom - 2),
            reason: 'On phone, the chat dock is docked below the hero board',
          );
        } else {
          // On tablet and desktop: 2-column layout, controls beside the board.
          expect(find.byKey(const Key('tutor-side-panel')), findsOneWidget);
          expect(find.byKey(const Key('tutor-phone-dock')), findsNothing);

          final boardRight = tester.getTopRight(
            find.byKey(const Key('visual-tutor-canvas-board')),
          ).dx;
          final panelLeft = tester.getTopLeft(
            find.byKey(const Key('tutor-side-panel')),
          ).dx;
          expect(
            panelLeft,
            greaterThanOrEqualTo(boardRight - 2),
            reason: 'On $name, the controls panel is beside the board',
          );
        }
      });
    }
  });

  group('Responsive Layout: StudentLessonsScreen', () {
    for (final entry in sizes.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('renders on $name without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            StudentLessonsScreen(
              repository: const LocalDemoStudentLessonsRepository(),
              onOpenLesson: (_) {},
              onPractice: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('lessons-search-field')), findsOneWidget);
      });
    }
  });

  group('Responsive Layout: VisualTutorHomeScreen', () {
    for (final entry in sizes.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('renders on $name without overflow and is centered on desktop', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            VisualTutorHomeScreen(
              repository: const LocalDemoStudentLessonsRepository(),
              onOpenLesson: (_) {},
              onAskQuestion: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final search = find.byKey(const Key('curriculum-search-field'));
        expect(search, findsOneWidget);

        if (name == 'desktop') {
          // On desktop (1440 wide), content is horizontally centered.
          final center = tester.getRect(search).center.dx;
          expect((center - size.width / 2).abs(), lessThan(10.0));
        }
      });
    }
  });

  group('Responsive Layout: DashboardScreen', () {
    for (final entry in sizes.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('renders on $name without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            DashboardScreen(
              repository: _MockDashboardRepository(),
              onResumeLearning: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('dashboard-greeting')), findsOneWidget);
      });
    }
  });

  group('Touch Target Dimensions >= 44pt', () {
    testWidgets('BoardArrowButton in BoardPageSwitcher has min touch target >= 44pt', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BoardPageSwitcher(
            pages: const [
              BoardPage(index: 0, actions: []),
              BoardPage(index: 1, actions: []),
            ],
            currentIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );
      await tester.pump();

      final nextBtnSize = tester.getSize(find.byKey(const Key('visual-tutor-board-next')));
      expect(nextBtnSize.width, greaterThanOrEqualTo(44.0));
      expect(nextBtnSize.height, greaterThanOrEqualTo(44.0));

      final prevBtnSize = tester.getSize(find.byKey(const Key('visual-tutor-board-previous')));
      expect(prevBtnSize.width, greaterThanOrEqualTo(44.0));
      expect(prevBtnSize.height, greaterThanOrEqualTo(44.0));
    });
  });

  group('Board Pagination across Form Factors (Board 1/2/3)', () {
    List<VisualTutorBoardActionEntity> solution({int steps = 8}) => [
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

    const boardSizes = {
      'phone': Size(400, 500),
      'tablet_portrait': Size(494, 900),
      'tablet_landscape': Size(772, 700),
      'desktop': Size(1040, 800),
    };

    for (final entry in boardSizes.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('paginates and navigates Board 1/2/3 on $name (${size.width}x${size.height})', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: size.width,
              height: size.height,
              child: TeachingCanvasBoard(
                variant: 'speaking_writing',
                actions: solution(steps: 8),
                finalAnswerLocked: false,
                reducedMotion: true,
                restored: true,
                useLogicalCanvasScale: true,
                pageViewportHeight: size.height,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Paging controls appear for an 8-step solution
        expect(find.byKey(const Key('visual-tutor-board-pages')), findsOneWidget);
        expect(find.byKey(const Key('teaching-board-action-step-0-text')), findsOneWidget);

        // Switch to Board 2
        await tester.tap(find.byKey(const Key('visual-tutor-board-next')));
        await tester.pump(const Duration(milliseconds: 300));

        // Step 0 is not on Board 2
        expect(find.byKey(const Key('teaching-board-action-step-0-text')), findsNothing);

        // Switch back to Board 1
        await tester.tap(find.byKey(const Key('visual-tutor-board-previous')));
        await tester.pump(const Duration(milliseconds: 300));

        // Step 0 is back
        expect(find.byKey(const Key('teaching-board-action-step-0-text')), findsOneWidget);
      });
    }
  });
}
