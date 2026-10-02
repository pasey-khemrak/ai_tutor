import 'package:ai_tutor/core/localization/app_language_controller.dart';
import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
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

  group('Curriculum Status Badge in TutorPresenceBar', () {
    testWidgets('displays verified curriculum badge when verified is true', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('en');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            metadata: {
              'verified': true,
              'curriculum_status': 'verified_curriculum',
              'curriculum_topic': 'Limits of Functions',
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-verified-badge')), findsOneWidget);
      expect(find.byKey(const Key('curriculum-unverified-badge')), findsNothing);
      expect(find.text('✓ Verified Curriculum'), findsOneWidget);
    });

    testWidgets('displays AI unverified badge when verified is false', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('en');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            metadata: {
              'verified': false,
              'curriculum_status': 'ai_unverified',
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-verified-badge')), findsNothing);
      expect(find.byKey(const Key('curriculum-unverified-badge')), findsOneWidget);
      expect(find.text('AI Generated (Unverified)'), findsOneWidget);
    });

    testWidgets('displays verified badge in Khmer when locale is km', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('km');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            metadata: {
              'verified': true,
              'curriculum_status': 'verified_curriculum',
            },
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-verified-badge')), findsOneWidget);
      expect(find.text('✓ ផ្ទៀងផ្ទាត់តាមកម្មវិធីសិក្សា'), findsOneWidget);
    });

    testWidgets('displays unverified badge in Khmer when locale is km', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('km');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            metadata: {
              'verified': false,
              'curriculum_status': 'ai_unverified',
            },
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-unverified-badge')), findsOneWidget);
      expect(find.text('ចម្លើយ AI (មិនទាន់ផ្ទៀងផ្ទាត់)'), findsOneWidget);
    });

    testWidgets('does not display any badge when verified metadata is omitted', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('en');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            metadata: {},
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-verified-badge')), findsNothing);
      expect(find.byKey(const Key('curriculum-unverified-badge')), findsNothing);
    });

    testWidgets('displays compact verified badge on mobile in English', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('en');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            compact: true,
            metadata: {
              'verified': true,
              'curriculum_status': 'verified_curriculum',
              'curriculum_topic': 'Limits of Functions',
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-verified-badge')), findsOneWidget);
      expect(find.text('✓ Verified'), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byKey(const Key('curriculum-verified-badge')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, equals('Topic: Limits of Functions'));
    });

    testWidgets('displays compact unverified badge on mobile in English', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('en');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            compact: true,
            metadata: {
              'verified': false,
              'curriculum_status': 'ai_unverified',
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-unverified-badge')), findsOneWidget);
      expect(find.text('AI Unverified'), findsOneWidget);
    });

    testWidgets('displays compact verified badge on mobile in Khmer with localized tooltip', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('km');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            compact: true,
            metadata: {
              'verified': true,
              'curriculum_status': 'verified_curriculum',
              'curriculum_topic': 'លីមីតនៃអនុគមន៍',
            },
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-verified-badge')), findsOneWidget);
      expect(find.text('✓ ផ្ទៀងផ្ទាត់'), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byKey(const Key('curriculum-verified-badge')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, equals('ប្រធានបទ៖ លីមីតនៃអនុគមន៍'));
    });

    testWidgets('displays compact unverified badge on mobile in Khmer', (tester) async {
      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('km');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            compact: true,
            metadata: {
              'verified': false,
              'curriculum_status': 'ai_unverified',
            },
          ),
          locale: const Locale('km'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-unverified-badge')), findsOneWidget);
      expect(find.text('AI មិនទាន់ផ្ទៀងផ្ទាត់'), findsOneWidget);
    });

    testWidgets('renders cleanly on narrow mobile screen without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await AppLanguageController.initialize();
      await AppLanguageController.setLanguage('en');

      await tester.pumpWidget(
        _wrap(
          const TutorPresenceBar(
            learningContext: null,
            stageState: 'drawing',
            compact: true,
            metadata: {
              'verified': true,
              'curriculum_status': 'verified_curriculum',
              'curriculum_topic': 'Newton Second Law of Motion',
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('curriculum-verified-badge')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
