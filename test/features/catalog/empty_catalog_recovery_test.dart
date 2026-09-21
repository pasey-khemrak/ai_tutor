import 'package:ai_tutor/core/config/app_config.dart';
import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyApiClient extends ApiClient {
  _EmptyApiClient() : super(config: AppConfig.current);

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    return {
      'data': {'lessons': []},
    };
  }
}

class _EmptyLessonsRepository implements StudentLessonsRepository {
  const _EmptyLessonsRepository();
  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  }) async => const [];
}

void main() {
  group('Empty Catalog Recovery', () {
    test('BackendStudentLessonsRepository falls back to Grade 12 STEM lessons when backend is empty', () async {
      final repository = BackendStudentLessonsRepository(apiClient: _EmptyApiClient());
      final lessons = await repository.loadLessons();

      expect(lessons, isNotEmpty);
      expect(lessons.length, greaterThanOrEqualTo(3));

      final subjects = lessons.map((l) => l.subjectId).toSet();
      expect(subjects, contains('math'));
      expect(subjects, contains('physics'));
      expect(subjects, contains('chemistry'));

      for (final lesson in lessons) {
        expect(lesson.grade, 12);
      }
    });

    testWidgets('empty catalog view displays helpful explanation, Ask Tutor button, and starter chips', (tester) async {
      String? askedPrompt;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: StudentLessonsScreen(
              repository: const _EmptyLessonsRepository(),
              onOpenLesson: (_) {},
              onPractice: (_) {},
              onAskTutor: (prompt) => askedPrompt = prompt,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Useful empty state explanation
      expect(find.byKey(const Key('empty-catalog-ask-tutor-button')), findsOneWidget);
      expect(find.byKey(const Key('empty-starter-limits')), findsOneWidget);
      expect(find.byKey(const Key('empty-starter-physics')), findsOneWidget);
      expect(find.byKey(const Key('empty-starter-chemistry')), findsOneWidget);

      // Tapping Ask Tutor
      await tester.tap(find.byKey(const Key('empty-catalog-ask-tutor-button')));
      await tester.pumpAndSettle();
      expect(askedPrompt, isNotNull);

      // Tapping a specific starter chip invokes onAskTutor with that problem
      askedPrompt = null;
      final physicsFinder = find.byKey(const Key('empty-starter-physics'));
      await tester.ensureVisible(physicsFinder);
      await tester.tap(physicsFinder);
      await tester.pumpAndSettle();
      expect(askedPrompt, contains('v = u + at'));
    });
  });
}
