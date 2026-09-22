import 'dart:io';

import 'package:ai_tutor/core/localization/app_language_controller.dart';
import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/board_pagination.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/board_page_switcher.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/step_interaction_widget.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_repository.dart';
import 'package:ai_tutor/screens/dashboard/dashboard_screen.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_repository.dart';
import 'package:ai_tutor/screens/lessons/student_lessons_screen.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:ai_tutor/screens/tutor/visual_tutor_home_screen.dart';
import 'package:ai_tutor/shared/app_bottom_navigation.dart';
import 'package:ai_tutor/shared/language_switcher_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapWithLocalization(
  Widget child, {
  Locale locale = const Locale('km'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLanguageController & Persistence', () {
    test('defaults to Khmer and toggles between Khmer and English', () async {
      await AppLanguageController.initialize();
      expect(AppLanguageController.isKhmer, isTrue);
      expect(AppLanguageController.currentLocale.value.languageCode, equals('km'));

      await AppLanguageController.toggleLanguage();
      expect(AppLanguageController.isKhmer, isFalse);
      expect(AppLanguageController.currentLocale.value.languageCode, equals('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language_code'), equals('en'));

      await AppLanguageController.setLanguage('km');
      expect(AppLanguageController.isKhmer, isTrue);
      expect(prefs.getString('app_language_code'), equals('km'));
    });

    test('restores saved language preference from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'app_language_code': 'en'});
      await AppLanguageController.initialize();
      expect(AppLanguageController.isKhmer, isFalse);
      expect(AppLanguageController.currentLocale.value.languageCode, equals('en'));
    });
  });

  group('AppLocalizations catalogue', () {
    test('provides Khmer and English translations for core strings', () {
      const en = AppLocalizations(Locale('en'));
      const km = AppLocalizations(Locale('km'));

      // Core actions
      expect(en.appName, equals('Rean AI'));
      expect(km.appName, equals('Rean AI'));
      expect(en.loading, equals('Loading...'));
      expect(km.loading, equals('កំពុងផ្ទុក...'));
      expect(en.retry, equals('Retry'));
      expect(km.retry, equals('សាកល្បងម្តងទៀត'));

      // Auth
      expect(en.signIn, equals('Sign In'));
      expect(km.signIn, equals('ចូលគណនី'));
      expect(en.createAccount, equals('Create Account'));
      expect(km.createAccount, equals('បង្កើតគណនី'));

      // Navigation
      expect(en.navHome, equals('Home'));
      expect(km.navHome, equals('ទំព័រដើម'));
      expect(en.navTutor, equals('Tutor'));
      expect(km.navTutor, equals('គ្រូបង្រៀន'));
      expect(en.navLessons, equals('Lessons'));
      expect(km.navLessons, equals('មេរៀន'));

      // Tutor actions
      expect(en.askAnyQuestionHint, contains('Ask Rean'));
      expect(km.askAnyQuestionHint, contains('សួរសំណួរ'));
      expect(en.typeQuestionTitle, equals('Type a Question'));
      expect(km.typeQuestionTitle, equals('សរសេរសំណួរ'));
      expect(en.voiceInputTitle, equals('Voice Input'));
      expect(km.voiceInputTitle, equals('បញ្ចូលសំឡេង'));
      expect(en.imStuckTitle, equals("I'm Stuck!"));
      expect(km.imStuckTitle, equals('ខ្ញុំទាល់គំនិតហើយ!'));
      expect(en.startLiveHelp, equals('Start Live Help'));
      expect(km.startLiveHelp, equals('ចាប់ផ្តើមជំនួយផ្ទាល់'));

      // Board pagination
      expect(en.boardPageOf(1, 3), equals('Board 1 of 3'));
      expect(km.boardPageOf(1, 3), equals('ក្តារទី ១ នៃ ៣'));
    });
  });

  group('BoardPageSwitcher localization', () {
    testWidgets('renders Khmer board page label under km locale', (tester) async {
      final pages = [
        const BoardPage(index: 0, actions: []),
        const BoardPage(index: 1, actions: []),
        const BoardPage(index: 2, actions: []),
      ];

      await tester.pumpWidget(
        _wrapWithLocalization(
          BoardPageSwitcher(
            pages: pages,
            currentIndex: 0,
            onSelected: (_) {},
          ),
          locale: const Locale('km'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('ក្តារទី ១ នៃ ៣'), findsOneWidget);
      // Must NOT render hardcoded English "Board 1 of 3"
      expect(find.text('Board 1 of 3'), findsNothing);
    });

    testWidgets('renders English board page label under en locale', (tester) async {
      final pages = [
        const BoardPage(index: 0, actions: []),
        const BoardPage(index: 1, actions: []),
      ];

      await tester.pumpWidget(
        _wrapWithLocalization(
          BoardPageSwitcher(
            pages: pages,
            currentIndex: 0,
            onSelected: (_) {},
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Board 1 of 2'), findsOneWidget);
    });
  });

  group('VisualTutorHomeScreen localization', () {
    testWidgets('renders the Khmer curriculum without hardcoded English', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          VisualTutorHomeScreen(
            repository: const LocalDemoStudentLessonsRepository(),
            onOpenLesson: (_) {},
            onAskQuestion: (_) {},
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('កម្មវិធីសិក្សា'), findsOneWidget);
      expect(find.text('សួរលំហាត់ផ្ទាល់ខ្លួន'), findsOneWidget);

      expect(find.text('Curriculum'), findsNothing);
      expect(find.text('Continue Learning'), findsNothing);
      expect(find.text('See All'), findsNothing);
      expect(find.text('Ask your own problem'), findsNothing);
    });
  });

  group('AppBottomNavigation localization', () {
    testWidgets('renders Khmer tab titles under km locale', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          AppBottomNavigation(
            selectedIndex: 0,
            onSelected: (_) {},
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ទំព័រដើម'), findsOneWidget);
      expect(find.text('គ្រូបង្រៀន'), findsOneWidget);
      expect(find.text('មេរៀន'), findsOneWidget);

      expect(find.text('Home'), findsNothing);
      expect(find.text('Tutor'), findsNothing);
      expect(find.text('Lessons'), findsNothing);
      // Voice is reached from Home, not a tab.
      expect(find.text('សំឡេង'), findsNothing);
    });
  });

  group('LanguageSwitcherButton', () {
    testWidgets('displays active language and toggles on tap', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('km');

      await tester.pumpWidget(
        _wrapWithLocalization(
          const LanguageSwitcherButton(),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('language-switcher-button')), findsOneWidget);
      expect(find.text('ខ្មែរ'), findsOneWidget);

      await tester.tap(find.byKey(const Key('language-switcher-button')));
      await tester.pumpAndSettle();

      expect(AppLanguageController.isKhmer, isFalse);
    });
  });

  group('TutorPresenceBar localization', () {
    testWidgets('renders Khmer title, status, and switcher in km mode', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('km');

      await tester.pumpWidget(
        _wrapWithLocalization(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rean AI គ្រូបង្រៀន'), findsOneWidget);
      expect(find.text('កំពុងសរសេរ...'), findsOneWidget);
      expect(find.byKey(const Key('language-switcher-button')), findsOneWidget);
    });
  });

  group('DashboardScreen localization', () {
    testWidgets('renders Khmer headings, metrics, and actions in km mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('km');

      await tester.pumpWidget(
        _wrapWithLocalization(
          DashboardScreen(
            repository: _TestDashboardRepository(),
            onResumeLearning: () {},
            onAskQuestion: (_) {},
            onVoiceQuestion: () {},
            onStartDailyPractice: (_) {},
            onCompleteProfile: () {},
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      // Khmer elements must be present
      expect(find.text('ស្វាគមន៍ 👋'), findsOneWidget);
      expect(find.text('បន្តការរៀន'), findsOneWidget);
      expect(find.text('វឌ្ឍនភាពរបស់អ្នក'), findsOneWidget);
      expect(find.text('ការអនុវត្តប្រចាំថ្ងៃ'), findsOneWidget);
      expect(find.text('ចាប់ផ្តើមលំហាត់'), findsOneWidget);
      expect(find.text('រៀបចំ'), findsOneWidget);
      expect(find.text('ចំនួនថ្ងៃបន្តបន្ទាប់'), findsOneWidget);
      expect(find.text('ស្ទាត់ជំនាញ'), findsOneWidget);

      // Raw hardcoded English headings must NOT be present
      expect(find.text('Continue Learning'), findsNothing);
      expect(find.text('Your progress'), findsNothing);
      expect(find.text('Daily Practice'), findsNothing);
      expect(find.text('Start Challenge'), findsNothing);
      expect(find.text('Set up'), findsNothing);
      expect(find.text('Daily Streak'), findsNothing);
      expect(find.text('Mastered'), findsNothing);
    });
  });

  group('StudentLessonsScreen localization', () {
    testWidgets('renders Khmer chips and empty state in km mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('km');

      await tester.pumpWidget(
        _wrapWithLocalization(
          StudentLessonsScreen(
            repository: const _EmptyStudentLessonsRepository(),
            onOpenLesson: (_) {},
            onPractice: (_) {},
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('គ្រប់មុខវិជ្ជា'), findsOneWidget);
      expect(find.text('ស្វែងរកមេរៀន ឬប្រធានបទ'), findsOneWidget);
      expect(find.text('មិនទាន់មានមេរៀននៅឡើយទេ'), findsOneWidget);

      // English equivalents must NOT be present
      expect(find.text('All subjects'), findsNothing);
      expect(find.text('Search lessons or topics'), findsNothing);
      expect(find.text('No lessons are available yet'), findsNothing);
    });
  });

  group('StepInteractionWidget localization', () {
    testWidgets('renders Khmer action buttons in km mode', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          StepInteractionWidget(
            responseType: 'short_answer',
            question: 'What is the limit?',
            onSubmit: (_) {},
            onHint: () {},
            onSkip: () {},
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ជំនួយ'), findsOneWidget);
      expect(find.text('រំលង'), findsOneWidget);
      expect(find.text('បញ្ជូន'), findsOneWidget);

      expect(find.text('Hint'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Submit'), findsNothing);
    });
  });

  group('Source code audit: no raw hardcoded strings in screens', () {
    test('screens do not contain raw hardcoded English action strings', () {
      final forbiddenInScreens = [
        "'Type a Question'",
        "'Start Live Help'",
        "'Review previous'",
        "'Jump to latest'",
        "'Resume task'",
        "'Next Practice Problem  →'",
        "'Try Another Problem'",
        "'Report explanation'",
        "'Cancel recording'",
        "'Conversation History'",
        "'Daily Streak'",
        "'No lessons are available yet'",
      ];

      final filesToCheck = [
        'lib/screens/tutor/tutor_screen.dart',
        'lib/screens/tutor/visual_tutor_home_screen.dart',
        'lib/screens/dashboard/dashboard_screen.dart',
        'lib/screens/lessons/student_lessons_screen.dart',
        'lib/features/visual_tutor/presentation/widgets/board_page_switcher.dart',
      ];

      for (final filePath in filesToCheck) {
        final file = File(filePath);
        if (!file.existsSync()) continue;
        final content = file.readAsStringSync();
        for (final forbidden in forbiddenInScreens) {
          expect(
            content.contains(forbidden),
            isFalse,
            reason: '$filePath contains hardcoded string $forbidden',
          );
        }
      }
    });
  });
}

class _TestDashboardRepository implements DashboardRepository {
  @override
  Future<StudentDashboardData> loadDashboard() async {
    return const StudentDashboardData(
      studentName: 'Alex',
      gradeLabel: 'Grade 12',
      subjects: [],
      learningStreakDays: 5,
      recentActivity: [],
      subjectProgress: [
        SubjectProgress(
          subject: 'Mathematics',
          topic: 'Limits of Functions',
          progress: 0.85,
        ),
      ],
      weakTopic: null,
      resumeTitle: 'Limits of Functions',
      resumeSubtitle: 'Indeterminate Forms',
    );
  }
}

class _EmptyStudentLessonsRepository implements StudentLessonsRepository {
  const _EmptyStudentLessonsRepository();

  @override
  Future<List<StudentLesson>> loadLessons({
    String? search,
    String? subjectId,
    String? topicId,
    int? grade,
  }) async {
    return const [];
  }
}
