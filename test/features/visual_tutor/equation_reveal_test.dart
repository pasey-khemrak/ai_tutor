/// An equation is revealed by clipping the drawn maths, never by cutting its
/// LaTeX source.
///
/// Half of "\quad" is not valid LaTeX, so character-by-character reveal made
/// the renderer fall back to printing the raw command on the board mid-write.
library;
import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/board_element_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cancelStep = VisualTutorBoardActionEntity(
    id: 'cancel',
    type: 'write_equation',
    sequenceIndex: 0,
    x: 24,
    y: 24,
    width: 600,
    height: 80,
    latex: r'\frac{x^{2} - 9}{x - 3} = x + 3, \quad x \neq 3',
  );

  Widget board(Animation<double> progress) => MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      body: SizedBox(
        width: 700,
        height: 300,
        child: Stack(
          children: [
            BoardElementRenderer(action: cancelStep, progress: progress),
          ],
        ),
      ),
    ),
  );

  testWidgets('no raw LaTeX is shown at any point while writing', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 400),
    );
    addTearDown(controller.dispose);

    for (final value in [0.0, 0.15, 0.4, 0.6, 0.85, 1.0]) {
      controller.value = value;
      await tester.pumpWidget(board(controller));
      await tester.pump();

      // Any of these on screen means the source string leaked to the student.
      for (final fragment in [r'\frac', r'\quad', r'\q', r'\neq', r'x^{2}']) {
        expect(
          find.textContaining(fragment),
          findsNothing,
          reason: 'raw "$fragment" must never be drawn (progress $value)',
        );
      }
    }
  });
}
