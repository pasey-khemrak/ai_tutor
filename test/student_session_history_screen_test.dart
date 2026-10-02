import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_repository.dart';
import 'package:ai_tutor/screens/history/student_session_history_screen.dart';
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

const _withSessions = StudentDashboardData(
  studentName: 'Dara',
  gradeLabel: 'Grade 11',
  subjects: ['Mathematics'],
  learningStreakDays: 2,
  recentActivity: [
    DashboardActivity(
      title: 'Solved a linear equation',
      subtitle: '2x + 5 = 15',
      timeLabel: 'Today',
      topicId: 'linear-equations',
      tutorSessionId: 'session-1',
    ),
    DashboardActivity(
      title: 'Worked on kinematics',
      subtitle: 'v = u + at',
      timeLabel: 'Yesterday',
      topicId: 'kinematics',
      tutorSessionId: 'session-2',
    ),
    // A quiz entry carries no session, so it cannot be reopened as a board.
    DashboardActivity(
      title: 'Finished a quiz',
      subtitle: 'Scored 80%',
      timeLabel: 'Today',
      topicId: 'linear-equations',
    ),
  ],
  subjectProgress: [],
  weakTopic: null,
  resumeTitle: 'Linear Equations',
  resumeSubtitle: 'Continue',
);

const _noSessions = StudentDashboardData(
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
  testWidgets('history lists only sessions that can be reopened', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const StudentSessionHistoryScreen(
          repository: _StubRepository(_withSessions),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-session-session-1')), findsOneWidget);
    expect(find.byKey(const Key('history-session-session-2')), findsOneWidget);
    expect(find.text('Finished a quiz'), findsNothing);
  });

  testWidgets('tapping a session reopens it', (tester) async {
    String? reopened;
    await tester.pumpWidget(
      _wrap(
        StudentSessionHistoryScreen(
          repository: const _StubRepository(_withSessions),
          onOpenSession: (session) => reopened = session.tutorSessionId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('history-session-session-2')));
    expect(reopened, 'session-2');
  });

  testWidgets('history empty state routes into the tutor', (tester) async {
    var started = false;
    await tester.pumpWidget(
      _wrap(
        StudentSessionHistoryScreen(
          repository: const _StubRepository(_noSessions),
          onStartLearning: () => started = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-empty')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-empty-start-button')));
    expect(started, isTrue);
  });

  testWidgets('history error state retries', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StudentSessionHistoryScreen(repository: _FailingRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-error')), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('history localizes its dates in Khmer', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StudentSessionHistoryScreen(
          repository: _StubRepository(_withSessions),
        ),
        locale: const Locale('km'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ថ្ងៃនេះ'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.text('ប្រវត្តិមេរៀន'), findsOneWidget);
  });


  testWidgets('history fits a 360px phone in Khmer and in the light theme', (
    tester,
  ) async {
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
          home: const StudentSessionHistoryScreen(
            repository: _StubRepository(_withSessions),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
