import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tutor/app/ai_tutor_app.dart';

void main() {
  testWidgets('AI Tutor frontend auth and dashboard flow works', (
    WidgetTester tester,
  ) async {
    Future<void> pumpFrame() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(const AiTutorApp());
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

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

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Sign In').last);
    await pumpFrame();

    expect(find.text('Good morning, Brathna'), findsOneWidget);

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
    expect(find.text('Ask any question to start chatting'), findsOneWidget);
    expect(find.textContaining('Find the equation of the line'), findsNothing);
    expect(find.text('Step 1: Find the Slope'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('tutor-message-field')),
      'Find the equation of the line',
    );
    await tester.tap(find.byKey(const Key('tutor-send-button')));
    await pumpFrame();
    expect(find.textContaining('Find the equation of the line'), findsOneWidget);
    expect(find.textContaining('the equation is y = 2x + 1'), findsOneWidget);
    expect(find.text('Step 1: Find the Slope'), findsNothing);

    await tester.tap(find.text('Profile'));
    await pumpFrame();
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Khemrak Pasey'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('profile-edit-save-button')));
    await pumpFrame();
    await tester.tap(find.byKey(const Key('profile-edit-save-button')));
    await pumpFrame();
    await tester.ensureVisible(find.byKey(const Key('profile-avatar-edit-button')));
    await pumpFrame();
    await tester.tap(find.byKey(const Key('profile-avatar-edit-button')));
    await pumpFrame();
    expect(find.text('Choose Profile'), findsOneWidget);
    expect(find.byKey(const Key('profile-avatar-upload-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-avatar-choice-1')));
    await pumpFrame();
    await tester.ensureVisible(find.byKey(const Key('profile-name-field')));
    await pumpFrame();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile-name-field')),
        matching: find.byType(TextField),
      ),
      'Sokha Rean',
    );
    await tester.ensureVisible(find.byKey(const Key('profile-grade-field')));
    await pumpFrame();
    await tester.tap(find.byKey(const Key('profile-grade-field')));
    await pumpFrame();
    await tester.tap(find.text('Grade 11').last);
    await pumpFrame();
    await tester.ensureVisible(find.byKey(const Key('profile-goal-field')));
    await pumpFrame();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('profile-goal-field')),
        matching: find.byType(TextField),
      ),
      'Improve algebra every day',
    );
    await tester.ensureVisible(find.byKey(const Key('profile-edit-save-button')));
    await pumpFrame();
    await tester.tap(find.byKey(const Key('profile-edit-save-button')));
    await pumpFrame();
    expect(find.text('Sokha Rean'), findsWidgets);
    expect(find.text('Grade 11'), findsWidgets);
    expect(find.text('Improve algebra every day'), findsOneWidget);

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

    await tester.tap(find.byKey(const Key('settings-grade-row')));
    await pumpFrame();
    expect(find.text('Choose Grade'), findsOneWidget);
    await tester.tap(find.text('Grade 10').last);
    await pumpFrame();
    expect(find.text('Grade 10'), findsWidgets);

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

    await tester.tap(find.byTooltip('Back'));
    await pumpFrame();
    expect(find.text('Sokha Rean'), findsWidgets);
    expect(find.text('Grade 10'), findsWidgets);
    expect(find.text('Master algebra before finals'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await pumpFrame();

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
