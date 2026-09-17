import 'package:ai_tutor/app/tutor_shell.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Voice tab opens the real Visual Tutor in microphone-first mode',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const TutorShell()),
      );

      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('visual-tutor-board-vertical-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('voice-response-button')), findsOneWidget);
      expect(find.byKey(const Key('voice-open-keyboard')), findsOneWidget);
      expect(find.text('What is the integral of e^x?'), findsNothing);

      await tester.tap(find.byKey(const Key('voice-open-keyboard')));
      await tester.pump();

      expect(find.byKey(const Key('tutor-message-field')), findsOneWidget);
      expect(find.byKey(const Key('voice-close-keyboard')), findsOneWidget);
      expect(find.byKey(const Key('voice-response-button')), findsOneWidget);
    },
  );

  testWidgets(
    'Tutor navigation is authoritative and replaces a voice tutor route with tutor home',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const TutorShell()),
      );

      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('voice-response-button')), findsOneWidget);

      await tester.tap(find.text('Tutor'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('visual-tutor-home-screen')), findsOneWidget);
      expect(find.byKey(const Key('voice-response-button')), findsNothing);
      expect(
        find.byKey(const Key('visual-tutor-board-vertical-scroll')),
        findsNothing,
      );
    },
  );
}
