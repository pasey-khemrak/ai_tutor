import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ai_tutor/core/localization/app_localizations.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Student-Centric Error & Refusal Overhaul', () {
    testWidgets('unsupported problem shows supported-topic chips and NO Contact Support button', (tester) async {
      VisualTutorStudentSubmission? submitted;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: StudentInteractionPanel(
              controller: TextEditingController(),
              turn: const VisualTutorTurnResponseEntity(
                sessionId: 'sess-1',
                turnId: 'turn-refused',
                screenState: 'unsupported_problem',
                teachingMode: 'guided',
                speech: VisualTutorSpeechEntity(
                  text: 'This topic is out of scope.',
                ),
                board: VisualTutorBoardEntity(
                  type: 'unsupported_problem',
                  metadata: {'screen_state': 'unsupported_problem'},
                ),
                boardActions: [],
                displayText: 'This topic is out of scope.',
                spokenText: 'This topic is out of scope.',
                studentTask: 'Try a Grade 12 Math, Physics, or Chemistry problem.',
                finalAnswerLocked: false,
              ),
              latestStudentMessage: 'Can you teach me history?',
              onSubmit: (submission) => submitted = submission,
              onReset: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No developer-shaped "Contact Support" button!
      expect(find.byKey(const Key('unsupported-contact-support-button')), findsNothing);

      // Must have actionable starter chips for supported Grade 12 STEM
      expect(find.byKey(const Key('unsupported-chip-limits')), findsOneWidget);
      expect(find.byKey(const Key('unsupported-chip-physics')), findsOneWidget);
      expect(find.byKey(const Key('unsupported-chip-chemistry')), findsOneWidget);
      expect(find.byKey(const Key('unsupported-try-another-button')), findsOneWidget);

      // Tapping a supported chip submits that problem directly
      await tester.tap(find.byKey(const Key('unsupported-chip-limits')));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.message, contains('lim'));
      expect(submitted!.action, 'submit_problem');
    });

    testWidgets('unsupported panel displays Khmer copy when Khmer locale is active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('km'),
          supportedLocales: const [Locale('km'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.dark(),
          home: Scaffold(
            body: StudentInteractionPanel(
              controller: TextEditingController(),
              turn: const VisualTutorTurnResponseEntity(
                sessionId: 'sess-1',
                turnId: 'turn-refused-km',
                screenState: 'unsupported_problem',
                teachingMode: 'guided',
                speech: VisualTutorSpeechEntity(
                  text: 'មេរៀននេះមិនទាន់មានទេ។',
                ),
                board: VisualTutorBoardEntity(
                  type: 'unsupported_problem',
                  metadata: {'screen_state': 'unsupported_problem'},
                ),
                boardActions: [],
                displayText: 'មេរៀននេះមិនទាន់មានទេ។',
                spokenText: 'មេរៀននេះមិនទាន់មានទេ។',
                studentTask: 'សូមសាកល្បងលំហាត់ថ្នាក់ទី១២។',
                finalAnswerLocked: false,
              ),
              latestStudentMessage: 'បង្រៀនប្រវត្តិវិទ្យា',
              onSubmit: (_) {},
              onReset: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unsupported-action-panel')), findsOneWidget);
      expect(find.byKey(const Key('unsupported-contact-support-button')), findsNothing);
      expect(find.text('ទាក់ទងជំនួយ'), findsNothing);
    });
  });
}
