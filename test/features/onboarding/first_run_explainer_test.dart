import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/onboarding/first_run_explainer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FirstRunExplainerSheet', () {
    testWidgets('renders as a single screen without a carousel PageView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: FirstRunExplainerSheet(
              onStart: () {},
              onSkip: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Invariant: single screen, not a carousel
      expect(find.byType(PageView), findsNothing);
      expect(find.byKey(const Key('first-run-explainer-sheet')), findsOneWidget);

      // Benefit cards / rows
      expect(find.byKey(const Key('first-run-benefit-whiteboard')), findsOneWidget);
      expect(find.byKey(const Key('first-run-benefit-bilingual')), findsOneWidget);
      expect(find.byKey(const Key('first-run-benefit-followups')), findsOneWidget);

      // Action buttons
      expect(find.byKey(const Key('first-run-start-learning-button')), findsOneWidget);
      expect(find.byKey(const Key('first-run-skip-button')), findsOneWidget);
    });

    testWidgets('tapping Skip invokes onSkip and persists seen flag in SharedPreferences', (tester) async {
      var skipped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: FirstRunExplainerSheet(
              onStart: () {},
              onSkip: () => skipped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final skipFinder = find.byKey(const Key('first-run-skip-button'));
      await tester.ensureVisible(skipFinder);
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      expect(skipped, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(FirstRunExplainerSheet.prefKeySeen), isTrue);
    });

    testWidgets('tapping Start Learning invokes onStart and persists seen flag', (tester) async {
      var started = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: FirstRunExplainerSheet(
              onStart: () => started = true,
              onSkip: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final startFinder = find.byKey(const Key('first-run-start-learning-button'));
      await tester.ensureVisible(startFinder);
      await tester.tap(startFinder);
      await tester.pumpAndSettle();

      expect(started, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(FirstRunExplainerSheet.prefKeySeen), isTrue);
    });

    testWidgets('tapping a starter problem chip invokes onSelectProblem with problem text', (tester) async {
      String? selectedProblem;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: FirstRunExplainerSheet(
              onStart: () {},
              onSkip: () {},
              onSelectProblem: (problem) => selectedProblem = problem,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('starter-chip-limits')), findsOneWidget);
      await tester.tap(find.byKey(const Key('starter-chip-limits')));
      await tester.pumpAndSettle();

      expect(selectedProblem, contains('lim'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(FirstRunExplainerSheet.prefKeySeen), isTrue);
    });

    testWidgets('showIfNeeded does not display if already seen', (tester) async {
      SharedPreferences.setMockInitialValues({
        FirstRunExplainerSheet.prefKeySeen: true,
      });

      var shown = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  shown = await FirstRunExplainerSheet.showIfNeeded(context);
                },
                child: const Text('Check'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(shown, isFalse);
      expect(find.byKey(const Key('first-run-explainer-sheet')), findsNothing);
    });
  });
}
