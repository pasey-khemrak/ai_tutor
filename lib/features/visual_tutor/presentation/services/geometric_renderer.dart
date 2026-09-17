import 'dart:math' as math;

import 'package:flutter/material.dart';

/// GeometricRenderer: Renders geometric shapes and diagrams
///
/// Supports:
/// - Triangles (right, equilateral, isosceles, arbitrary)
/// - Circles (with radius, center point)
/// - Rectangles and squares
/// - Polygons (any number of vertices)
/// - Free body diagrams (object with force vectors)
/// - Angle marking and labels
/// - Vertex labels and annotations
///
/// Example:
/// ```
/// GeometricRenderer.drawTriangle(
///   Point(0, 0),
///   Point(3, 0),
///   Point(3, 4),
///   fillColor: Colors.blue.withOpacity(0.2),
///   labels: {'p1': 'A', 'p2': 'B', 'p3': 'C'},
///   rightAngle: true,
/// )
/// ```
class GeometricRenderer {
  static const double defaultLineWidth = 2.0;
  static const double labelFontSize = 14.0;
  static const double vertexRadius = 4.0;

  GeometricRenderer._(); // Prevent instantiation

  /// Draw a triangle given three vertices
  static Widget drawTriangle(
    Point p1,
    Point p2,
    Point p3, {
    Color? fillColor,
    Color strokeColor = Colors.black,
    double strokeWidth = defaultLineWidth,
    Map<String, String>? labels, // e.g., {'p1': 'A', 'p2': 'B', 'p3': 'C'}
    bool rightAngle = false,
    String? rightAngleVertex, // 'p1', 'p2', or 'p3'
  }) {
    return _GeometricPainter(
      shape: _TriangleShape(
        p1: p1,
        p2: p2,
        p3: p3,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        labels: labels,
        rightAngle: rightAngle,
        rightAngleVertex: rightAngleVertex,
      ),
    );
  }

  /// Draw a circle given center and radius
  static Widget drawCircle(
    Point center,
    double radius, {
    Color? fillColor,
    Color strokeColor = Colors.black,
    double strokeWidth = defaultLineWidth,
    String? label,
    bool showRadius = false,
    bool showCenter = true,
  }) {
    return _GeometricPainter(
      shape: _CircleShape(
        center: center,
        radius: radius,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        label: label,
        showRadius: showRadius,
        showCenter: showCenter,
      ),
    );
  }

  /// Draw a rectangle
  static Widget drawRectangle(
    Point topLeft,
    double width,
    double height, {
    Color? fillColor,
    Color strokeColor = Colors.black,
    double strokeWidth = defaultLineWidth,
    String? label,
  }) {
    return _GeometricPainter(
      shape: _RectangleShape(
        topLeft: topLeft,
        width: width,
        height: height,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        label: label,
      ),
    );
  }

  /// Draw an arbitrary polygon
  static Widget drawPolygon(
    List<Point> vertices, {
    Color? fillColor,
    Color strokeColor = Colors.black,
    double strokeWidth = defaultLineWidth,
    Map<String, String>? labels,
  }) {
    return _GeometricPainter(
      shape: _PolygonShape(
        vertices: vertices,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
        labels: labels,
      ),
    );
  }

  /// Draw a free body diagram: object with force vectors
  static Widget drawFreeBodybody(
    Point objectCenter,
    double objectRadius,
    List<NamedVector> forces, {
    String? objectLabel,
    double forceScale = 1.0,
    bool showMagnitudes = true,
    Color objectColor = Colors.grey,
    Color forceColor = Colors.red,
  }) {
    return _GeometricPainter(
      shape: _FreeBodbyShape(
        objectCenter: objectCenter,
        objectRadius: objectRadius,
        forces: forces,
        objectLabel: objectLabel,
        forceScale: forceScale,
        showMagnitudes: showMagnitudes,
        objectColor: objectColor,
        forceColor: forceColor,
      ),
    );
  }

  /// Draw a free-body diagram with the correctly spelled public API.
  static Widget drawFreeBodyDiagram(
    Point objectCenter,
    double objectRadius,
    List<NamedVector> forces, {
    String? objectLabel,
    double forceScale = 1.0,
    bool showMagnitudes = true,
    Color objectColor = Colors.grey,
    Color forceColor = Colors.red,
  }) => drawFreeBodybody(
    objectCenter,
    objectRadius,
    forces,
    objectLabel: objectLabel,
    forceScale: forceScale,
    showMagnitudes: showMagnitudes,
    objectColor: objectColor,
    forceColor: forceColor,
  );

  /// Draw an angle with arc and label
  static Widget drawAngle(
    Point vertex,
    Vector vector1,
    Vector vector2, {
    bool showArc = true,
    String? label,
    Color arcColor = Colors.blue,
    double arcRadius = 30.0,
  }) {
    return _GeometricPainter(
      shape: _AngleShape(
        vertex: vertex,
        vector1: vector1,
        vector2: vector2,
        showArc: showArc,
        label: label,
        arcColor: arcColor,
        arcRadius: arcRadius,
      ),
    );
  }
}

/// Represents a 2D point
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  Offset toOffset() => Offset(x, y);

  @override
  String toString() => 'Point($x, $y)';

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Represents a vector (direction and magnitude)
class Vector {
  final double magnitude;
  final double angleRadians;

  const Vector({required this.magnitude, required this.angleRadians});

  double get vx => magnitude * math.cos(angleRadians);
  double get vy => magnitude * math.sin(angleRadians);

  /// Create vector from components
  factory Vector.fromComponents(double vx, double vy) {
    final magnitude = math.sqrt(vx * vx + vy * vy);
    final angle = math.atan2(vy, vx);
    return Vector(magnitude: magnitude, angleRadians: angle);
  }

  /// Create vector from angle in degrees
  factory Vector.fromDegrees(double magnitude, double angleDegrees) {
    return Vector(
      magnitude: magnitude,
      angleRadians: angleDegrees * math.pi / 180,
    );
  }

  @override
  String toString() => 'Vector(mag: $magnitude, angle: $angleRadians)';
}

/// Named vector with label and unit
class NamedVector {
  final String name; // e.g., 'F', 'v', 'a'
  final Vector vector;
  final String? unit; // e.g., 'N', 'm/s', 'm/s²'
  final Color color;

  NamedVector({
    required this.name,
    required this.vector,
    this.unit,
    this.color = Colors.red,
  });

  @override
  String toString() => 'NamedVector($name, $vector $unit)';
}

// ============================================================================
// Internal shape classes (used by painter)
// ============================================================================

abstract class _GeometricShape {
  void paint(Canvas canvas, Size size);
  Rect getBounds();
}

class _TriangleShape extends _GeometricShape {
  final Point p1, p2, p3;
  final Color? fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final Map<String, String>? labels;
  final bool rightAngle;
  final String? rightAngleVertex;

  _TriangleShape({
    required this.p1,
    required this.p2,
    required this.p3,
    this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    this.labels,
    this.rightAngle = false,
    this.rightAngleVertex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor ?? Colors.transparent
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(p1.x, p1.y)
      ..lineTo(p2.x, p2.y)
      ..lineTo(p3.x, p3.y)
      ..close();

    if (fillColor != null) {
      canvas.drawPath(path, fillPaint);
    }
    canvas.drawPath(path, paint);

    // Draw vertices
    _drawVertex(canvas, p1);
    _drawVertex(canvas, p2);
    _drawVertex(canvas, p3);

    // Draw labels
    if (labels != null) {
      _drawLabel(canvas, p1, labels!['p1']);
      _drawLabel(canvas, p2, labels!['p2']);
      _drawLabel(canvas, p3, labels!['p3']);
    }

    // Draw right angle marker if specified
    if (rightAngle && rightAngleVertex != null) {
      _drawRightAngleMarker(canvas);
    }
  }

  void _drawVertex(Canvas canvas, Point p) {
    canvas.drawCircle(
      Offset(p.x, p.y),
      GeometricRenderer.vertexRadius,
      Paint()..color = Colors.black,
    );
  }

  void _drawLabel(Canvas canvas, Point p, String? label) {
    if (label == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: GeometricRenderer.labelFontSize,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(canvas, Offset(p.x + 10, p.y + 10));
  }

  void _drawRightAngleMarker(Canvas canvas) {
    // Draw small square at right angle vertex
    const size = 15.0;
    Point vertex = p1;

    if (rightAngleVertex == 'p2') {
      vertex = p2;
    } else if (rightAngleVertex == 'p3') {
      vertex = p3;
    }

    // This is simplified - a proper implementation would
    // calculate the angle and draw accordingly
    final rect = Rect.fromLTWH(vertex.x, vertex.y, size, size);
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  Rect getBounds() {
    double minX = math.min(p1.x, math.min(p2.x, p3.x));
    double maxX = math.max(p1.x, math.max(p2.x, p3.x));
    double minY = math.min(p1.y, math.min(p2.y, p3.y));
    double maxY = math.max(p1.y, math.max(p2.y, p3.y));
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class _CircleShape extends _GeometricShape {
  final Point center;
  final double radius;
  final Color? fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final String? label;
  final bool showRadius;
  final bool showCenter;

  _CircleShape({
    required this.center,
    required this.radius,
    this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    this.label,
    this.showRadius = false,
    this.showCenter = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor ?? Colors.transparent
      ..style = PaintingStyle.fill;

    final offset = Offset(center.x, center.y);

    if (fillColor != null) {
      canvas.drawCircle(offset, radius, fillPaint);
    }
    canvas.drawCircle(offset, radius, paint);

    // Draw center point
    if (showCenter) {
      canvas.drawCircle(
        offset,
        GeometricRenderer.vertexRadius,
        Paint()..color = Colors.black,
      );
    }

    // Draw radius line
    if (showRadius) {
      canvas.drawLine(
        offset,
        Offset(center.x + radius, center.y),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1.5,
      );

      // Draw radius label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'r = ${radius.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.x + radius / 2 + 5, center.y - 10),
      );
    }

    // Draw label
    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: GeometricRenderer.labelFontSize,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(center.x + radius + 10, center.y));
    }
  }

  @override
  Rect getBounds() {
    return Rect.fromCircle(center: center.toOffset(), radius: radius);
  }
}

class _RectangleShape extends _GeometricShape {
  final Point topLeft;
  final double width;
  final double height;
  final Color? fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final String? label;

  _RectangleShape({
    required this.topLeft,
    required this.width,
    required this.height,
    this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(topLeft.x, topLeft.y, width, height);

    final fillPaint = Paint()
      ..color = fillColor ?? Colors.transparent
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (fillColor != null) {
      canvas.drawRect(rect, fillPaint);
    }
    canvas.drawRect(rect, strokePaint);

    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: GeometricRenderer.labelFontSize,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(topLeft.x + width / 2 - textPainter.width / 2, topLeft.y - 20),
      );
    }
  }

  @override
  Rect getBounds() => Rect.fromLTWH(topLeft.x, topLeft.y, width, height);
}

class _PolygonShape extends _GeometricShape {
  final List<Point> vertices;
  final Color? fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final Map<String, String>? labels;

  _PolygonShape({
    required this.vertices,
    this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (vertices.isEmpty) return;

    final path = Path()..moveTo(vertices[0].x, vertices[0].y);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].x, vertices[i].y);
    }
    path.close();

    final fillPaint = Paint()
      ..color = fillColor ?? Colors.transparent
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (fillColor != null) {
      canvas.drawPath(path, fillPaint);
    }
    canvas.drawPath(path, strokePaint);

    // Draw vertices and any matching indexed labels (p1, p2, ...).
    for (var index = 0; index < vertices.length; index++) {
      final vertex = vertices[index];
      canvas.drawCircle(
        vertex.toOffset(),
        GeometricRenderer.vertexRadius,
        Paint()..color = Colors.black,
      );
      final label = labels?['p${index + 1}'];
      if (label != null) {
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: GeometricRenderer.labelFontSize),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(canvas, Offset(vertex.x + 8, vertex.y - text.height - 4));
      }
    }
  }

  @override
  Rect getBounds() {
    if (vertices.isEmpty) return Rect.zero;

    double minX = vertices[0].x;
    double maxX = vertices[0].x;
    double minY = vertices[0].y;
    double maxY = vertices[0].y;

    for (final v in vertices) {
      minX = math.min(minX, v.x);
      maxX = math.max(maxX, v.x);
      minY = math.min(minY, v.y);
      maxY = math.max(maxY, v.y);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class _FreeBodbyShape extends _GeometricShape {
  final Point objectCenter;
  final double objectRadius;
  final List<NamedVector> forces;
  final String? objectLabel;
  final double forceScale;
  final bool showMagnitudes;
  final Color objectColor;
  final Color forceColor;

  _FreeBodbyShape({
    required this.objectCenter,
    required this.objectRadius,
    required this.forces,
    this.objectLabel,
    this.forceScale = 1.0,
    this.showMagnitudes = true,
    this.objectColor = Colors.grey,
    this.forceColor = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw object (circle or box)
    canvas.drawCircle(
      objectCenter.toOffset(),
      objectRadius,
      Paint()
        ..color = objectColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      objectCenter.toOffset(),
      objectRadius,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Draw forces as vectors
    for (final namedVector in forces) {
      _drawForceVector(canvas, namedVector);
    }

    // Draw label if provided
    if (objectLabel != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: objectLabel,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(objectCenter.x - textPainter.width / 2, objectCenter.y - 20),
      );
    }
  }

  void _drawForceVector(Canvas canvas, NamedVector namedVector) {
    final v = namedVector.vector;
    final scaledMagnitude = v.magnitude * forceScale * 30; // 30 pixels per unit

    // Calculate endpoint
    final endX = objectCenter.x + scaledMagnitude * math.cos(v.angleRadians);
    final endY = objectCenter.y + scaledMagnitude * math.sin(v.angleRadians);

    // Draw arrow
    final paint = Paint()
      ..color = namedVector.color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(objectCenter.toOffset(), Offset(endX, endY), paint);

    // Draw arrowhead
    const arrowSize = 10.0;
    final angle = v.angleRadians;

    final p1 = Offset(
      endX - arrowSize * math.cos(angle - math.pi / 6),
      endY - arrowSize * math.sin(angle - math.pi / 6),
    );
    final p2 = Offset(
      endX - arrowSize * math.cos(angle + math.pi / 6),
      endY - arrowSize * math.sin(angle + math.pi / 6),
    );

    canvas.drawLine(Offset(endX, endY), p1, paint);
    canvas.drawLine(Offset(endX, endY), p2, paint);

    // Draw label
    final labelOffset = Offset(endX + 10, endY - 10);

    final text = showMagnitudes
        ? '${namedVector.name} = ${v.magnitude.toStringAsFixed(1)} ${namedVector.unit ?? ''}'
        : namedVector.name;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 12, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, labelOffset);
  }

  @override
  Rect getBounds() {
    double maxForceLength = 0;
    for (final f in forces) {
      maxForceLength = math.max(
        maxForceLength,
        f.vector.magnitude * forceScale * 30,
      );
    }

    return Rect.fromCircle(
      center: objectCenter.toOffset(),
      radius: objectRadius + maxForceLength + 50,
    );
  }
}

class _AngleShape extends _GeometricShape {
  final Point vertex;
  final Vector vector1;
  final Vector vector2;
  final bool showArc;
  final String? label;
  final Color arcColor;
  final double arcRadius;

  _AngleShape({
    required this.vertex,
    required this.vector1,
    required this.vector2,
    this.showArc = true,
    this.label,
    this.arcColor = Colors.blue,
    this.arcRadius = 30.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw vector lines
    final v1End = Offset(
      vertex.x + 100 * math.cos(vector1.angleRadians),
      vertex.y + 100 * math.sin(vector1.angleRadians),
    );
    final v2End = Offset(
      vertex.x + 100 * math.cos(vector2.angleRadians),
      vertex.y + 100 * math.sin(vector2.angleRadians),
    );

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    canvas.drawLine(vertex.toOffset(), v1End, paint);
    canvas.drawLine(vertex.toOffset(), v2End, paint);

    // Draw arc
    if (showArc) {
      _drawAngleArc(canvas);
    }

    // Draw label
    if (label != null) {
      final midAngle = (vector1.angleRadians + vector2.angleRadians) / 2;
      final labelOffset = Offset(
        vertex.x + (arcRadius + 20) * math.cos(midAngle),
        vertex.y + (arcRadius + 20) * math.sin(midAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, labelOffset);
    }
  }

  void _drawAngleArc(Canvas canvas) {
    final rect = Rect.fromCircle(center: vertex.toOffset(), radius: arcRadius);

    final paint = Paint()
      ..color = arcColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      rect,
      vector1.angleRadians,
      vector2.angleRadians - vector1.angleRadians,
      false,
      paint,
    );
  }

  @override
  Rect getBounds() {
    return Rect.fromCircle(center: vertex.toOffset(), radius: arcRadius + 50);
  }
}

/// Main painter widget
class _GeometricPainter extends StatelessWidget {
  final _GeometricShape shape;

  const _GeometricPainter({required this.shape});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GeometricCanvasPainter(shape),
      size: Size.infinite,
    );
  }
}

/// Canvas painter for shapes
class _GeometricCanvasPainter extends CustomPainter {
  final _GeometricShape shape;

  _GeometricCanvasPainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    shape.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _GeometricCanvasPainter oldDelegate) {
    return oldDelegate.shape != shape;
  }
}
