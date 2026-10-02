import 'package:ai_tutor/core/localization/app_language_controller.dart';
import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_repository.dart';
import 'package:ai_tutor/screens/profile/student_profile_repository.dart';
import 'package:ai_tutor/screens/profile/student_profile_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Profiles extends StudentProfileRepository {
  _Profiles(this.view);
  final StudentProfileView view;
  @override
  Future<StudentProfileView> loadProfile() async => view;
}

class _Stats implements DashboardRepository {
  const _Stats({this.fail = false});
  final bool fail;
  @override
  Future<StudentDashboardData?> loadDashboard() async {
    if (fail) throw StateError('offline');
    return const StudentDashboardData(
      studentName: 'Sophea',
      gradeLabel: 'Grade 12',
      subjects: ['Mathematics'],
      learningStreakDays: 6,
      completedPractice: 14,
      recentActivity: [],
      subjectProgress: [
        SubjectProgress(subject: 'Mathematics', topic: 'Limits', progress: .9),
      ],
      weakTopic: null,
      resumeTitle: 'Limits',
      resumeSubtitle: '',
    );
  }
}

const _complete = StudentProfileView(
  displayName: 'Sophea Chan',
  email: 'sophea@example.com',
  gradeLevelId: 'grade-12',
  preferredLanguage: 'km',
  subjects: ['Mathematics', 'Physics'],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget build({
    StudentProfileView view = _complete,
    bool statsFail = false,
    VoidCallback? onSetup,
    VoidCallback? onLogout,
    Locale locale = const Locale('en'),
  }) => MaterialApp(
    theme: AppTheme.dark(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: StudentProfileSummaryScreen(
        repository: _Profiles(view),
        statsRepository: _Stats(fail: statsFail),
        onSetup: onSetup ?? () {},
        onLogout: onLogout ?? () {},
      ),
    ),
  );

  testWidgets('shows identity, stats and learning setup', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    expect(find.text('Sophea Chan'), findsOneWidget);
    expect(find.text('sophea@example.com'), findsOneWidget);
    expect(find.text('SC'), findsOneWidget);
    expect(find.text('Profile complete'), findsOneWidget);
    expect(find.byKey(const Key('profile-stats-row')), findsOneWidget);
    expect(find.text('6 Days'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Update learning setup'), findsOneWidget);
  });

  testWidgets('stats are left out when the summary cannot load', (tester) async {
    await tester.pumpWidget(build(statsFail: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-stats-row')), findsNothing);
    expect(find.text('Sophea Chan'), findsOneWidget);
  });

  testWidgets('incomplete profile asks the student to finish setup', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      build(
        view: const StudentProfileView(
          displayName: '',
          gradeLevelId: '',
          preferredLanguage: 'en',
          subjects: [],
        ),
        onSetup: () => opened = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Profile not complete'), findsOneWidget);
    final setup = find.byKey(const Key('profile-complete-learning-profile'));
    await tester.ensureVisible(setup);
    await tester.tap(setup);
    expect(opened, isTrue);
  });

  testWidgets('sign out asks for confirmation first', (tester) async {
    var signedOut = false;
    await tester.pumpWidget(build(onLogout: () => signedOut = true));
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('profile-sign-out-button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(signedOut, isFalse);

    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-sign-out-confirm')));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  testWidgets('language preference switches the app language', (tester) async {
    await AppLanguageController.initialize();
    await AppLanguageController.setLanguage('en');
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    final khmer = find.descendant(
      of: find.byKey(const Key('profile-language-toggle')),
      matching: find.text('ខ្មែរ'),
    );
    await tester.ensureVisible(khmer);
    await tester.tap(khmer);
    await tester.pumpAndSettle();
    expect(AppLanguageController.isKhmer, isTrue);
  });

  testWidgets('renders in Khmer', (tester) async {
    await tester.pumpWidget(build(locale: const Locale('km')));
    await tester.pumpAndSettle();
    expect(find.text('គណនី'), findsWidgets);
    expect(find.text('ព័ត៌មានពេញលេញ'), findsOneWidget);
    expect(find.text('ថ្នាក់ទី ១២'), findsWidgets);
    expect(find.text('គណិតវិទ្យា'), findsOneWidget);
    expect(find.text('Profile complete'), findsNothing);
  });

  testWidgets('no overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(build(locale: const Locale('km')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
