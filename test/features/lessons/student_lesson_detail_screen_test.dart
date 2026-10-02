import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/lessons/student_lesson_detail_screen.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _mockLesson = StudentLesson(
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

class _MockStudentLessonsRepository implements StudentLessonsRepository {
  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  }) async {
    return [_mockLesson];
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
      learningObjectives: ['Evaluate finite limits', 'Resolve 0/0 indeterminate forms'],
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

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders header, tabs, and displays concepts & formulas on Tab 1', (
    tester,
  ) async {
    final repo = _MockStudentLessonsRepository();

    await tester.pumpWidget(
      _wrap(
        StudentLessonDetailScreen(
          lesson: _mockLesson,
          onBack: () {},
          onWatchOnWhiteboard: (_) {},
          onPractice: (_) {},
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.textContaining('Mathematics'), findsWidgets);
    expect(find.textContaining('Limits of Functions'), findsWidgets);
    expect(find.textContaining('Grade 12'), findsWidgets);

    // Verify Three Tabs
    expect(find.byKey(const Key('tab-concepts')), findsOneWidget);
    expect(find.byKey(const Key('tab-examples')), findsOneWidget);
    expect(find.byKey(const Key('tab-practice')), findsOneWidget);

    // Verify Tab 1 content
    expect(find.text('Direct Substitution'), findsOneWidget);
    expect(find.textContaining('If f is continuous'), findsOneWidget);
    expect(find.text('Indeterminate Form 0/0'), findsOneWidget);
    expect(find.textContaining('Assuming 0/0 is 1 or 0'), findsOneWidget);
  });

  testWidgets('navigates to Tab 2 and clicking Watch on Whiteboard triggers callback', (
    tester,
  ) async {
    final repo = _MockStudentLessonsRepository();
    String? watchedProblem;

    await tester.pumpWidget(
      _wrap(
        StudentLessonDetailScreen(
          lesson: _mockLesson,
          onBack: () {},
          onWatchOnWhiteboard: (problem) => watchedProblem = problem,
          onPractice: (_) {},
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Tab 2
    await tester.tap(find.byKey(const Key('tab-examples')), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Worked Example content
    expect(find.textContaining('Factor numerator'), findsOneWidget);
    expect(find.textContaining('Cancel common factor'), findsOneWidget);

    // Tap Watch on Whiteboard button
    final watchButton = find.byKey(const Key('lesson-watch-whiteboard-button'));
    expect(watchButton, findsOneWidget);
    await tester.ensureVisible(watchButton);
    await tester.tap(watchButton);
    await tester.pumpAndSettle();

    expect(watchedProblem, r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}');
  });

  testWidgets('navigates to Tab 3 and clicking Practice triggers callback', (
    tester,
  ) async {
    final repo = _MockStudentLessonsRepository();
    StudentLesson? practicedLesson;

    await tester.pumpWidget(
      _wrap(
        StudentLessonDetailScreen(
          lesson: _mockLesson,
          onBack: () {},
          onWatchOnWhiteboard: (_) {},
          onPractice: (lesson) => practicedLesson = lesson,
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Tab 3
    await tester.tap(find.byKey(const Key('tab-practice')), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tap Start Practice button
    final practiceButton = find.byKey(const Key('lesson-practice-button'));
    expect(practiceButton, findsOneWidget);
    await tester.ensureVisible(practiceButton);
    await tester.tap(practiceButton);
    await tester.pumpAndSettle();

    expect(practicedLesson, _mockLesson);
  });
}
