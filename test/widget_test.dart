// This is a basic Flutter widget test.
//
// To perform an interaction with a widget, use the WidgetTester utility in the
// flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tutor/app/ai_tutor_app.dart';

void main() {
  testWidgets('AI Tutor shell shows generated screens', (
    WidgetTester tester,
  ) async {
    Future<void> pumpFrame() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(const AiTutorApp());

    expect(find.text('Your intelligent learning companion'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.byKey(const Key('auth-footer-next-button')));
    await pumpFrame();
    await tester.tap(find.byKey(const Key('auth-footer-next-button')));
    await pumpFrame();
    await tester.tap(find.byKey(const Key('auth-footer-next-button')));
    await pumpFrame();

    expect(find.text('Sign In'), findsWidgets);
    expect(find.byKey(const Key('forgot-password-link')), findsOneWidget);

    await tester.tap(find.text('Sign In').last);
    await pumpFrame();

    expect(find.text('Dashboard'), findsWidgets);

    await tester.tap(find.text('Voice'));
    await pumpFrame();
    expect(find.text('Ready for voice tutoring'), findsOneWidget);
    expect(find.byKey(const Key('voice-start-button')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('voice-start-button')));
    await tester.tap(find.byKey(const Key('voice-start-button')));
    await pumpFrame();
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.text('Tutor'));
    await pumpFrame();
    expect(find.text('Hey Khemrak, how can I help you today?'), findsOneWidget);
    expect(find.textContaining('Find the equation of the line'), findsNothing);
    expect(find.text('Step 1: Find the Slope'), findsNothing);

    await tester.tap(find.text('Ask Rean any question!'));
    await pumpFrame();
    expect(find.textContaining('Find the equation of the line'), findsOneWidget);
    expect(find.text('Step 1: Find the Slope'), findsOneWidget);
    expect(find.text('Next Step'), findsOneWidget);

    await tester.tap(find.text('Quizzes'));
    await pumpFrame();
    expect(find.text('គណិតវិទ្យា'), findsOneWidget);
    expect(find.byKey(const Key('bac-dup-quiz-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bac-dup-quiz-card')));
    await pumpFrame();
    expect(find.text('បាក់ឌុប'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-intro-back-button')));
    await pumpFrame();
    expect(find.text('គណិតវិទ្យា'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('semester-quiz-card')));
    await tester.tap(find.byKey(const Key('semester-quiz-card')));
    await pumpFrame();
    expect(find.text('ប្រចាំឆមាស'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz-intro-back-button')));
    await pumpFrame();
    await tester.tap(find.byKey(const Key('bac-dup-quiz-card')));
    await pumpFrame();
    expect(find.text('បាក់ឌុប'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('ចាប់ផ្តើម'));
    await pumpFrame();
    await tester.tap(find.textContaining('ចាប់ផ្តើម'));
    await pumpFrame();
    expect(find.textContaining('f(x) = √'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('ពិនិត្យលទ្ធផល'));
    await pumpFrame();
    await tester.tap(find.textContaining('ពិនិត្យលទ្ធផល'));
    await pumpFrame();
    expect(find.text('បានបញ្ចប់ការតេស្ត'), findsOneWidget);

    await tester.ensureVisible(find.text('មើលចម្លើយលម្អិត'));
    await pumpFrame();
    await tester.tap(find.text('មើលចម្លើយលម្អិត'));
    await pumpFrame();
    expect(find.textContaining('ទាំងអស់'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await pumpFrame();
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Khemrak Pasey'), findsWidgets);

    await tester.tap(find.byTooltip('Settings'));
    await pumpFrame();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Logout from Rean'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-password-row')));
    await pumpFrame();
    expect(find.text('Change Password'), findsWidgets);
    expect(find.byKey(const Key('current-password-field')), findsOneWidget);
    expect(find.byKey(const Key('new-password-field')), findsOneWidget);
    expect(find.byKey(const Key('confirm-password-field')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await pumpFrame();

    await tester.tap(find.byKey(const Key('settings-level-row')));
    await pumpFrame();
    expect(find.text('Choose Level'), findsOneWidget);
    await tester.tap(find.text('High'));
    await pumpFrame();
    expect(find.text('High'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('settings-goal-row')));
    await pumpFrame();
    await tester.tap(find.byKey(const Key('settings-goal-row')));
    await pumpFrame();
    expect(find.byKey(const Key('learning-goal-field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('learning-goal-field')),
      'Master algebra before finals',
    );
    await tester.tap(find.byKey(const Key('save-goal-button')));
    await pumpFrame();
    expect(find.text('Master algebra before finals'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('settings-reminders-row')));
    await tester.tap(find.byKey(const Key('settings-reminders-row')));
    await pumpFrame();
    expect(find.text('Notifications are off'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-sound-row')));
    await pumpFrame();
    expect(find.text('Button and tutor sounds are on'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('settings-theme-row')));
    await tester.tap(find.byKey(const Key('settings-theme-row')));
    await pumpFrame();
    expect(find.text('Light Mode'), findsOneWidget);
  });
}
