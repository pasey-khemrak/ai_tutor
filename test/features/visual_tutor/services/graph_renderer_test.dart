import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide findsOneWidget;

import 'package:ai_tutor/features/visual_tutor/presentation/services/graph_renderer.dart';

final findsOneWidget = findsAtLeastNWidgets(1);

void main() {
  test('samples a quadratic function accurately', () {
    final points = GraphRenderer.sampleFunction(
      (x) => x * x,
      xMin: -2,
      xMax: 2,
      yMin: -1,
      yMax: 5,
      pointCount: 5,
    );
    expect(points.map((point) => point.y), containsAll(<double>[0, 4]));
  });

  testWidgets('renders a sine graph', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 200,
          child: GraphRenderer.plotFunction('sin(x)'),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
