import 'package:flutter/material.dart';
import 'dart:math';

class DashedRect extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double? width;
  final double? height;
  
  const DashedRect({
    super.key, 
    this.color = Colors.blue, 
    this.strokeWidth = 2, 
    this.gap = 5, 
    this.width, 
    this.height
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: color, 
          strokeWidth: strokeWidth, 
          gap: gap
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  
  _DashedRectPainter({
    required this.color, 
    required this.strokeWidth, 
    required this.gap
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
      
    _drawDashedLine(canvas, Offset(0, 0), Offset(size.width, 0), paint); // top
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(size.width, size.height), paint); // right
    _drawDashedLine(canvas, Offset(size.width, size.height), Offset(0, size.height), paint); // bottom
    _drawDashedLine(canvas, Offset(0, size.height), Offset(0, 0), paint); // left
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 8;
    double totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    double drawn = 0;
    
    while (drawn < totalLength) {
      final currentStart = start + direction * drawn;
      final currentEnd = start + direction * min(drawn + dashWidth, totalLength);
      canvas.drawLine(currentStart, currentEnd, paint);
      drawn += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 