import 'dart:convert';

import 'package:ai_tutor/core/config/app_config.dart';
import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_repository.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class TestDashboardRepository implements DashboardRepository {
  const TestDashboardRepository(this.data);

  final StudentDashboardData? data;

  @override
  Future<StudentDashboardData?> loadDashboard() async => data;
}

const _dashboardFixture = StudentDashboardData(
  studentName: 'Khemrak',
  gradeLabel: 'Grade 10',
  subjects: ['Mathematics'],
  learningStreakDays: 4,
  resumeTitle: 'Linear Equations',
  resumeSubtitle: 'Continue your guided tutor session',
  recentActivity: [
    DashboardActivity(title: 'Solved a linear equation', subtitle: '2x + 5 = 15', timeLabel: 'Today'),
  ],
  subjectProgress: [
    SubjectProgress(subject: 'Mathematics', topic: 'Linear Equations', progress: .72),
  ],
  weakTopic: WeakTopic(
    title: 'Slope from two points',
    reason: 'Needs more practice with rise over run.',
    actionLabel: 'Practice now',
  ),
);

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('dashboard renders with data', (tester) async {
    await tester.pumpWidget(
      wrap(
        DashboardScreen(
          repository: const TestDashboardRepository(_dashboardFixture),
          onResumeLearning: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome back, Khemrak'), findsOneWidget);
    expect(find.text('Grade 10'), findsOneWidget);
    expect(find.text('Mathematics'), findsWidgets);
    expect(find.text('4 days'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Subject progress'), findsOneWidget);
    expect(find.text('Slope from two points'), findsOneWidget);
  });

  testWidgets('dashboard loads backend progress summary data', (tester) async {
    final client = ApiClient(
      config: const AppConfig(
        environment: AppEnvironment.production,
        backendBaseUrl: 'http://localhost:4000/api/v1',
        aiServiceBaseUrl: 'http://localhost:8001/api/v1',
        useDemoAuth: false,
        useDemoTutorData: false,
      ),
      tokenProvider: () async => 'token',
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:4000/api/v1/progress/dashboard',
        );
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Dashboard summary retrieved successfully',
            'data': {
              'user_id': 'student-1',
              'learner': {
                'display_name': 'Dara',
                'grade_label': 'Grade 11',
                'subjects': [
                  {'subject_id': 'physics', 'subject_name': 'Physics'},
                  {'subject_id': 'english', 'subject_name': 'English'},
                ],
                'learning_goal': 'Prepare for exams',
              },
              'total_sessions': 2,
              'lessons_completed': 1,
              'quiz_attempts': 1,
              'average_quiz_score': 80,
              'correct_answers': 3,
              'incorrect_answers': 1,
              'current_streak': 5,
              'weak_topic': {
                'topic_id': 'slope',
                'confidence': 'low',
                'reason': '1/3 recent answers were correct.',
              },
              'recent_activity': [
                {
                  'id': 'event-1',
                  'event_type': 'tutor_session_summary',
                  'topic_id': 'linear-equations',
                  'title': 'Started tutor session',
                  'created_at': DateTime.now().toIso8601String(),
                },
              ],
              'resume_lesson': {
                'tutor_session_id': 'session-42',
                'subject_id': 'physics',
                'topic_id': 'slope',
                'status': 'active',
                'board_version': 4,
              },
              'empty_state': false,
            },
          }),
          200,
        );
      }),
    );

    await tester.pumpWidget(
      wrap(
        DashboardScreen(
          repository: BackendDashboardRepository(apiClient: client),
          onResumeLearning: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Dara'), findsOneWidget);
    expect(find.text('Grade 11'), findsOneWidget);
    expect(find.text('Physics, English'), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
    expect(find.text('Linear Equations'), findsWidgets);
    expect(find.text('Slope'), findsWidgets);
    expect(find.text('Started tutor session'), findsOneWidget);
    client.close();
  });

  testWidgets('dashboard renders empty state', (tester) async {
    await tester.pumpWidget(
      wrap(
        DashboardScreen(
          repository: const TestDashboardRepository(null),
          onResumeLearning: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No learning activity yet'), findsOneWidget);
    expect(
      find.text('Start a tutor session to see your progress here.'),
      findsOneWidget,
    );
  });

  testWidgets('resume learning without a persisted session opens tutor home', (
    tester,
  ) async {
    var resumed = false;
    await tester.pumpWidget(
      wrap(
        DashboardScreen(
          repository: const TestDashboardRepository(_dashboardFixture),
          onResumeLearning: () => resumed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Khemrak'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard-resume-learning-button')));
    await tester.pumpAndSettle();

    expect(resumed, isTrue);
  });

  testWidgets('dashboard API error is shown with retry', (tester) async {
    await tester.pumpWidget(
      wrap(
        DashboardScreen(
          repository: const ErrorDashboardRepository(),
          onResumeLearning: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load your dashboard.'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
