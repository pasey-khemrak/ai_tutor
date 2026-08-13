import 'package:ai_tutor/features/visual_tutor/presentation/visual_tutor_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visual tutor tokens expose screenshot palette values', () {
    expect(VisualTutorColors.shell, const Color(0xFF07101E));
    expect(VisualTutorColors.boardPaper, const Color(0xFFFFFBF1));
    expect(VisualTutorColors.cyan, const Color(0xFF16E5F4));
    expect(VisualTutorColors.orange, const Color(0xFFFFA20D));
    expect(VisualTutorColors.blueInk, const Color(0xFF2E74FF));
    expect(VisualTutorColors.redInk, const Color(0xFFFF4A5F));
    expect(VisualTutorColors.yellowHighlight, const Color(0xFFFFE88A));
    expect(VisualTutorColors.scanIconBackground, const Color(0xFF063B45));
    expect(VisualTutorColors.typeIconBackground, const Color(0xFF2E1D52));
    expect(VisualTutorColors.voiceIconBackground, const Color(0xFF06372F));
    expect(VisualTutorTypography.fontFallback, contains('Noto Sans Khmer'));
  });

  testWidgets('VisualTutorPanel renders reusable rounded mobile card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: VisualTutorColors.shell,
          body: Center(
            child: VisualTutorPanel(child: Text('Visual Tutor panel')),
          ),
        ),
      ),
    );

    expect(find.text('Visual Tutor panel'), findsOneWidget);
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(VisualTutorPanel),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(container.decoration, isA<BoxDecoration>());
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, VisualTutorColors.panel);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(VisualTutorRadius.xl),
    );
  });

  testWidgets('VisualTutorActionCard uses shared mobile card styling', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: VisualTutorColors.shell,
          body: Center(
            child: VisualTutorActionCard(
              icon: Icons.keyboard_rounded,
              iconBackground: VisualTutorColors.typeIconBackground,
              title: 'Type a Question',
              subtitle: 'សរសេរសំណួររបស់អ្នក',
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Type a Question'), findsOneWidget);
    expect(find.text('សរសេរសំណួររបស់អ្នក'), findsOneWidget);
    await tester.tap(find.byType(VisualTutorActionCard));
    expect(tapped, isTrue);
  });

  testWidgets('VisualTutorStatusChip uses screenshot accent token', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: VisualTutorColors.shell,
          body: Center(child: VisualTutorStatusChip(label: 'Writing...')),
        ),
      ),
    );

    expect(find.text('Writing...'), findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(VisualTutorStatusChip),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(
      decoration.borderRadius,
      BorderRadius.circular(VisualTutorRadius.pill),
    );
  });
}
