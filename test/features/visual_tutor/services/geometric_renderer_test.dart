import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide findsOneWidget;

import 'package:ai_tutor/features/visual_tutor/presentation/services/geometric_renderer.dart';

final findsOneWidget = findsAtLeastNWidgets(1);

void main() {
  testWidgets('renders a labelled triangle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 200,
          child: GeometricRenderer.drawTriangle(
            const Point(20, 160),
            const Point(150, 20),
            const Point(280, 160),
            labels: const {'p1': 'A'},
          ),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('renders a free-body diagram', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 200,
          child:
              GeometricRenderer.drawFreeBodyDiagram(const Point(150, 100), 20, [
                NamedVector(
                  name: 'F',
                  vector: const Vector(magnitude: 30, angleRadians: 0),
                ),
              ]),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
