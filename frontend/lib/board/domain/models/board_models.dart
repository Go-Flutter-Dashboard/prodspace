import 'package:flutter/material.dart';
import 'dart:typed_data'; // Добавлено для Uint8List
import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

enum ToolType {
  pan,
  selection,
  rectangle,
  circle,
  text,
  draw,
  image, // Новый инструмент для добавления изображения
}

enum BoardObjectType { rectangle, circle, text, path, image, err }

@JsonSerializable()
class BoardObject {
  int? id;
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
    this.id,
  });

  static BoardObjectType getType(Map<String, dynamic> json) {
    if (json.containsKey("image")) return BoardObjectType.image;
    if (json.containsKey("text")) return BoardObjectType.text;
    if (json.containsKey("shape")) {
      if (json["shape"]["name"] as String == "rectangle") return BoardObjectType.rectangle;
      if (json["shape"]["name"] as String == "circle") return BoardObjectType.circle;
    }
    return BoardObjectType.err;
  }

  factory BoardObject.fromJson(Map<String, dynamic> json) => BoardObject(
    id: json['id'] as int,
    type: getType(json),
    position: Offset((json["position_x"] as int).toDouble(), (json["position_y"] as int).toDouble()),
    zPos: json["z_index"] as int,
    size: Size((json["width"] as int).toDouble(), (json["height"] as int).toDouble()),
    color: Color(int.parse(json["color"] as String)),
    text: getType(json) == BoardObjectType.text ? json['text']['content'] as String : null,
    imageBytes: getType(json) == BoardObjectType.image ? base64Decode(json['image']['bytes']) : null,
  );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'position_x': position.dx,
      'position_y': position.dy,
      'z_index': zPos,
      'color': color.toARGB32().toString(),
      'width': size.width,
      'height': size.height,
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
        map['shape'] = {"name": "rectangle"};
        if (text != null) {
          map['text'] = {'content': text};
        }
        break;
      case BoardObjectType.circle:
        map['shape'] = {"name": "circle"};
        if (text != null) {
          map['text'] = {'content': text};
        }
        break;
      default:
        break;
    }

    return map;
  }

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

@JsonSerializable()
class DrawPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  int? id;

  DrawPath({required this.points, required this.color, this.strokeWidth = 3, this.id});

  static List<Offset> getPoints(List<dynamic> list) {
    List<Offset> result = [];
    for (int i = 0; i < list.length; i++) {
      result.add(Offset((list[i]['x'] as int).toDouble(), (list[i]['y'] as int).toDouble()));
    }
    return result;
  }

  factory DrawPath.fromJson(Map<String, dynamic> json) => DrawPath(
    id: json['id'] as int,
    points: getPoints(json['drawing']['points']),
    color: Color(int.parse(json["color"] as String)),
    );
  
  Map<String, dynamic> toJson() => {
    'drawing' : {'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList()},
    // 'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
    'color': color.toARGB32().toString(),
    'position_x': 1,
    'position_y': 1,
    'z_index': 1,
  };
}

abstract class BoardItem {
  Map<String, dynamic> toJson();
  void setId(int id);
  int getId();
}

class BoardItemObject extends BoardItem {
  final BoardObject object;
  BoardItemObject(this.object);

  @override
  Map<String, dynamic> toJson() {
    return object.toJson();
  }

  @override
  void setId(int id) {
    object.id = id;
  }

  @override
  int getId() {
    return object.id!;
  }
}

class BoardItemPath extends BoardItem {
  final DrawPath path;
  BoardItemPath(this.path);

  @override
  Map<String, dynamic> toJson() {
    return path.toJson();
  }

  @override
  void setId(int id) {
    path.id = id;
  }

  @override
  int getId() {
    return path.id!;
  }
}

enum BoardItemAction {create, update, delete}

class BoardAction {
  final BoardItem item;
  final BoardItemAction action;
  BoardAction(this.item, this.action);
}