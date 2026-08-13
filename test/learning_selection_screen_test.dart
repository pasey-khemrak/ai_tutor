import 'package:ai_tutor/app/tutor_shell.dart';
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('student can select grade Mathematics and topic', (tester) async {
    LearningContext? selectedContext;
    await tester.pumpWidget(
      wrap(
        LearningSelectionScreen(
          repository: const MockLearningSelectionRepository(
            delay: Duration.zero,
          ),
          onJoinClass: (context) => selectedContext = context,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Grade 10'), findsOneWidget);
    expect(find.text('Grade 11'), findsOneWidget);
    expect(find.text('Grade 12'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Linear Equations'), findsOneWidget);
    expect(find.text('Coordinate Plane'), findsOneWidget);
    expect(find.text('Slope'), findsOneWidget);
    expect(find.text('Equation of a Line'), findsOneWidget);
    expect(find.text('Functions'), findsOneWidget);
    expect(find.text('Quadratic Functions'), findsOneWidget);

    await tester.tap(find.byKey(const Key('grade-11-option')));
    await tester.tap(find.byKey(const Key('subject-Mathematics-option')));
    await tester.ensureVisible(find.byKey(const Key('topic-Slope-option')));
    await tester.tap(find.byKey(const Key('topic-Slope-option')));
    await tester.ensureVisible(find.byKey(const Key('join-class-button')));
    await tester.tap(find.byKey(const Key('join-class-button')));
    await tester.pump();

    expect(selectedContext?.grade, 11);
    expect(selectedContext?.subject, 'Mathematics');
    expect(selectedContext?.topic, 'Slope');
  });

  testWidgets('Tutor shell home opens live tutor with default context', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const TutorShell()),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Tutor'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('visual-tutor-home-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('type-question-card')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('visual-tutor-canvas-board')), findsOneWidget);
    expect(find.byKey(const Key('tutor-presence-bar')), findsOneWidget);
    expect(find.text('Rean AI'), findsOneWidget);
    expect(find.textContaining('រង់ចាំអ្នក'), findsOneWidget);
  });

  testWidgets('selection screen has loading and error states', (tester) async {
    await tester.pumpWidget(
      wrap(
        LearningSelectionScreen(
          repository: const MockLearningSelectionRepository(),
          onJoinClass: (_) {},
        ),
      ),
    );

    expect(find.text('Loading classes...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(
      wrap(
        LearningSelectionScreen(
          repository: const ErrorLearningSelectionRepository(),
          onJoinClass: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Could not load subjects and topics.'), findsOneWidget);
  });
}
