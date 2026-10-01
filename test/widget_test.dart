import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/tutor/visual_tutor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VisualTutorHomeScreen opens whiteboard with fresh board prompt and chips', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(
        body: VisualTutorHomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('visual-tutor-home-screen')), findsOneWidget);
    expect(find.byKey(const Key('fresh-board-prompt')), findsOneWidget);

    final chip = find.byKey(const Key('fresh-board-topic-limits'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.textContaining('limit of (x^2 - 4)/(x - 2)'), findsOneWidget);
  });
}
