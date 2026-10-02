import 'package:ai_tutor/app/tutor_shell.dart';
import 'package:ai_tutor/core/config/app_config.dart';
import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/board_element_renderer.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    );

class _MockDynamicCatalogApiClient extends ApiClient {
  _MockDynamicCatalogApiClient() : super(config: AppConfig.current);

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    // Mock the Gateway GET /curriculum/catalog endpoint
    if (path.contains('/curriculum/catalog')) {
      final gradeFilter = queryParameters?['grade'];
      final subjectFilter = queryParameters?['subject_id'];
      final allTopics = [
        {
          'lesson_id': 'chem.g12.lesson.acids-bases',
          'curriculum_version_id': 'curric-ver-v2-chem',
          'grade_level_id': 'grade-12',
          'grade': 12,
          'subject_id': 'chemistry',
          'subject_name': 'Chemistry',
          'topic_id': 'chemistry-g12-acids-bases',
          'topic_name': 'Acids and Bases',
          'title': 'អាស៊ីត និងបាស',
          'english_title': 'Acids and Bases',
          'description': 'Calculate pH, pOH, and titration curves.',
          'khmer_description': 'គណនា pH, pOH និងខ្សែបន្ទាត់ទីត្រាត។',
          'starter_problem': r'pH = -\log[H_3O^+]',
          'difficulty': 'intermediate',
          'is_available': true,
          'tags': ['#AcidsBases', '#pH', '#Titration'],
          'problem_count': 5,
        },
        {
          'lesson_id': 'phys.g11.lesson.snells-law',
          'curriculum_version_id': 'curric-ver-v2-phys',
          'grade_level_id': 'grade-11',
          'grade': 11,
          'subject_id': 'physics',
          'subject_name': 'Physics',
          'topic_id': 'physics-g11-optics-snells-law',
          'topic_name': "Geometrical Optics & Snell's Law",
          'title': 'អុបទិចធរណីមាត្រ និងច្បាប់ដេកាត (Snell)',
          'english_title': "Geometrical Optics & Snell's Law",
          'description': "Calculate refraction angles using Snell's Law.",
          'khmer_description': 'គណនាមុំកំណកតាមច្បាប់ដេកាត។',
          'starter_problem': r'n_1 \sin(\theta_1) = n_2 \sin(\theta_2)',
          'difficulty': 'intermediate',
          'is_available': true,
          'tags': ['#Optics', "#Snell's Law", '#Refraction'],
          'problem_count': 6,
        },
        {
          'lesson_id': 'math.g10.lesson.linear-systems',
          'curriculum_version_id': 'curric-ver-v2-math',
          'grade_level_id': 'grade-10',
          'grade': 10,
          'subject_id': 'math',
          'subject_name': 'Mathematics',
          'topic_id': 'math-g10-linear-systems',
          'topic_name': 'Systems of Linear Equations',
          'title': 'ប្រព័ន្ធសមីការលីនេអ៊ែរ',
          'english_title': 'Systems of Linear Equations',
          'description': 'Solve linear equations with substitution and elimination.',
          'khmer_description': 'ដោះស្រាយប្រព័ន្ធសមីការលីនេអ៊ែរ។',
          'starter_problem': r'2x + y = 7',
          'difficulty': 'beginner',
          'is_available': true,
          'tags': ['#LinearSystems', '#Algebra'],
          'problem_count': 4,
        },
      ];

      final filtered = allTopics.where((t) {
        if (gradeFilter != null && t['grade'].toString() != gradeFilter) {
          return false;
        }
        if (subjectFilter != null && t['subject_id'] != subjectFilter) {
          return false;
        }
        return true;
      }).toList();

      return {
        'success': true,
        'data': {
          'topics': filtered,
          'total': filtered.length,
        },
      };
    }

    return {'data': {'lessons': []}};
  }
}

void main() {
  group('Dynamic Curriculum Catalog', () {
    test('BackendStudentLessonsRepository retrieves dynamic catalog across Grades 10-12', () async {
      final repo = BackendStudentLessonsRepository(apiClient: _MockDynamicCatalogApiClient());
      final allLessons = await repo.loadLessons();

      expect(allLessons.length, 3);

      final grades = allLessons.map((l) => l.grade).toSet();
      expect(grades, containsAll([10, 11, 12]));

      final subjects = allLessons.map((l) => l.subjectId).toSet();
      expect(subjects, containsAll(['math', 'physics', 'chemistry']));

      final acidsBases = allLessons.firstWhere((l) => l.lessonId == 'chem.g12.lesson.acids-bases');
      expect(acidsBases.tags, containsAll(['#AcidsBases', '#pH', '#Titration']));
      expect(acidsBases.difficulty, 'intermediate');
      expect(acidsBases.problemCount, 5);
      expect(acidsBases.starterProblem, contains('pH = -'));
    });

    test('BackendStudentLessonsRepository filters by grade', () async {
      final repo = BackendStudentLessonsRepository(apiClient: _MockDynamicCatalogApiClient());

      final g10 = await repo.loadLessons(grade: 10);
      expect(g10.length, 1);
      expect(g10.first.grade, 10);
      expect(g10.first.subjectId, 'math');

      final g11 = await repo.loadLessons(grade: 11);
      expect(g11.length, 1);
      expect(g11.first.grade, 11);
      expect(g11.first.subjectId, 'physics');

      final g12 = await repo.loadLessons(grade: 12);
      expect(g12.length, 1);
      expect(g12.first.grade, 12);
      expect(g12.first.subjectId, 'chemistry');
    });

    testWidgets('StudentLessonsScreen displays Grade chips, curriculum tags, difficulty, and problem count', (tester) async {
      final repo = BackendStudentLessonsRepository(apiClient: _MockDynamicCatalogApiClient());

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

      // Grade selector chips are visible
      expect(find.byKey(const Key('filter-grade-all')), findsOneWidget);
      expect(find.byKey(const Key('filter-grade-10')), findsOneWidget);
      expect(find.byKey(const Key('filter-grade-11')), findsOneWidget);
      expect(find.byKey(const Key('filter-grade-12')), findsOneWidget);

      // Verify topic cards render difficulty chips
      expect(find.text('Intermediate'), findsWidgets);
      expect(find.text('Beginner'), findsWidgets);

      // Verify problem count chips render
      expect(find.text('5 problems'), findsOneWidget);
      expect(find.text('6 problems'), findsOneWidget);
      expect(find.text('4 problems'), findsOneWidget);

      // Verify curriculum tags render on the card
      expect(find.text('#AcidsBases'), findsOneWidget);
      expect(find.text('#pH'), findsOneWidget);
    });

    testWidgets('Tapping topic card preloads topic metadata via learningContextForLesson', (tester) async {
      final repo = BackendStudentLessonsRepository(apiClient: _MockDynamicCatalogApiClient());
      StudentLesson? openedLesson;

      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      // Tap the Acids and Bases lesson card
      final acidsBasesCard = find.byKey(const Key('lesson-card-chem.g12.lesson.acids-bases'));
      expect(acidsBasesCard, findsOneWidget);
      await tester.tap(acidsBasesCard);
      await tester.pumpAndSettle();

      // Detail view shows full tags, difficulty, problem count
      expect(find.text('#Titration'), findsOneWidget);
      expect(find.text('5 problems'), findsOneWidget);

      // Tap Start with Tutor
      final startButton = find.byKey(const Key('lesson-start-button'));
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(openedLesson, isNotNull);
      expect(openedLesson!.topicId, 'chemistry-g12-acids-bases');
      expect(openedLesson!.starterProblem, contains('pH = -'));

      // Validate learningContextForLesson extracts correct metadata
      final context = learningContextForLesson(openedLesson!);
      expect(context.grade, 12);
      expect(context.subject, 'Chemistry');
      expect(context.topic, 'Acids and Bases');
      expect(context.topicId, 'chemistry-g12-acids-bases');
      expect(context.lessonId, 'chem.g12.lesson.acids-bases');
      expect(context.curriculumVersionId, 'curric-ver-v2-chem');
    });

    testWidgets('Grade selector filters lessons dynamically', (tester) async {
      final repo = BackendStudentLessonsRepository(apiClient: _MockDynamicCatalogApiClient());

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

      // Tap Grade 11
      await tester.tap(find.byKey(const Key('filter-grade-11')));
      await tester.pumpAndSettle();

      // Only Grade 11 Physics (Snell's Law) is displayed
      expect(find.byKey(const Key('lesson-card-phys.g11.lesson.snells-law')), findsOneWidget);
      expect(find.byKey(const Key('lesson-card-chem.g12.lesson.acids-bases')), findsNothing);
      expect(find.byKey(const Key('lesson-card-math.g10.lesson.linear-systems')), findsNothing);

      // Tap Grade 10
      await tester.tap(find.byKey(const Key('filter-grade-10')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lesson-card-math.g10.lesson.linear-systems')), findsOneWidget);
      expect(find.byKey(const Key('lesson-card-phys.g11.lesson.snells-law')), findsNothing);
    });
  });

  group('KaTeX Formula Preprocessing & Multi-Subject Equations', () {
    test('cleans accidental outer delimiters', () {
      expect(preprocessLatexEquation(r'$$2H_2 + O_2 \to 2H_2O$$'), r'2H_2 + O_2 \to 2H_2O');
      expect(preprocessLatexEquation(r'$v = u + at$'), 'v = u + at');
      expect(preprocessLatexEquation(r'\[\lim_{x \to 3} f(x)\]'), r'\lim_{x \to 3} f(x)');
      expect(preprocessLatexEquation(r'\(PV = nRT\)'), 'PV = nRT');
    });

    test('replaces chemical reaction arrows with standard KaTeX symbols', () {
      // Reversible reactions
      expect(preprocessLatexEquation('N_2 + 3H_2 <=> 2NH_3'), r'N_2 + 3H_2 \rightleftharpoons 2NH_3');
      expect(preprocessLatexEquation('HA + H_2O <-> H_3O^+ + A^-'), r'HA + H_2O \rightleftharpoons H_3O^+ + A^-');

      // Forward reactions
      expect(preprocessLatexEquation('2H_2 + O_2 -> 2H_2O'), r'2H_2 + O_2 \rightarrow  2H_2O');
      expect(preprocessLatexEquation('CH_4 + 2O_2 --> CO_2 + 2H_2O'), r'CH_4 + 2O_2 \rightarrow CO_2 + 2H_2O');
    });

    test('normalizes physics vectors and unit vectors', () {
      expect(preprocessLatexEquation(r'\vec v = \vec u + \vec a t'), r'\vec{v} = \vec{u} + \vec{a} t');
      expect(preprocessLatexEquation(r'\vec F = m \vec a'), r'\vec{F} = m \vec{a}');
      expect(preprocessLatexEquation(r'\vec r = 3\hat i + 4\hat j'), r'\vec{r} = 3\hat{i} + 4\hat{j}');
    });

    testWidgets('BoardElementRenderer renders chemistry equations and physics vectors cleanly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoardPaperScaffold(
            child: Stack(
              children: [
                BoardElementRenderer(
                  action: const VisualTutorBoardActionEntity(
                    id: 'test-chem-eq-1',
                    type: 'write_equation',
                    latex: r'2H_2 + O_2 -> 2H_2O',
                    style: {'ink': 'blue'},
                    metadata: {},
                    x: 20,
                    y: 40,
                    width: 300,
                    height: 50,
                  ),
                ),
                BoardElementRenderer(
                  action: const VisualTutorBoardActionEntity(
                    id: 'test-phys-vec-1',
                    type: 'write_equation',
                    latex: r'\vec v = \hat i + 2\hat j',
                    style: {'ink': 'green'},
                    metadata: {},
                    x: 20,
                    y: 100,
                    width: 300,
                    height: 50,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify equations rendered without exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
