import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_tutor/app/ai_tutor_app.dart';

void main() {
  testWidgets('AI Tutor frontend auth and dashboard flow works', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AiTutorApp());
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.text('Your intelligent learning companion'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsWidgets);
    expect(find.byKey(const Key('forgot-password-link')), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Sign In').last);
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Brathna'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Brathna Student');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ážáŸ’áž“áž¶áž€áŸ‹'), findsWidgets);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('áž˜áž»ážážœáž·áž‡áŸ’áž‡áž¶'), findsWidgets);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Brathna'), findsOneWidget);

    await tester.tap(find.text('VOICE'));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.text('Tutor'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Find the equation line'), findsOneWidget);

    await tester.tap(find.text('Quizzes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bac-dup-quiz-card')), findsOneWidget);
  });
}
