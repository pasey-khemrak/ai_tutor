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
    await tester.pumpWidget(const AiTutorApp());

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

    await tester.tap(find.text('Sign In').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('ថ្នាក់'), findsWidgets);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('មុខវិជ្ជា'), findsWidgets);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.text('Tutor'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Find the equation line'), findsOneWidget);

    await tester.tap(find.text('Quizzes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bac-dup-quiz-card')), findsOneWidget);
  });
}
