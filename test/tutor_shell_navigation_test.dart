import 'package:ai_tutor/app/tutor_shell.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'bottom navigation opens the real Visual Tutor voice entry point',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const TutorShell()),
      );

      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();

      expect(find.text('Rean AI Tutor'), findsOneWidget);
      expect(find.text('Waiting for you'), findsOneWidget);
      expect(
        find.byKey(const Key('visual-tutor-canvas-board')),
        findsOneWidget,
      );
    },
  );
}
