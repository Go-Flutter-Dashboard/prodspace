import 'package:flutter/material.dart';
import 'dart:ui';
import '../../domain/models/board_models.dart';

class BoardPainter extends CustomPainter {
  final List<DrawPath> paths;
  
  BoardPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
        
      if (path.points.length > 1) {
        for (int i = 0; i < path.points.length - 1; i++) {
          canvas.drawLine(path.points[i], path.points[i + 1], paint);
        }
      } else if (path.points.isNotEmpty) {
        canvas.drawPoints(PointMode.points, path.points, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
} 