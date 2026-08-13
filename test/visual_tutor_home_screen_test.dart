import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/visual_tutor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildScreen({
    VoidCallback? onTypeQuestion,
    VoidCallback? onVoiceInput,
    VoidCallback? onStuck,
    VoidCallback? onScanProblem,
    ValueChanged<LearningContext>? onContinueLearning,
  }) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: VisualTutorHomeScreen(
          onBack: () {},
          onTypeQuestion: onTypeQuestion ?? () {},
          onVoiceInput: onVoiceInput ?? () {},
          onStuck: onStuck ?? () {},
          onScanProblem: onScanProblem ?? () {},
          onContinueLearning: onContinueLearning ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('all Visual Tutor home cards render', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.byKey(const Key('visual-tutor-home-screen')), findsOneWidget);
    expect(find.text('Rean AI Visual Tutor'), findsOneWidget);
    expect(find.text('រៀនជាមួយគ្រូ AI'), findsOneWidget);
    expect(find.byKey(const Key('visual-tutor-welcome-panel')), findsOneWidget);
    expect(find.text('How can I help you\ntoday?'), findsOneWidget);
    expect(find.byKey(const Key('scan-problem-card')), findsOneWidget);
    expect(find.byKey(const Key('type-question-card')), findsOneWidget);
    expect(find.byKey(const Key('voice-input-card')), findsOneWidget);
    expect(find.byKey(const Key('visual-tutor-stuck-card')), findsOneWidget);
    expect(find.text('Continue Learning'), findsOneWidget);
    expect(find.text('Quadratic Equations'), findsOneWidget);
    expect(find.text('Organic Chemistry'), findsOneWidget);
  });

  testWidgets('action cards call navigation callbacks', (tester) async {
    var typed = false;
    var voice = false;
    var stuck = false;
    var scanned = false;
    LearningContext? continued;

    await tester.pumpWidget(
      buildScreen(
        onTypeQuestion: () => typed = true,
        onVoiceInput: () => voice = true,
        onStuck: () => stuck = true,
        onScanProblem: () => scanned = true,
        onContinueLearning: (context) => continued = context,
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('type-question-card')));
    await tester.tap(find.byKey(const Key('type-question-card')));
    await tester.ensureVisible(find.byKey(const Key('voice-input-card')));
    await tester.tap(find.byKey(const Key('voice-input-card')));
    await tester.ensureVisible(find.byKey(const Key('scan-problem-card')));
    await tester.tap(find.byKey(const Key('scan-problem-card')));
    await tester.ensureVisible(find.byKey(const Key('start-live-help-button')));
    await tester.tap(find.byKey(const Key('start-live-help-button')));
    await tester.ensureVisible(
      find.byKey(const Key('continue-quadratic-equations')),
    );
    await tester.tap(find.byKey(const Key('continue-quadratic-equations')));

    expect(typed, isTrue);
    expect(voice, isTrue);
    expect(scanned, isTrue);
    expect(stuck, isTrue);
    expect(continued?.topic, 'Quadratic Equations');
  });

  testWidgets('Visual Tutor home has no mobile overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('visual-tutor-home-screen')), findsOneWidget);
    expect(find.byKey(const Key('visual-tutor-stuck-card')), findsOneWidget);
  });
}
