import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    );

class _TestCatalogRepository implements StudentLessonsRepository {
  const _TestCatalogRepository(this.lessons);
  final List<StudentLesson> lessons;

  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  }) async {
    final query = search?.trim().toLowerCase() ?? '';
    return lessons
        .where(
          (lesson) =>
              (subjectId == null || lesson.subjectId == subjectId) &&
              (topicId == null || lesson.topicId == topicId) &&
              (query.isEmpty ||
                  lesson.title.toLowerCase().contains(query) ||
                  (lesson.englishTitle?.toLowerCase().contains(query) ??
                      false) ||
                  lesson.topic.toLowerCase().contains(query) ||
                  (lesson.description?.toLowerCase().contains(query) ??
                      false) ||
                  (lesson.khmerDescription?.toLowerCase().contains(query) ??
                      false)),
        )
        .toList(growable: false);
  }
}

void main() {
  group('Grade 12 STEM Curriculum Catalog', () {
    test('catalog contains 15 Grade 12 lessons across Math, Physics, and Chemistry', () {
      final lessons = publishedGrade12StemFallbackLessons;

      expect(lessons.length, 15);

      final mathLessons = lessons.where((l) => l.subjectId == 'math').toList();
      final physicsLessons = lessons.where((l) => l.subjectId == 'physics').toList();
      final chemLessons = lessons.where((l) => l.subjectId == 'chemistry').toList();

      expect(mathLessons.length, 5);
      expect(physicsLessons.length, 5);
      expect(chemLessons.length, 5);

      for (final lesson in lessons) {
        expect(lesson.grade, 12);
        expect(lesson.gradeLevelId, 'grade-12');
      }
    });

    test('every lesson has non-empty Khmer and English titles and descriptions', () {
      for (final lesson in publishedGrade12StemFallbackLessons) {
        // Khmer content
        expect(lesson.title.trim(), isNotEmpty,
            reason: '${lesson.lessonId} missing Khmer title');
        expect(lesson.khmerDescription?.trim(), isNotEmpty,
            reason: '${lesson.lessonId} missing Khmer description');

        // English content
        expect(lesson.englishTitle?.trim(), isNotEmpty,
            reason: '${lesson.lessonId} missing English title');
        expect(lesson.description?.trim(), isNotEmpty,
            reason: '${lesson.lessonId} missing English description');

        // Bilingual display title contains both
        expect(lesson.displayTitle, contains(lesson.title));
        expect(lesson.displayTitle, contains(lesson.englishTitle!));
      }
    });

    test('authoritative teachable topics are marked available with starter problems', () {
      final availableLessons = publishedGrade12StemFallbackLessons
          .where((l) => l.isAvailable)
          .toList();

      expect(availableLessons.length, 3);

      final availableTopics = availableLessons.map((l) => l.topicId).toSet();
      expect(availableTopics, contains('math-g12-limits-of-functions'));
      expect(availableTopics, contains('physics-g12-kinematics'));
      expect(availableTopics, contains('chemistry-g12-stoichiometry'));

      for (final lesson in availableLessons) {
        expect(lesson.starterProblem, isNotNull);
        expect(lesson.starterProblem!.trim(), isNotEmpty);
      }

      // Limits starter problem
      final limits = availableLessons
          .firstWhere((l) => l.topicId == 'math-g12-limits-of-functions');
      expect(limits.starterProblem, contains('lim'));

      // Kinematics starter problem
      final kinematics =
          availableLessons.firstWhere((l) => l.topicId == 'physics-g12-kinematics');
      expect(kinematics.starterProblem, contains('v = u + at'));

      // Stoichiometry starter problem
      final stoichiometry = availableLessons
          .firstWhere((l) => l.topicId == 'chemistry-g12-stoichiometry');
      expect(stoichiometry.starterProblem, contains('2H_2 + O_2'));

      // The remaining 12 topics are clearly marked not yet available
      final unavailableLessons = publishedGrade12StemFallbackLessons
          .where((l) => !l.isAvailable)
          .toList();
      expect(unavailableLessons.length, 12);
    });

    testWidgets('available lesson displays Available badge and Start with Tutor CTA', (tester) async {
      StudentLesson? openedLesson;
      final repo = _TestCatalogRepository(publishedGrade12StemFallbackLessons);

      await tester.pumpWidget(
        _wrap(
          StudentLessonsScreen(
            repository: repo,
            onOpenLesson: (lesson) => openedLesson = lesson,
            onPractice: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card shows Ready badge
      expect(find.text('Ready'), findsWidgets);

      // Open Limits lesson
      final limitsCard = find.byKey(
        const Key('lesson-card-math.g12.lesson1.limits-of-functions'),
      );
      expect(limitsCard, findsOneWidget);
      await tester.tap(limitsCard);
      await tester.pumpAndSettle();

      // Detail view shows both Khmer and English descriptions
      expect(find.text('លីមីតនៃអនុគមន៍ — Limits of Functions'), findsOneWidget);
      expect(find.textContaining('គណនាលីមីតកំណត់'), findsOneWidget);
      expect(find.textContaining('Calculate finite limits'), findsOneWidget);

      // Detail shows start button
      final startButton = find.byKey(const Key('lesson-start-button'));
      expect(startButton, findsOneWidget);

      await tester.tap(startButton);
      expect(openedLesson, isNotNull);
      expect(openedLesson!.isAvailable, isTrue);
      expect(openedLesson!.starterProblem, contains('lim'));
    });

    testWidgets('unavailable lesson displays Coming Soon badge and Ask Tutor CTA without dead end', (tester) async {
      String? askedPrompt;
      final repo = _TestCatalogRepository(publishedGrade12StemFallbackLessons);

      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrap(
          StudentLessonsScreen(
            repository: repo,
            onOpenLesson: (_) {},
            onPractice: (_) {},
            onAskTutor: (prompt) => askedPrompt = prompt,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card shows Coming Soon badge
      expect(find.text('Coming Soon'), findsWidgets);

      // Open Derivatives lesson (marked unavailable)
      final derivativesCard = find.byKey(
        const Key('lesson-card-math.g12.lesson2.derivatives'),
      );
      expect(derivativesCard, findsOneWidget);
      await tester.ensureVisible(derivativesCard);
      await tester.tap(derivativesCard);
      await tester.pumpAndSettle();

      // Detail shows Coming Soon explanation banner
      expect(find.text('Lesson Under Preparation'), findsOneWidget);
      expect(
        find.textContaining('Lessons and exercises for this topic are being prepared'),
        findsOneWidget,
      );

      // Start button is replaced with Ask Tutor About This Topic CTA (not a dead end)
      expect(find.byKey(const Key('lesson-start-button')), findsNothing);
      final askTutorButton = find.byKey(const Key('lesson-ask-tutor-button'));
      expect(askTutorButton, findsOneWidget);

      // Tapping Ask Tutor routes topic to live tutor
      await tester.tap(askTutorButton);
      expect(askedPrompt, 'Derivatives of Functions');
    });

    testWidgets('filtering by subject isolates Mathematics, Physics, Chemistry', (tester) async {
      final repo = _TestCatalogRepository(publishedGrade12StemFallbackLessons);

      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrap(
          StudentLessonsScreen(
            repository: repo,
            onOpenLesson: (_) {},
            onPractice: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Physics chip
      await tester.tap(find.text('Physics'));
      await tester.pumpAndSettle();

      // Physics lesson is shown, Math is hidden
      expect(find.byKey(const Key('lesson-card-physics.g12.lesson1.kinematics')), findsOneWidget);
      expect(find.byKey(const Key('lesson-card-math.g12.lesson1.limits-of-functions')), findsNothing);

      // Tap Chemistry chip
      await tester.tap(find.text('Chemistry'));
      await tester.pumpAndSettle();

      // Chemistry lesson is shown, Physics is hidden
      expect(find.byKey(const Key('lesson-card-chemistry.g12.lesson1.stoichiometry')), findsOneWidget);
      expect(find.byKey(const Key('lesson-card-physics.g12.lesson1.kinematics')), findsNothing);
    });

    testWidgets('search works in both Khmer and English', (tester) async {
      final repo = _TestCatalogRepository(publishedGrade12StemFallbackLessons);

      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrap(
          StudentLessonsScreen(
            repository: repo,
            onOpenLesson: (_) {},
            onPractice: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search with English term
      await tester.enterText(
        find.byKey(const Key('lessons-search-field')),
        'Kinematics',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lesson-card-physics.g12.lesson1.kinematics')), findsOneWidget);
      expect(find.byKey(const Key('lesson-card-math.g12.lesson1.limits-of-functions')), findsNothing);

      // Search with Khmer term
      await tester.enterText(
        find.byKey(const Key('lessons-search-field')),
        'លីមីត',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lesson-card-math.g12.lesson1.limits-of-functions')), findsOneWidget);
      expect(find.byKey(const Key('lesson-card-physics.g12.lesson1.kinematics')), findsNothing);
    });
  });
}
