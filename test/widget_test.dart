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
    expect(find.textContaining('Find the equation of the line'), findsNothing);
    expect(find.text('Step 1: Find the Slope'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('tutor-message-field')),
      'Find the equation of the line',
    );
    await tester.tap(find.byKey(const Key('tutor-send-button')));
    await pumpFrame();
    expect(find.textContaining('Find the equation of the line'), findsOneWidget);
    expect(find.text('Step 1: Find the Slope'), findsOneWidget);
    expect(find.text('Next Step'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await pumpFrame();
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Khemrak Pasey'), findsWidgets);

    await tester.tap(find.byTooltip('Settings'));
    await pumpFrame();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Logout from Rean'), findsOneWidget);
  });
}
