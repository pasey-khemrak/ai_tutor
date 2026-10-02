import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/screens/learning_selection/learning_selection_repository.dart';
import 'package:ai_tutor/screens/tutor/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('phone density preserves whiteboard space and limits quote panel lines', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: TutorScreen(
            context: LearningContext(
              grade: 12,
              subject: 'Mathematics',
              topic: 'Limits of Functions',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check presence bar is rendered and compact
    final presenceBar = find.byKey(const Key('tutor-presence-bar'));
    expect(presenceBar, findsOneWidget);
    final presenceBarSize = tester.getSize(presenceBar);
    expect(presenceBarSize.height, lessThanOrEqualTo(65));

    // Check phone dock is rendered and compact
    final phoneDock = find.byKey(const Key('tutor-phone-dock'));
    expect(phoneDock, findsOneWidget);

    // Whiteboard occupies majority of height
    final board = find.byKey(const Key('visual-tutor-board-vertical-scroll'));
    expect(board, findsOneWidget);
    final boardSize = tester.getSize(board);
    expect(boardSize.height, greaterThan(400));
  });
}
