import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_screen.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lessonId = 'math.g12.lesson1.limits-of-functions';
  const curriculumVersionId = 'local-g12-math-limits-2025-10-01-v1';
  const teachingMomentId =
      'math.g12.lesson1.limits-of-functions.finite-at-point.01';

  test(
    'local MVP catalogue exposes only the Grade 12 Limits teaching moment',
    () async {
      final lessons = await const LocalDemoStudentLessonsRepository()
          .loadLessons();

      expect(lessons, hasLength(1));
      final limits = lessons.single;
      expect(demoStudentLessons, contains(limits));
      expect(limits.lessonId, lessonId);
      expect(limits.grade, 12);
      expect(limits.subject, 'Mathematics');
      expect(limits.subjectId, 'math');
      expect(limits.topic, 'Limits of Functions');
      expect(limits.topicId, 'math-g12-limits-of-functions');
      expect(limits.title, 'លីមីតនៃអនុគមន៍');
      expect(limits.displayTitle, 'លីមីតនៃអនុគមន៍');
      expect(limits.curriculumVersionId, curriculumVersionId);
      expect(limits.teachingMomentId, teachingMomentId);
      expect(limits.languageMode, 'khmer');
      expect(limits.isLocalCurriculumDemo, isTrue);
      expect(lessons.where((lesson) => lesson.grade == 10), isEmpty);
    },
  );

  test(
    'Grade 10, Physics, and Chemistry are not available in the local MVP catalogue',
    () async {
      const repository = LocalDemoStudentLessonsRepository();

      expect(await repository.loadLessons(search: 'Grade 10'), isEmpty);
      expect(await repository.loadLessons(search: 'Physics'), isEmpty);
      expect(await repository.loadLessons(search: 'Chemistry'), isEmpty);
    },
  );

  testWidgets(
    'opening Grade 12 Limits exposes the exact selected lesson context',
    (tester) async {
      StudentLesson? startedLesson;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: StudentLessonsScreen(
              repository: const LocalDemoStudentLessonsRepository(),
              onOpenLesson: (lesson) => startedLesson = lesson,
              onPractice: (_) =>
                  fail('Local MVP practice is intentionally unavailable'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('លីមីតនៃអនុគមន៍'), findsOneWidget);
      expect(find.text('Limits of Functions'), findsNothing);
      await tester.tap(find.byKey(const Key('lesson-card-$lessonId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson-start-button')));

      final lesson = startedLesson;
      expect(lesson, isNotNull);
      expect(lesson!.grade, 12);
      expect(lesson.subject, 'Mathematics');
      expect(lesson.topic, 'Limits of Functions');
      expect(lesson.lessonId, lessonId);
      expect(lesson.curriculumVersionId, curriculumVersionId);
      expect(lesson.languageMode, 'khmer');
      expect(lesson.teachingMomentId, teachingMomentId);
    },
  );

  testWidgets(
    'unsupported local selections receive the Khmer-first MVP recovery',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: StudentLessonsScreen(
              repository: const LocalDemoStudentLessonsRepository(),
              onOpenLesson: (_) {},
              onPractice: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('lessons-search-field')),
        'Physics',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text(localMvpUnsupportedRecoveryMessage), findsOneWidget);
    },
  );

  testWidgets(
    'Limits local tutor surface is labelled as a local curriculum demo',
    (tester) async {
      const context = LearningContext(
        grade: 12,
        subject: 'Mathematics',
        topic: 'Limits of Functions',
        gradeLevelId: 'grade-12',
        subjectId: 'math',
        topicId: 'math-g12-limits-of-functions',
        lessonId: lessonId,
        curriculumVersionId: curriculumVersionId,
        teachingMomentId: teachingMomentId,
        languageMode: 'khmer',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: TutorScreen(context: context)),
        ),
      );

      expect(
        find.byKey(const Key('local-curriculum-demo-label')),
        findsOneWidget,
      );
      expect(find.text('Local curriculum demo'), findsOneWidget);
    },
  );
}
