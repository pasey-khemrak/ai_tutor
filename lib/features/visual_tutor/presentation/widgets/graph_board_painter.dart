import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../visual_tutor_design.dart';

class GraphBoardPainter extends CustomPainter {
  const GraphBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = VisualTutorColors.blackInk.withValues(alpha: .82)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final curvePaint = Paint()
      ..color = VisualTutorColors.blueInk
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = VisualTutorColors.cyan;

    final origin = Offset(size.width * .5, size.height * .52);
    canvas.drawLine(
      Offset(size.width * .12, origin.dy),
      Offset(size.width * .9, origin.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(origin.dx, size.height * .12),
      Offset(origin.dx, size.height * .88),
      axisPaint,
    );

    final path = Path();
    for (var i = 0; i <= 96; i++) {
      final t = i / 96;
      final x = size.width * (.12 + t * .74);
      final y = origin.dy - math.sin(t * math.pi * 2) * size.height * .16;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, curvePaint);

    final point = Offset(size.width * .56, origin.dy);
    canvas.drawCircle(point, 7, pointPaint);
    canvas.drawCircle(
      point,
      7,
      Paint()
        ..color = VisualTutorColors.blackInk
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant GraphBoardPainter oldDelegate) => false;
}
