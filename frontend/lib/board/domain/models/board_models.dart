import 'package:flutter/material.dart';
import 'dart:typed_data'; // Добавлено для Uint8List

enum ToolType {
  pan,
  selection,
  rectangle,
  circle,
  text,
  draw,
  image, // Новый инструмент для добавления изображения
}

enum BoardObjectType { rectangle, circle, text, path, image }

class BoardObject {
  final BoardObjectType type;
  final Offset position;
  final Size size;
  final Color color;
  final String? text;
  final Uint8List? imageBytes; // Добавлено для хранения изображения

  BoardObject({
    required this.type,
    required this.position,
    required this.size,
    required this.color,
    this.text,
    this.imageBytes,
  });

  BoardObject copyWith({Offset? position, Size? size, Color? color, String? text, Uint8List? imageBytes}) {
    return BoardObject(
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      color: color ?? this.color,
      text: text ?? this.text,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}

class DrawPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawPath(this.points, this.color, this.strokeWidth);
} 