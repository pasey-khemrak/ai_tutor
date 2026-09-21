import 'dart:convert';

import 'package:ai_tutor/core/config/app_config.dart';
import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _linearLesson = StudentLesson(
  lessonId: 'lesson-linear',
  curriculumVersionId: 'version-10-math',
  gradeLevelId: 'grade-10',
  grade: 10,
  subjectId: 'math',
  subject: 'Mathematics',
  topicId: 'linear-equations',
  topic: 'Linear Equations',
  title: 'Solving linear equations',
  description: 'Use inverse operations one step at a time.',
  difficulty: 'beginner',
);

class _LessonsRepository implements StudentLessonsRepository {
  _LessonsRepository(this.lessons);

  final List<StudentLesson> lessons;
  final List<({String? search, String? subjectId, String? topicId, int? grade})> calls = [];

  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  }) async {
    calls.add((search: search, subjectId: subjectId, topicId: topicId, grade: grade));
    return lessons
        .where(
          (lesson) =>
              (grade == null || lesson.grade == grade) &&
              (subjectId == null || lesson.subjectId == subjectId) &&
              (topicId == null || lesson.topicId == topicId) &&
              (search == null ||
                  search.isEmpty ||
                  lesson.title.toLowerCase().contains(search.toLowerCase()) ||
                  lesson.topic.toLowerCase().contains(search.toLowerCase())),
        )
        .toList();
  }
}

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  test(
    'published lesson repository sends filters and discards invalid grade rows',
    () async {
      final client = ApiClient(
        config: const AppConfig(
          environment: AppEnvironment.production,
          backendBaseUrl: 'http://localhost:4000/api/v1',
          aiServiceBaseUrl: 'http://localhost:8001/api/v1',
          useDemoAuth: false,
          useDemoTutorData: false,
        ),
        tokenProvider: () async => 'student-token',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/catalog/published-lessons');
          expect(request.url.queryParameters, {
            'search': 'linear',
            'subject_id': 'math',
            'topic_id': 'linear-equations',
          });
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'lessons': [
                  {
                    'lesson_id': 'lesson-10',
                    'curriculum_version_id': 'version-10',
                    'grade_level_id': 'grade-10',
                    'grade_number': 10,
                    'subject_id': 'math',
                    'subject_name': 'Mathematics',
                    'topic_id': 'linear-equations',
                    'topic_name': 'Linear Equations',
                    'title': 'Solving Linear Equations',
                    'difficulty': 'beginner',
                  },
                  {
                    'lesson_id': 'grade-nine-must-not-render',
                    'curriculum_version_id': 'version-9',
                    'grade_level_id': 'grade-9',
                    'grade_number': 9,
                    'subject_id': 'math',
                    'subject_name': 'Mathematics',
                    'topic_id': 'linear-equations',
                    'topic_name': 'Linear Equations',
                    'title': 'Unsupported lesson',
                    'difficulty': 'beginner',
                  },
                  {
                    'lesson_id': 'missing-version-must-not-render',
                    'curriculum_version_id': '',
                    'grade_number': 10,
                  },
                ],
              },
            }),
            200,
          );
        }),
      );

      final lessons = await BackendStudentLessonsRepository(apiClient: client)
          .loadLessons(
            search: 'linear',
            subjectId: 'math',
            topicId: 'linear-equations',
          );

      expect(lessons.map((lesson) => lesson.lessonId), ['lesson-10']);
      client.close();
    },
  );

  testWidgets(
    'student can open a published lesson and start the exact lesson',
    (tester) async {
      StudentLesson? opened;
      final repository = _LessonsRepository([_linearLesson]);

      await tester.pumpWidget(
        _wrap(
          StudentLessonsScreen(
            repository: repository,
            onOpenLesson: (lesson) => opened = lesson,
            onPractice: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lesson-card-lesson-linear')));
      await tester.pumpAndSettle();
      expect(find.text('Solving linear equations'), findsOneWidget);
      expect(find.text('Topic: Linear Equations'), findsOneWidget);

      await tester.tap(find.byKey(const Key('lesson-start-button')));
      expect(opened, _linearLesson);
    },
  );

  testWidgets('search and subject filter reload published lessons only', (
    tester,
  ) async {
    final physics = StudentLesson(
      lessonId: 'lesson-physics',
      curriculumVersionId: 'version-10-physics',
      gradeLevelId: 'grade-10',
      grade: 10,
      subjectId: 'physics',
      subject: 'Physics',
      topicId: 'motion',
      topic: 'Motion',
      title: 'Motion basics',
      difficulty: 'beginner',
    );
    final repository = _LessonsRepository([_linearLesson, physics]);

    await tester.pumpWidget(
      _wrap(
        StudentLessonsScreen(
          repository: repository,
          onOpenLesson: (_) {},
          onPractice: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mathematics'));
    await tester.pumpAndSettle();
    expect(repository.calls.last.subjectId, 'math');
    expect(find.text('Solving linear equations'), findsOneWidget);
    expect(find.text('Motion basics'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('lessons-search-field')),
      'linear',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Solving linear equations'), findsOneWidget);
    expect(repository.calls.last.subjectId, 'math');
    expect(repository.calls.last.search, 'linear');
  });
}
