import 'package:flutter/material.dart';
import 'dart:typed_data'; // Добавлено для Uint8List
import 'dart:convert';

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
  final int zPos;
  final Size size;
  final Color color;
  final String? text;
  final Uint8List? imageBytes; // Добавлено для хранения изображения

  BoardObject({
    required this.type,
    required this.position,
    required this.zPos,
    required this.size,
    required this.color,
    this.text,
    this.imageBytes,
  });

  BoardObject copyWith({Offset? position, int? zPos, Size? size, Color? color, String? text, Uint8List? imageBytes}) {
    return BoardObject(
      type: type,
      position: position ?? this.position,
      zPos: zPos ?? this.zPos,
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

extension DrawPathJson on DrawPath {
  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'color': '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
    'strokeWidth': strokeWidth,
  };
}

extension BoardObjectJson on BoardObject {
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'position_x': position.dx,
      'position_y': position.dy,
      'z_index': zPos,
    };

    switch (type) {
      case BoardObjectType.image:
        if (imageBytes != null) {
          map['image'] = {
            'bytes': base64Encode(imageBytes!),
          };
        }
        break;
      case BoardObjectType.text:
        if (text != null) {
          map['text'] = {'content': text};
        }
        break;
      case BoardObjectType.rectangle:
        map['name'] = 'rectangle';
        map['shape'] = 'rectangle';
        if (text != null) {
          map['text'] = {'content': text};
        }
        break;
      case BoardObjectType.circle:
        map['name'] = 'circle';
        map['shape'] = 'circle';
        if (text != null) {
          map['text'] = {'content': text};
        }
        break;
      default:
        break;
    }

    return map;
  }
} 