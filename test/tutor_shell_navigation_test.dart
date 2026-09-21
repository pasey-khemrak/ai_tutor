import 'package:ai_tutor/app/tutor_shell.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom navigation has no Voice tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const TutorShell()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tutor'), findsOneWidget);
    expect(find.text('Lessons'), findsOneWidget);
    expect(find.text('Voice'), findsNothing);
  });

  testWidgets('Tutor navigation is authoritative and opens tutor home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const TutorShell()),
    );

    await tester.tap(find.text('Lessons'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tutor'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('visual-tutor-home-screen')), findsOneWidget);
    expect(find.byKey(const Key('voice-response-button')), findsNothing);
  });
}
