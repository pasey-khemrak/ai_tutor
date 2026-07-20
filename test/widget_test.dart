// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:ai_tutor/app/ai_tutor_app.dart';

void main() {
  testWidgets('AI Tutor shell shows generated screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AiTutorApp());

    expect(find.text('Rean រៀន'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.text('Tutor'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Find the equation line'), findsOneWidget);

    await tester.tap(find.text('Quizzes'));
    await tester.pumpAndSettle();
    expect(find.text('គណិតវិទ្យា'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bac-dup-quiz-card')));
    await tester.pumpAndSettle();
    expect(find.text('លំហាត់អនុគមន៍'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('ចាប់ផ្តើម'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ចាប់ផ្តើម'));
    await tester.pumpAndSettle();
    expect(find.textContaining('f(x) = √'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('ពិនិត្យលទ្ធផល'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ពិនិត្យលទ្ធផល'));
    await tester.pumpAndSettle();
    expect(find.text('បានបញ្ចប់ការតេស្ត'), findsOneWidget);

    await tester.ensureVisible(find.text('មើលចម្លើយលម្អិត'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('មើលចម្លើយលម្អិត'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ទាំងអស់'), findsOneWidget);
  });
}
