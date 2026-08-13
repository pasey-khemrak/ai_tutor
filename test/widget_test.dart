import 'package:ai_tutor/screens/tutor/visual_tutor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Visual Tutor home opens its real text, scan, voice, and stuck entry points', (tester) async {
    var typed = false;
    var scanned = false;
    var voiced = false;
    var stuck = false;

    await tester.pumpWidget(MaterialApp(
      home: VisualTutorHomeScreen(
        onBack: () {},
        onTypeQuestion: () => typed = true,
        onScanProblem: () => scanned = true,
        onVoiceInput: () => voiced = true,
        onStuck: () => stuck = true,
        onContinueLearning: (_) {},
      ),
    ));

    await tester.tap(find.byKey(const Key('type-question-card')));
    await tester.tap(find.byKey(const Key('scan-problem-card')));
    await tester.ensureVisible(find.byKey(const Key('voice-input-card')));
    await tester.tap(find.byKey(const Key('voice-input-card')));
    await tester.ensureVisible(find.byKey(const Key('start-live-help-button')));
    await tester.tap(find.byKey(const Key('start-live-help-button')));

    expect(typed, isTrue);
    expect(scanned, isTrue);
    expect(voiced, isTrue);
    expect(stuck, isTrue);
  });
}
