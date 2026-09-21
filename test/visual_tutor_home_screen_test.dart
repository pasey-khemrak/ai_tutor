import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/tutor/visual_tutor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements StudentLessonsRepository {
  const _Repo(this.lessons, {this.fail = false});
  final List<StudentLesson> lessons;
  final bool fail;

  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  }) async {
    if (fail) throw StateError('catalogue down');
    return lessons;
  }
}

StudentLesson _lesson(
  String id,
  String subjectId,
  String subject,
  String title, {
  int grade = 12,
  bool available = true,
  String? starter,
}) => StudentLesson(
  lessonId: id,
  curriculumVersionId: 'v1',
  gradeLevelId: 'grade-$grade',
  grade: grade,
  subjectId: subjectId,
  subject: subject,
  topicId: id,
  topic: title,
  title: title,
  difficulty: 'beginner',
  isAvailable: available,
  starterProblem: starter,
);

final _catalogue = [
  _lesson('limits', 'math', 'Mathematics', 'Limits of Functions',
      starter: 'Find the limit of (x^2-4)/(x-2) as x approaches 2'),
  _lesson('kinematics', 'physics', 'Physics', 'Kinematics'),
  _lesson('stoichiometry', 'chemistry', 'Chemistry', 'Stoichiometry', available: false),
  _lesson('quadratics', 'math', 'Mathematics', 'Quadratic Functions', grade: 11),
];

void main() {
  Widget buildScreen({
    List<StudentLesson>? lessons,
    bool fail = false,
    ValueChanged<StudentLesson>? onOpenLesson,
    ValueChanged<String?>? onAskQuestion,
    Locale? locale,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: VisualTutorHomeScreen(
          repository: _Repo(lessons ?? _catalogue, fail: fail),
          onOpenLesson: onOpenLesson ?? (_) {},
          onAskQuestion: onAskQuestion ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('tutor home shows the curriculum grouped by subject', (tester) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('visual-tutor-home-screen')), findsOneWidget);
    expect(find.text('Curriculum'), findsOneWidget);
    expect(find.text('Limits of Functions'), findsOneWidget);
    expect(find.text('Kinematics'), findsOneWidget);
    expect(find.text('Stoichiometry'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);
    // The duplicated Home entry points are gone from this tab.
    expect(find.byKey(const Key('type-question-card')), findsNothing);
    expect(find.byKey(const Key('voice-input-card')), findsNothing);
    expect(find.byKey(const Key('visual-tutor-stuck-card')), findsNothing);
  });

  testWidgets('grade, subject and search filters narrow the topics', (tester) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('curriculum-grade-11')));
    await tester.pumpAndSettle();
    expect(find.text('Quadratic Functions'), findsOneWidget);
    expect(find.text('Limits of Functions'), findsNothing);

    await tester.tap(find.byKey(const Key('curriculum-grade-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('curriculum-subject-physics')));
    await tester.pumpAndSettle();
    expect(find.text('Kinematics'), findsOneWidget);
    expect(find.text('Limits of Functions'), findsNothing);

    await tester.tap(find.byKey(const Key('curriculum-subject-all')));
    await tester.enterText(find.byKey(const Key('curriculum-search-field')), 'stoich');
    await tester.pumpAndSettle();
    expect(find.text('Stoichiometry'), findsOneWidget);
    expect(find.text('Kinematics'), findsNothing);

    await tester.enterText(find.byKey(const Key('curriculum-search-field')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No topics match your search.'), findsOneWidget);
  });

  testWidgets('topics open the tutor and missing topics can be asked directly', (tester) async {
    StudentLesson? opened;
    var asked = false;
    await tester.pumpWidget(
      buildScreen(
        onOpenLesson: (lesson) => opened = lesson,
        onAskQuestion: (problem) => asked = problem == null,
      ),
    );
    await tester.pumpAndSettle();

    final topic = find.byKey(const Key('curriculum-topic-limits'));
    await tester.ensureVisible(topic);
    await tester.tap(topic);
    expect(opened?.lessonId, 'limits');

    final ask = find.byKey(const Key('curriculum-ask-own-button'));
    await tester.ensureVisible(ask);
    await tester.tap(ask);
    expect(asked, isTrue);
  });

  testWidgets('a catalogue failure offers retry and still allows asking', (tester) async {
    var asked = false;
    await tester.pumpWidget(buildScreen(fail: true, onAskQuestion: (_) => asked = true));
    await tester.pumpAndSettle();

    expect(find.text('Could not load the curriculum.'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byKey(const Key('curriculum-ask-own-button')));
    expect(asked, isTrue);
  });

  testWidgets('tutor home has no phone overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('curriculum-search-field')), findsOneWidget);
  });

  testWidgets('tutor home renders in Khmer', (tester) async {
    await tester.pumpWidget(buildScreen(locale: const Locale('km')));
    await tester.pumpAndSettle();

    expect(find.text('កម្មវិធីសិក្សា'), findsOneWidget);
    expect(find.text('គណិតវិទ្យា'), findsWidgets);
    expect(find.text('Curriculum'), findsNothing);
    expect(find.text('Coming Soon'), findsNothing);
  });
}
