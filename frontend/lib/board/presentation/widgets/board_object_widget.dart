import 'package:flutter/material.dart';
import '../../domain/models/board_models.dart';
import 'dashed_rect.dart';

enum ResizeDirection { topLeft, topRight, bottomLeft, bottomRight }

class BoardObjectWidget extends StatelessWidget {
  final BoardObject object;
  final bool isSelected;
  final void Function(ResizeDirection direction, DragUpdateDetails details)? onResize;

  const BoardObjectWidget({
    super.key,
    required this.object,
    required this.isSelected,
    this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    
    switch (object.type) {
      case BoardObjectType.rectangle:
        child = Container(
          width: object.size.width,
          height: object.size.height,
          decoration: BoxDecoration(
            color: object.color.withAlpha(179),
            border: Border.all(color: Colors.black54, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        );
        break;
      case BoardObjectType.circle:
        child = Container(
          width: object.size.width,
          height: object.size.height,
          decoration: BoxDecoration(
            color: object.color.withAlpha(179),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black54, width: 2),
          ),
        );
        break;
      case BoardObjectType.text:
        child = Container(
          width: object.size.width,
          height: object.size.height,
          alignment: Alignment.center,
          child: Text(
            object.text ?? '',
            style: TextStyle(
              fontSize: object.size.height * 0.5, // Пропорционально высоте контейнера
              color: object.color, 
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        );
        break;
      case BoardObjectType.image:
        child = object.imageBytes != null
            ? Image.memory(
                object.imageBytes!,
                width: object.size.width,
                height: object.size.height,
                fit: BoxFit.cover,
              )
            : const SizedBox.shrink();
        break;
      default:
        child = const SizedBox.shrink();
    }

    return Stack(
      children: [
        child,
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: DashedRect(
                color: Colors.blue,
                strokeWidth: 2,
                gap: 6,
              ),
            ),
          ),
        if (isSelected)
          ..._buildResizeHandles(object.size),
      ],
    );
  }

  List<Widget> _buildResizeHandles(Size size) {
    const double handleSize = 16;
    return [
      // Top-left
      Positioned(
        left: -handleSize / 2,
        top: -handleSize / 2,
        child: GestureDetector(
          onPanUpdate: (details) => onResize?.call(ResizeDirection.topLeft, details),
          child: _resizeHandle(),
        ),
      ),
      // Top-right
      Positioned(
        right: -handleSize / 2,
        top: -handleSize / 2,
        child: GestureDetector(
          onPanUpdate: (details) => onResize?.call(ResizeDirection.topRight, details),
          child: _resizeHandle(),
        ),
      ),
      // Bottom-left
      Positioned(
        left: -handleSize / 2,
        bottom: -handleSize / 2,
        child: GestureDetector(
          onPanUpdate: (details) => onResize?.call(ResizeDirection.bottomLeft, details),
          child: _resizeHandle(),
        ),
      ),
      // Bottom-right
      Positioned(
        right: -handleSize / 2,
        bottom: -handleSize / 2,
        child: GestureDetector(
          onPanUpdate: (details) => onResize?.call(ResizeDirection.bottomRight, details),
          child: _resizeHandle(),
        ),
      ),
    ];
  }

  Widget _resizeHandle() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue, width: 2),
        shape: BoxShape.circle,
      ),
    );
  }
} 