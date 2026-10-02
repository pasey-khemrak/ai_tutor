import 'package:ai_tutor/core/theme/app_theme.dart';
import 'package:ai_tutor/features/visual_tutor/domain/entities/visual_tutor_entities.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/widgets/board_element_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget render(String text, {String id = 'inline-math'}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 180,
          child: Stack(
            children: [
              BoardElementRenderer(
                action: VisualTutorBoardActionEntity(
                  id: id,
                  type: 'write_text',
                  text: text,
                  x: 12,
                  y: 12,
                  width: 560,
                  height: 150,
                ),
                reducedMotion: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String selectableProse(WidgetTester tester) => tester
      .widgetList<SelectableText>(find.byType(SelectableText))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
      .join();

  testWidgets(
    r'write_text renders $...$ and \(...\) as math but keeps currency as prose',
    (tester) async {
      const content =
          r'The notebook costs $25. Our goal is to isolate $x$ and use \(x^2 \to 4\).';
      await tester.pumpWidget(render(content));
      await tester.pump();

      expect(find.byType(Math), findsNWidgets(2));
      final prose = selectableProse(tester);
      expect(prose, contains(r'$25'));
      expect(prose, contains('Our goal is to isolate'));
      expect(prose, isNot(contains(r'$x$')));
      expect(prose, isNot(contains(r'\(')));
      expect(prose, isNot(contains(r'\)')));
    },
  );

  testWidgets(
    'Khmer prose keeps accessible inline superscripts, arrows, and limits',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        const content =
            r'គោលដៅរបស់យើងគឺ $x^2$ ពេល \(x□2\) ហើយរក $\lim_{x \to 2} f(x)$។';
        await tester.pumpWidget(render(content, id: 'khmer-inline-math'));
        await tester.pump();

        expect(find.byType(Math), findsNWidgets(3));
        expect(selectableProse(tester), contains('គោលដៅរបស់យើង'));

        final actionSemantics = tester.getSemantics(
          find.byKey(const Key('teaching-board-action-khmer-inline-math')),
        );
        expect(actionSemantics.label, contains('គោលដៅរបស់យើង'));
        expect(actionSemantics.label, contains('x → 2'));
        expect(actionSemantics.label, isNot(contains('□')));
        expect(actionSemantics.label, isNot(contains(r'$x^2$')));
        expect(actionSemantics.label, isNot(contains(r'\(')));
        expect(actionSemantics.label, isNot(contains(r'\)')));

        final rawTextWidgets = tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data ?? '')
            .where(
              (text) =>
                  text.contains(r'$x^2$') ||
                  text.contains(r'\(') ||
                  text.contains(r'\)'),
            );
        expect(rawTextWidgets, isEmpty);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('common algebra and chemistry fragments are not left raw', (
    tester,
  ) async {
    const content = r'Use $2x$, $(x-2)$, $-x$, and $NaCl$.';
    await tester.pumpWidget(render(content));
    await tester.pump();

    expect(find.byType(Math), findsNWidgets(4));
    expect(selectableProse(tester), isNot(contains(r'$2x$')));
    expect(selectableProse(tester), isNot(contains(r'$(x-2)$')));
    expect(selectableProse(tester), isNot(contains(r'$NaCl$')));
  });

  testWidgets('multiple currency amounts remain intact ordinary prose', (
    tester,
  ) async {
    const content = r'It costs $5 + $2 in fees, or $10-$12 total.';
    await tester.pumpWidget(render(content));
    await tester.pump();

    expect(find.byType(Math), findsNothing);
    expect(selectableProse(tester), contains(content));
  });
}
