import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_repository.dart';
import 'package:ai_tutor/screens/progress/student_progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubRepository implements DashboardRepository {
  const _StubRepository(this.data);
  final StudentDashboardData? data;
  @override
  Future<StudentDashboardData?> loadDashboard() async => data;
}

class _FailingRepository implements DashboardRepository {
  const _FailingRepository();
  @override
  Future<StudentDashboardData?> loadDashboard() async =>
      throw Exception('backend down');
}

const _populated = StudentDashboardData(
  studentName: 'Dara',
  gradeLabel: 'Grade 11',
  subjects: ['Mathematics', 'Physics'],
  learningStreakDays: 4,
  totalSessions: 9,
  lessonsCompleted: 5,
  quizAttempts: 3,
  averageQuizScore: 82,
  completedPractice: 6,
  recentActivity: [],
  subjectProgress: [
    SubjectProgress(
      subject: 'Mathematics',
      topic: 'Linear Equations',
      progress: .9,
      subjectId: 'mathematics',
      topicId: 'linear-equations',
      lessonsCompleted: 3,
      quizAttempts: 2,
      correctAnswers: 9,
      totalAnswers: 10,
      averageQuizScore: 90,
      readiness: 'ready',
    ),
    SubjectProgress(
      subject: 'Physics',
      topic: 'Kinematics',
      progress: .35,
      subjectId: 'physics',
      topicId: 'kinematics',
      lessonsCompleted: 1,
      quizAttempts: 1,
      correctAnswers: 3,
      totalAnswers: 9,
      readiness: 'needs_practice',
    ),
  ],
  weakTopic: WeakTopic(
    title: 'Kinematics',
    reason: 'Only 3 of 9 recent answers were correct.',
    actionLabel: 'Practice now',
    topicId: 'kinematics',
  ),
  resumeTitle: 'Linear Equations',
  resumeSubtitle: 'Continue',
);

const _empty = StudentDashboardData(
  studentName: 'Dara',
  gradeLabel: 'Grade 11',
  subjects: [],
  learningStreakDays: 0,
  recentActivity: [],
  subjectProgress: [],
  weakTopic: null,
  resumeTitle: 'Start learning',
  resumeSubtitle: 'Choose a goal',
);

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.dark(),
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  testWidgets('progress groups topics under their subject with mastery', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const StudentProgressScreen(repository: _StubRepository(_populated))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);
    expect(find.byKey(const Key('progress-topic-linear-equations')), findsOneWidget);
    expect(find.byKey(const Key('progress-topic-kinematics')), findsOneWidget);
    expect(find.byKey(const Key('progress-stats-row')), findsOneWidget);
  });

  testWidgets('progress shows the weak topic and offers practice', (
    tester,
  ) async {
    String? practisedTopic;
    await tester.pumpWidget(
      _wrap(
        StudentProgressScreen(
          repository: const _StubRepository(_populated),
          onPracticeTopic: (topicId, subjectId) => practisedTopic = topicId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final practice = find.byKey(const Key('progress-practice-button'));
    expect(practice, findsOneWidget);
    await tester.ensureVisible(practice);
    await tester.tap(practice);
    expect(practisedTopic, 'kinematics');
  });

  testWidgets('progress empty state invites a first session', (tester) async {
    var started = false;
    await tester.pumpWidget(
      _wrap(
        StudentProgressScreen(
          repository: const _StubRepository(_empty),
          onStartLearning: () => started = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('progress-empty')), findsOneWidget);
    await tester.tap(find.byKey(const Key('progress-empty-start-button')));
    expect(started, isTrue);
  });

  testWidgets('progress error state retries', (tester) async {
    await tester.pumpWidget(
      _wrap(const StudentProgressScreen(repository: _FailingRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('progress-error')), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('progress renders in Khmer', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StudentProgressScreen(repository: _StubRepository(_populated)),
        locale: const Locale('km'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ការរីកចម្រើនរបស់អ្នក'), findsOneWidget);
    expect(find.text('Your progress'), findsNothing);
  });


  testWidgets(
    'progress fits a 360px phone in Khmer and in the light theme',
    (tester) async {
      // Khmer glyphs are taller and wider than Latin, and this codebase has
      // shipped overflow before. A RenderFlex overflow throws in tests, so
      // pumping at phone width is the assertion.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final theme in [AppTheme.dark(), AppTheme.light()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            locale: const Locale('km'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const StudentProgressScreen(
              repository: _StubRepository(_populated),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
