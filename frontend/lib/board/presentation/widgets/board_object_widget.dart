import 'package:flutter/material.dart';
import '../../domain/models/board_models.dart';
import 'dashed_rect.dart';

class BoardObjectWidget extends StatelessWidget {
  final BoardObject object;
  final bool isSelected;

  const BoardObjectWidget({
    Key? key,
    required this.object,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;
    
    switch (object.type) {
      case BoardObjectType.rectangle:
        child = Container(
          width: object.size.width,
          height: object.size.height,
          decoration: BoxDecoration(
            color: object.color.withOpacity(0.7),
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
            color: object.color.withOpacity(0.7),
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
              fontSize: 20, 
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
      ],
    );
  }
} 