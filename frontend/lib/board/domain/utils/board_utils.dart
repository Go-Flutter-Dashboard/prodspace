import 'package:flutter/material.dart';
import '../models/board_models.dart';

class BoardUtils {
  static bool isInsideBoard(Offset pos, Size boardSize) {
    return pos.dx >= 0 && pos.dy >= 0 && pos.dx <= boardSize.width && pos.dy <= boardSize.height;
  }

  static Offset screenToBoardCoordinates(Offset screenPos, Offset canvasOffset, double canvasScale) {
    return (screenPos - canvasOffset) / canvasScale;
  }

  static int? findObjectAt(Offset localPoint, List<BoardObject> objects) {
    final transformed = localPoint;
    for (int i = objects.length - 1; i >= 0; i--) {
      final obj = objects[i];
      final r = obj.position & obj.size;
      if (r.contains(transformed)) return i;
    }
    return null;
  }

  static int? findPathAt(Offset localPoint, List<DrawPath> paths, {double threshold = 10}) {
    final transformed = localPoint;
    for (int i = paths.length - 1; i >= 0; i--) {
      if (_isPointNearPath(transformed, paths[i], threshold: threshold)) return i;
    }
    return null;
  }

  static bool _isPointNearPath(Offset point, DrawPath path, {double threshold = 10}) {
    for (int i = 0; i < path.points.length - 1; i++) {
      final p1 = path.points[i];
      final p2 = path.points[i + 1];
      final distance = _distanceToSegment(point, p1, p2);
      if (distance < threshold) return true;
    }
    return false;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ap = p - a;
    final ab = b - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final t = ab2 == 0 ? 0 : (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
    if (t < 0) return ap.distance;
    if (t > 1) return (p - b).distance;
    final proj = a + ab * t.toDouble();
    return (p - proj).distance;
  }

  static Rect boundingBoxForPath(DrawPath path) {
    if (path.points.isEmpty) return Rect.zero;
    double minX = path.points.first.dx.toDouble();
    double minY = path.points.first.dy.toDouble();
    double maxX = path.points.first.dx.toDouble();
    double maxY = path.points.first.dy.toDouble();
    
    for (final p in path.points) {
      if (p.dx < minX) minX = p.dx.toDouble();
      if (p.dy < minY) minY = p.dy.toDouble();
      if (p.dx > maxX) maxX = p.dx.toDouble();
      if (p.dy > maxY) maxY = p.dy.toDouble();
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
} 