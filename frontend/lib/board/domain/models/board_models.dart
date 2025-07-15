import 'package:flutter/material.dart';

enum ToolType { pan, selection, rectangle, circle, text, draw }

enum BoardObjectType { rectangle, circle, text, path }

class BoardObject {
  final BoardObjectType type;
  final Offset position;
  final Size size;
  final Color color;
  final String? text;

  BoardObject({
    required this.type,
    required this.position,
    required this.size,
    required this.color,
    this.text,
  });

  BoardObject copyWith({Offset? position, Size? size, Color? color, String? text}) {
    return BoardObject(
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      color: color ?? this.color,
      text: text ?? this.text,
    );
  }
}

class DrawPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawPath(this.points, this.color, this.strokeWidth);
} 