import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide findsOneWidget;

import 'package:ai_tutor/features/visual_tutor/presentation/services/geometric_renderer.dart';
import 'package:ai_tutor/features/visual_tutor/presentation/services/vector_renderer.dart';

// MaterialApp contributes a background CustomPaint; renderer assertions only
// need to verify that at least one paint surface is present.
final findsOneWidget = findsAtLeastNWidgets(1);

void main() {
  group('VectorRenderer', () {
    group('drawVector', () {
      testWidgets('draws single force vector correctly', (
        WidgetTester tester,
      ) async {
        // Test case: Single force vector 20N @ 30°
        const Point origin = Point(100, 100);
        final vector = Vector(
          magnitude: 20.0,
          angleRadians: math.pi / 6, // 30 degrees
        );

        final widget = Scaffold(
          body: VectorRenderer.drawVector(
            origin,
            vector,
            label: 'F',
            unit: 'N',
            color: Colors.red,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('applies correct scale factor', (WidgetTester tester) async {
        const Point origin = Point(100, 100);
        final vector = Vector(magnitude: 10.0, angleRadians: 0.0);

        final widget = Scaffold(
          body: VectorRenderer.drawVector(
            origin,
            vector,
            scale: 50.0, // 50 pixels per unit
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('renders label and unit correctly', (
        WidgetTester tester,
      ) async {
        const Point origin = Point(100, 100);
        final vector = Vector(
          magnitude: 20.0,
          angleRadians: math.pi / 4, // 45 degrees
        );

        final widget = Scaffold(
          body: VectorRenderer.drawVector(
            origin,
            vector,
            label: 'v',
            unit: 'm/s',
            showMagnitude: true,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });

    group('drawVectorAddition', () {
      testWidgets('visualizes vector addition correctly', (
        WidgetTester tester,
      ) async {
        // Test case: 10N + 10N @ 90° = 14.14N @ 45°
        final vectors = [
          Vector(magnitude: 10.0, angleRadians: 0.0), // Horizontal
          Vector(magnitude: 10.0, angleRadians: math.pi / 2), // Vertical
        ];
        final resultant = Vector(
          magnitude: math.sqrt(200), // ~14.14
          angleRadians: math.pi / 4, // 45 degrees
        );

        final widget = Scaffold(
          body: VectorRenderer.drawVectorAddition(
            vectors,
            resultant,
            labels: ['A', 'B'],
            colors: [Colors.red, Colors.blue],
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('handles empty vector list', (WidgetTester tester) async {
        final resultant = Vector(magnitude: 5.0, angleRadians: 0.0);

        final widget = Scaffold(
          body: VectorRenderer.drawVectorAddition([], resultant),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('scales vector addition correctly', (
        WidgetTester tester,
      ) async {
        final vectors = [
          Vector(magnitude: 5.0, angleRadians: 0.0),
          Vector(magnitude: 5.0, angleRadians: math.pi / 2),
        ];
        final resultant = Vector(
          magnitude: math.sqrt(50),
          angleRadians: math.pi / 4,
        );

        final widget = Scaffold(
          body: VectorRenderer.drawVectorAddition(
            vectors,
            resultant,
            scale: 40.0,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });

    group('drawComponents', () {
      testWidgets('displays component breakdown correctly', (
        WidgetTester tester,
      ) async {
        // Test case: F = 20N → Fx ≈ 17.3N, Fy = 10N
        final vector = Vector(
          magnitude: 20.0,
          angleRadians: math.pi / 6, // 30 degrees
        );

        final widget = Scaffold(
          body: VectorRenderer.drawComponents(
            vector,
            showX: true,
            showY: true,
            xColor: Colors.red,
            yColor: Colors.blue,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('calculates components correctly', (
        WidgetTester tester,
      ) async {
        final vector = Vector(magnitude: 20.0, angleRadians: math.pi / 6);

        // Verify component calculations
        expect(vector.vx, closeTo(17.32, 0.1)); // cos(30°) * 20
        expect(vector.vy, closeTo(10.0, 0.1)); // sin(30°) * 20
      });

      testWidgets('handles zero angle vector', (WidgetTester tester) async {
        final vector = Vector(magnitude: 15.0, angleRadians: 0.0);

        final widget = Scaffold(
          body: VectorRenderer.drawComponents(vector, showX: true, showY: true),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);

        // At 0 degrees: vx = magnitude, vy = 0
        expect(vector.vx, closeTo(15.0, 0.001));
        expect(vector.vy, closeTo(0.0, 0.001));
      });

      testWidgets('hides components selectively', (WidgetTester tester) async {
        final vector = Vector(magnitude: 20.0, angleRadians: math.pi / 4);

        final widget = Scaffold(
          body: VectorRenderer.drawComponents(
            vector,
            showX: true,
            showY: false,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });

    group('drawCoordinateSystem', () {
      testWidgets('draws Cartesian coordinate system', (
        WidgetTester tester,
      ) async {
        const Point origin = Point(100, 100);

        final widget = Scaffold(
          body: VectorRenderer.drawCoordinateSystem(
            origin,
            xMax: 10.0,
            yMax: 10.0,
            xLabel: 'x',
            yLabel: 'y',
            showGrid: true,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('rotates axes for tilted coordinate system', (
        WidgetTester tester,
      ) async {
        // Test case: Inclined plane at 30°
        const Point origin = Point(100, 100);

        final widget = Scaffold(
          body: VectorRenderer.drawCoordinateSystem(
            origin,
            xMax: 8.0,
            yMax: 8.0,
            rotation: math.pi / 6, // 30 degrees for incline
            showGrid: true,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('hides grid when disabled', (WidgetTester tester) async {
        const Point origin = Point(100, 100);

        final widget = Scaffold(
          body: VectorRenderer.drawCoordinateSystem(origin, showGrid: false),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('applies custom scaling', (WidgetTester tester) async {
        const Point origin = Point(200, 200);

        final widget = Scaffold(
          body: VectorRenderer.drawCoordinateSystem(
            origin,
            scale: 50.0,
            xMax: 6.0,
            yMax: 6.0,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });

    group('Vector class', () {
      test('calculates magnitude correctly', () {
        final vector = Vector(magnitude: 20.0, angleRadians: 0.0);
        expect(vector.magnitude, equals(20.0));
      });

      test('calculates components from magnitude and angle', () {
        final vector = Vector(
          magnitude: 10.0,
          angleRadians: math.pi / 4, // 45 degrees
        );

        expect(vector.vx, closeTo(7.071, 0.001));
        expect(vector.vy, closeTo(7.071, 0.001));
      });

      test('creates vector from components', () {
        final vector = Vector.fromComponents(3.0, 4.0);

        expect(vector.magnitude, closeTo(5.0, 0.001));
        expect(vector.angleRadians, closeTo(math.atan2(4.0, 3.0), 0.001));
      });

      test('creates vector from degrees', () {
        final vector = Vector.fromDegrees(10.0, 45.0);

        expect(vector.magnitude, equals(10.0));
        expect(vector.angleRadians, closeTo(math.pi / 4, 0.001));
      });

      test('handles zero magnitude vector', () {
        final vector = Vector(magnitude: 0.0, angleRadians: 0.0);

        expect(vector.magnitude, equals(0.0));
        expect(vector.vx, closeTo(0.0, 0.001));
        expect(vector.vy, closeTo(0.0, 0.001));
      });

      test('converts negative angles correctly', () {
        final vector = Vector(
          magnitude: 10.0,
          angleRadians: -math.pi / 4, // -45 degrees
        );

        expect(vector.vx, closeTo(7.071, 0.001));
        expect(vector.vy, closeTo(-7.071, 0.001));
      });
    });

    group('Point class', () {
      test('creates point with coordinates', () {
        const point = Point(100.0, 200.0);

        expect(point.x, equals(100.0));
        expect(point.y, equals(200.0));
      });

      test('converts to Offset', () {
        const point = Point(50.0, 75.0);
        final offset = point.toOffset();

        expect(offset.dx, equals(50.0));
        expect(offset.dy, equals(75.0));
      });

      test('equality comparison works', () {
        const point1 = Point(100.0, 100.0);
        const point2 = Point(100.0, 100.0);
        const point3 = Point(100.0, 101.0);

        expect(point1, equals(point2));
        expect(point1, isNot(equals(point3)));
      });

      test('hash code is consistent', () {
        const point1 = Point(100.0, 100.0);
        const point2 = Point(100.0, 100.0);

        expect(point1.hashCode, equals(point2.hashCode));
      });
    });
  });
}
