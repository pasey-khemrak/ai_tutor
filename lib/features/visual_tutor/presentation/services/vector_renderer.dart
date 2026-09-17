import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'geometric_renderer.dart';

/// VectorRenderer: Physics-specific vector visualization
///
/// Supports:
/// - Single vectors with magnitude, direction, label, and unit
/// - Vector addition visualization (A + B = R)
/// - Component vectors (Vx, Vy breakdown)
/// - Coordinate systems (Cartesian, tilted for inclines, polar)
/// - Physics units (N for force, m/s for velocity, m/s² for acceleration)
///
/// Performance: <100ms for typical vector diagrams
///
/// Example:
/// ```
/// // Draw force vector: 20N at 30°
/// VectorRenderer.drawVector(
///   Point(100, 100),
///   Vector(magnitude: 20, angleRadians: math.pi / 6),
///   label: 'F',
///   unit: 'N',
///   color: Colors.red,
/// )
/// ```
class VectorRenderer {
  static const double defaultArrowHeadSize = 10.0;
  static const double labelFontSize = 12.0;
  static const double componentLineWidth = 1.5;

  VectorRenderer._(); // Prevent instantiation

  /// Draw a single vector arrow from origin
  ///
  /// Parameters:
  /// - origin: Starting point of the vector
  /// - vector: Direction and magnitude
  /// - color: Color of the arrow
  /// - label: Text label (e.g., "F", "v")
  /// - unit: Unit label (e.g., "N", "m/s")
  /// - arrowHeadSize: Size of arrowhead
  /// - showMagnitude: Whether to show magnitude value
  /// - scale: Pixels per unit magnitude (e.g., 30 means 1 unit = 30px)
  static Widget drawVector(
    Point origin,
    Vector vector, {
    Color color = Colors.red,
    String? label,
    String? unit,
    double arrowHeadSize = defaultArrowHeadSize,
    bool showMagnitude = true,
    double scale = 30.0,
  }) {
    return _VectorPainter(
      shape: _SingleVectorShape(
        origin: origin,
        vector: vector,
        color: color,
        label: label,
        unit: unit,
        arrowHeadSize: arrowHeadSize,
        showMagnitude: showMagnitude,
        scale: scale,
      ),
    );
  }

  /// Draw vector addition: shows how vectors add together
  ///
  /// Demonstrates: A + B = R (resultant)
  /// Visual: Shows tail-to-head vector addition
  static Widget drawVectorAddition(
    List<Vector> vectors,
    Vector resultant, {
    List<Color>? colors,
    List<String>? labels,
    bool showComponents = false,
    double scale = 30.0,
    Point origin = const Point(100, 100),
  }) {
    return _VectorPainter(
      shape: _VectorAdditionShape(
        origin: origin,
        vectors: vectors,
        resultant: resultant,
        colors: colors,
        labels: labels,
        showComponents: showComponents,
        scale: scale,
      ),
    );
  }

  /// Draw component vectors (Vx and Vy breakdown)
  ///
  /// Shows how a vector breaks down into x and y components
  /// Example: 20N at 30° → Vx = 17.3N, Vy = 10N
  static Widget drawComponents(
    Vector vector, {
    bool showX = true,
    bool showY = true,
    Color xColor = Colors.red,
    Color yColor = Colors.blue,
    double scale = 30.0,
    Point origin = const Point(100, 100),
    String? xLabel = 'Vx',
    String? yLabel = 'Vy',
  }) {
    return _VectorPainter(
      shape: _ComponentVectorShape(
        origin: origin,
        vector: vector,
        showX: showX,
        showY: showY,
        xColor: xColor,
        yColor: yColor,
        scale: scale,
        xLabel: xLabel,
        yLabel: yLabel,
      ),
    );
  }

  /// Draw coordinate system (xy-plane, optionally tilted)
  ///
  /// Useful for physics problems on inclined planes
  /// Parameters:
  /// - origin: Center of coordinate system
  /// - xMax/yMax: Range of axes
  /// - rotation: Angle to rotate axes (radians)
  /// - For inclined planes: rotation = angle of incline
  static Widget drawCoordinateSystem(
    Point origin, {
    double xMax = 10.0,
    double yMax = 10.0,
    String? xLabel = 'x',
    String? yLabel = 'y',
    double rotation = 0.0,
    bool showGrid = true,
    Color gridColor = const Color(0xFFE0E0E0),
    Color axisColor = Colors.black,
    double scale = 30.0,
  }) {
    return _VectorPainter(
      shape: _CoordinateSystemShape(
        origin: origin,
        xMax: xMax,
        yMax: yMax,
        xLabel: xLabel,
        yLabel: yLabel,
        rotation: rotation,
        showGrid: showGrid,
        gridColor: gridColor,
        axisColor: axisColor,
        scale: scale,
      ),
    );
  }
}

// ============================================================================
// Internal shape classes (used by painter)
// ============================================================================

abstract class _VectorShape {
  void paint(Canvas canvas, Size size);
  Rect getBounds();
}

/// Single vector visualization
class _SingleVectorShape extends _VectorShape {
  final Point origin;
  final Vector vector;
  final Color color;
  final String? label;
  final String? unit;
  final double arrowHeadSize;
  final bool showMagnitude;
  final double scale;

  _SingleVectorShape({
    required this.origin,
    required this.vector,
    required this.color,
    this.label,
    this.unit,
    required this.arrowHeadSize,
    required this.showMagnitude,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate endpoint
    final scaledMagnitude = vector.magnitude * scale;
    final endX = origin.x + scaledMagnitude * math.cos(vector.angleRadians);
    final endY = origin.y + scaledMagnitude * math.sin(vector.angleRadians);

    // Draw arrow line
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(origin.x, origin.y), Offset(endX, endY), paint);

    // Draw arrowhead
    _drawArrowHead(
      canvas,
      Offset(origin.x, origin.y),
      Offset(endX, endY),
      paint,
    );

    // Draw label
    if (label != null || showMagnitude) {
      final labelOffset = Offset(endX + 15, endY - 10);

      final labelText = showMagnitude
          ? '${label ?? 'V'} = ${vector.magnitude.toStringAsFixed(1)}${unit ?? ''}'
          : label ?? 'V';

      _drawLabel(canvas, labelText, labelOffset);
    }

    // Draw magnitude line (optional, shows actual magnitude)
    if (showMagnitude) {
      _drawMagnitudeLabel(canvas, origin, vector.magnitude, unit);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = (end - start).direction;
    final p1 =
        end +
        Offset(
          -arrowHeadSize * math.cos(angle - math.pi / 6),
          -arrowHeadSize * math.sin(angle - math.pi / 6),
        );
    final p2 =
        end +
        Offset(
          -arrowHeadSize * math.cos(angle + math.pi / 6),
          -arrowHeadSize * math.sin(angle + math.pi / 6),
        );

    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: VectorRenderer.labelFontSize,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  void _drawMagnitudeLabel(
    Canvas canvas,
    Point origin,
    double magnitude,
    String? unit,
  ) {
    // Draw magnitude value at center of vector
    final midX =
        origin.x +
        (vector.magnitude * scale / 2) * math.cos(vector.angleRadians);
    final midY =
        origin.y +
        (vector.magnitude * scale / 2) * math.sin(vector.angleRadians);

    final magnitudeText = '${magnitude.toStringAsFixed(1)} ${unit ?? ''}';

    final textPainter = TextPainter(
      text: TextSpan(
        text: magnitudeText,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, midY - 10));
  }

  @override
  Rect getBounds() {
    final scaledMagnitude = vector.magnitude * scale;
    final endX = origin.x + scaledMagnitude * math.cos(vector.angleRadians);
    final endY = origin.y + scaledMagnitude * math.sin(vector.angleRadians);

    return Rect.fromPoints(
      Offset(origin.x, origin.y),
      Offset(endX, endY),
    ).expandToInclude(Rect.fromCircle(center: Offset(endX, endY), radius: 50));
  }
}

/// Vector addition visualization
class _VectorAdditionShape extends _VectorShape {
  final Point origin;
  final List<Vector> vectors;
  final Vector resultant;
  final List<Color>? colors;
  final List<String>? labels;
  final bool showComponents;
  final double scale;

  _VectorAdditionShape({
    required this.origin,
    required this.vectors,
    required this.resultant,
    this.colors,
    this.labels,
    required this.showComponents,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (vectors.isEmpty) return;

    // Draw vectors tail-to-head
    Offset currentStart = Offset(origin.x, origin.y);

    for (int i = 0; i < vectors.length; i++) {
      final v = vectors[i];
      final color = colors != null && i < colors!.length
          ? colors![i]
          : Colors.blue;
      final label = labels != null && i < labels!.length
          ? labels![i]
          : 'V${i + 1}';

      final scaledMag = v.magnitude * scale;
      final endX = currentStart.dx + scaledMag * math.cos(v.angleRadians);
      final endY = currentStart.dy + scaledMag * math.sin(v.angleRadians);

      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Draw vector
      canvas.drawLine(currentStart, Offset(endX, endY), paint);

      // Draw arrowhead
      final angle = (Offset(endX, endY) - currentStart).direction;
      final p1 =
          Offset(endX, endY) +
          Offset(
            -8 * math.cos(angle - math.pi / 6),
            -8 * math.sin(angle - math.pi / 6),
          );
      final p2 =
          Offset(endX, endY) +
          Offset(
            -8 * math.cos(angle + math.pi / 6),
            -8 * math.sin(angle + math.pi / 6),
          );

      canvas.drawLine(Offset(endX, endY), p1, paint);
      canvas.drawLine(Offset(endX, endY), p2, paint);

      // Draw label
      final labelPaint = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPaint.layout();
      labelPaint.paint(
        canvas,
        Offset(
          (currentStart.dx + endX) / 2 - labelPaint.width / 2,
          (currentStart.dy + endY) / 2 - 15,
        ),
      );

      currentStart = Offset(endX, endY);
    }

    // Draw resultant vector (from origin to final position)
    final resultantScaled = resultant.magnitude * scale;
    final resultantEndX =
        origin.x + resultantScaled * math.cos(resultant.angleRadians);
    final resultantEndY =
        origin.y + resultantScaled * math.sin(resultant.angleRadians);

    final resultantPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(origin.x, origin.y),
      Offset(resultantEndX, resultantEndY),
      resultantPaint,
    );

    // Draw resultant arrowhead
    final resultantAngle =
        (Offset(resultantEndX, resultantEndY) - Offset(origin.x, origin.y))
            .direction;
    final rp1 =
        Offset(resultantEndX, resultantEndY) +
        Offset(
          -10 * math.cos(resultantAngle - math.pi / 6),
          -10 * math.sin(resultantAngle - math.pi / 6),
        );
    final rp2 =
        Offset(resultantEndX, resultantEndY) +
        Offset(
          -10 * math.cos(resultantAngle + math.pi / 6),
          -10 * math.sin(resultantAngle + math.pi / 6),
        );

    canvas.drawLine(Offset(resultantEndX, resultantEndY), rp1, resultantPaint);
    canvas.drawLine(Offset(resultantEndX, resultantEndY), rp2, resultantPaint);

    // Label resultant
    final resultantLabel = TextPainter(
      text: TextSpan(
        text: 'R = ${resultant.magnitude.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 13,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    resultantLabel.layout();
    resultantLabel.paint(
      canvas,
      Offset(resultantEndX + 10, resultantEndY + 10),
    );
  }

  @override
  Rect getBounds() {
    double maxX = origin.x;
    double maxY = origin.y;
    double minX = origin.x;
    double minY = origin.y;

    Offset current = Offset(origin.x, origin.y);
    for (final v in vectors) {
      final scaledMag = v.magnitude * scale;
      final endX = current.dx + scaledMag * math.cos(v.angleRadians);
      final endY = current.dy + scaledMag * math.sin(v.angleRadians);

      maxX = math.max(maxX, endX);
      maxY = math.max(maxY, endY);
      minX = math.min(minX, endX);
      minY = math.min(minY, endY);

      current = Offset(endX, endY);
    }

    final resultantScaled = resultant.magnitude * scale;
    final resultantEndX =
        origin.x + resultantScaled * math.cos(resultant.angleRadians);
    final resultantEndY =
        origin.y + resultantScaled * math.sin(resultant.angleRadians);

    maxX = math.max(maxX, resultantEndX);
    maxY = math.max(maxY, resultantEndY);
    minX = math.min(minX, resultantEndX);
    minY = math.min(minY, resultantEndY);

    return Rect.fromLTRB(minX - 50, minY - 50, maxX + 50, maxY + 50);
  }
}

/// Component vector visualization
class _ComponentVectorShape extends _VectorShape {
  final Point origin;
  final Vector vector;
  final bool showX;
  final bool showY;
  final Color xColor;
  final Color yColor;
  final double scale;
  final String? xLabel;
  final String? yLabel;

  _ComponentVectorShape({
    required this.origin,
    required this.vector,
    required this.showX,
    required this.showY,
    required this.xColor,
    required this.yColor,
    required this.scale,
    this.xLabel,
    this.yLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw main vector (hypotenuse)
    final scaledMag = vector.magnitude * scale;
    final endX = origin.x + scaledMag * math.cos(vector.angleRadians);
    final endY = origin.y + scaledMag * math.sin(vector.angleRadians);

    final mainPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(origin.x, origin.y), Offset(endX, endY), mainPaint);

    // Draw right angle marker
    const markerSize = 10.0;
    final rect = Rect.fromLTWH(
      origin.x,
      endY - markerSize,
      markerSize,
      markerSize,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // Draw X component (horizontal)
    if (showX) {
      final xPaint = Paint()
        ..color = xColor
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(origin.x, origin.y),
        Offset(endX, origin.y),
        xPaint,
      );

      // Label X component
      final vx = vector.vx.abs();
      final labelText = '${xLabel ?? 'Vx'} = ${vx.toStringAsFixed(1)}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            fontSize: 11,
            color: xColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((origin.x + endX) / 2 - textPainter.width / 2, origin.y + 8),
      );
    }

    // Draw Y component (vertical)
    if (showY) {
      final yPaint = Paint()
        ..color = yColor
        ..strokeWidth = 2.0;

      canvas.drawLine(Offset(endX, origin.y), Offset(endX, endY), yPaint);

      // Label Y component
      final vy = vector.vy.abs();
      final labelText = '${yLabel ?? 'Vy'} = ${vy.toStringAsFixed(1)}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            fontSize: 11,
            color: yColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(endX + 8, (origin.y + endY) / 2 - textPainter.height / 2),
      );
    }

    // Label angle
    final angleDeg = (vector.angleRadians * 180 / math.pi).toStringAsFixed(1);
    final angleLabel = TextPainter(
      text: TextSpan(
        text: 'θ = $angleDeg°',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    angleLabel.layout();
    angleLabel.paint(canvas, Offset(origin.x + 20, origin.y - 20));
  }

  @override
  Rect getBounds() {
    final scaledMag = vector.magnitude * scale;
    final endX = origin.x + scaledMag * math.cos(vector.angleRadians);
    final endY = origin.y + scaledMag * math.sin(vector.angleRadians);

    return Rect.fromPoints(
      Offset(origin.x, origin.y),
      Offset(endX, endY),
    ).expandToInclude(Rect.fromCircle(center: Offset(endX, endY), radius: 50));
  }
}

/// Coordinate system visualization
class _CoordinateSystemShape extends _VectorShape {
  final Point origin;
  final double xMax;
  final double yMax;
  final String? xLabel;
  final String? yLabel;
  final double rotation;
  final bool showGrid;
  final Color gridColor;
  final Color axisColor;
  final double scale;

  _CoordinateSystemShape({
    required this.origin,
    required this.xMax,
    required this.yMax,
    this.xLabel,
    this.yLabel,
    required this.rotation,
    required this.showGrid,
    required this.gridColor,
    required this.axisColor,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas);
    }

    // Draw axes
    _drawAxes(canvas);

    // Draw labels
    _drawLabels(canvas);
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final xStep = scale;
    final yStep = scale;

    // Vertical grid lines (parallel to y-axis)
    for (double x = -xMax; x <= xMax; x += 1) {
      if (x == 0) continue; // Skip origin
      final startX = origin.x + x * xStep * math.cos(rotation);
      final startY = origin.y + x * xStep * math.sin(rotation);
      final endX =
          origin.x +
          x * xStep * math.cos(rotation) +
          yMax * scale * math.cos(rotation + math.pi / 2);
      final endY =
          origin.y +
          x * xStep * math.sin(rotation) +
          yMax * scale * math.sin(rotation + math.pi / 2);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Horizontal grid lines (parallel to x-axis)
    for (double y = -yMax; y <= yMax; y += 1) {
      if (y == 0) continue; // Skip origin
      final startX = origin.x + y * yStep * math.cos(rotation + math.pi / 2);
      final startY = origin.y + y * yStep * math.sin(rotation + math.pi / 2);
      final endX =
          origin.x +
          xMax * scale * math.cos(rotation) +
          y * yStep * math.cos(rotation + math.pi / 2);
      final endY =
          origin.y +
          xMax * scale * math.sin(rotation) +
          y * yStep * math.sin(rotation + math.pi / 2);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  void _drawAxes(Canvas canvas) {
    final paint = Paint()
      ..color = axisColor
      ..strokeWidth = 2.0;

    // X-axis
    final xEndX = origin.x + xMax * scale * math.cos(rotation);
    final xEndY = origin.y + xMax * scale * math.sin(rotation);

    canvas.drawLine(Offset(origin.x, origin.y), Offset(xEndX, xEndY), paint);

    // Draw X-axis arrowhead
    const arrowSize = 8.0;
    final xAngle = rotation;
    final xp1 = Offset(
      xEndX - arrowSize * math.cos(xAngle - math.pi / 6),
      xEndY - arrowSize * math.sin(xAngle - math.pi / 6),
    );
    final xp2 = Offset(
      xEndX - arrowSize * math.cos(xAngle + math.pi / 6),
      xEndY - arrowSize * math.sin(xAngle + math.pi / 6),
    );

    canvas.drawLine(Offset(xEndX, xEndY), xp1, paint);
    canvas.drawLine(Offset(xEndX, xEndY), xp2, paint);

    // Y-axis
    final yEndX = origin.x + yMax * scale * math.cos(rotation + math.pi / 2);
    final yEndY = origin.y + yMax * scale * math.sin(rotation + math.pi / 2);

    canvas.drawLine(Offset(origin.x, origin.y), Offset(yEndX, yEndY), paint);

    // Draw Y-axis arrowhead
    final yAngle = rotation + math.pi / 2;
    final yp1 = Offset(
      yEndX - arrowSize * math.cos(yAngle - math.pi / 6),
      yEndY - arrowSize * math.sin(yAngle - math.pi / 6),
    );
    final yp2 = Offset(
      yEndX - arrowSize * math.cos(yAngle + math.pi / 6),
      yEndY - arrowSize * math.sin(yAngle + math.pi / 6),
    );

    canvas.drawLine(Offset(yEndX, yEndY), yp1, paint);
    canvas.drawLine(Offset(yEndX, yEndY), yp2, paint);
  }

  void _drawLabels(Canvas canvas) {
    // X-axis label
    if (xLabel != null) {
      final xEndX = origin.x + xMax * scale * math.cos(rotation);
      final xEndY = origin.y + xMax * scale * math.sin(rotation);

      final textPainter = TextPainter(
        text: TextSpan(
          text: xLabel,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xEndX + 10, xEndY + 10));
    }

    // Y-axis label
    if (yLabel != null) {
      final yEndX = origin.x + yMax * scale * math.cos(rotation + math.pi / 2);
      final yEndY = origin.y + yMax * scale * math.sin(rotation + math.pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: yLabel,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(yEndX - 20, yEndY - 20));
    }
  }

  @override
  Rect getBounds() {
    final xEndX = origin.x + xMax * scale * math.cos(rotation);
    final xEndY = origin.y + xMax * scale * math.sin(rotation);
    final yEndX = origin.x + yMax * scale * math.cos(rotation + math.pi / 2);
    final yEndY = origin.y + yMax * scale * math.sin(rotation + math.pi / 2);

    double minX = origin.x;
    double maxX = origin.x;
    double minY = origin.y;
    double maxY = origin.y;

    minX = math.min(minX, xEndX);
    maxX = math.max(maxX, xEndX);
    minY = math.min(minY, xEndY);
    maxY = math.max(maxY, xEndY);

    minX = math.min(minX, yEndX);
    maxX = math.max(maxX, yEndX);
    minY = math.min(minY, yEndY);
    maxY = math.max(maxY, yEndY);

    return Rect.fromLTRB(minX - 50, minY - 50, maxX + 50, maxY + 50);
  }
}

/// Main painter widget
class _VectorPainter extends StatelessWidget {
  final _VectorShape shape;

  const _VectorPainter({required this.shape});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _VectorCanvasPainter(shape),
      size: Size.infinite,
    );
  }
}

/// Canvas painter for vectors
class _VectorCanvasPainter extends CustomPainter {
  final _VectorShape shape;

  _VectorCanvasPainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    shape.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _VectorCanvasPainter oldDelegate) {
    return oldDelegate.shape != shape;
  }
}
