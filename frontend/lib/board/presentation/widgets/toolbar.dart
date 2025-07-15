import 'package:flutter/material.dart';
import '../../domain/models/board_models.dart';
import 'color_picker_dialog.dart';

class Toolbar extends StatelessWidget {
  final ToolType selectedTool;
  final Function(ToolType) onToolSelected;
  final Color rectColor;
  final Color circleColor;
  final Color textColor;
  final Function(Color) onRectColorChanged;
  final Function(Color) onCircleColorChanged;
  final Function(Color) onTextColorChanged;

  const Toolbar({
    Key? key,
    required this.selectedTool,
    required this.onToolSelected,
    required this.rectColor,
    required this.circleColor,
    required this.textColor,
    required this.onRectColorChanged,
    required this.onCircleColorChanged,
    required this.onTextColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toolButton(Icons.pan_tool, ToolType.pan, 'Навигация'),
          const SizedBox(width: 8),
          _toolButton(Icons.mouse, ToolType.selection, 'Выделение'),
          const SizedBox(width: 8),
          _toolButton(Icons.crop_square, ToolType.rectangle, 'Прямоугольник'),
          _colorPickerButton(rectColor, () async {
            final color = await showDialog<Color>(
              context: context,
              builder: (context) => ColorPickerDialog(initialColor: rectColor),
            );
            if (color != null) onRectColorChanged(color);
          }),
          const SizedBox(width: 8),
          _toolButton(Icons.circle, ToolType.circle, 'Круг'),
          _colorPickerButton(circleColor, () async {
            final color = await showDialog<Color>(
              context: context,
              builder: (context) => ColorPickerDialog(initialColor: circleColor),
            );
            if (color != null) onCircleColorChanged(color);
          }),
          const SizedBox(width: 8),
          _toolButton(Icons.text_fields, ToolType.text, 'Текст'),
          _colorPickerButton(textColor, () async {
            final color = await showDialog<Color>(
              context: context,
              builder: (context) => ColorPickerDialog(initialColor: textColor),
            );
            if (color != null) onTextColorChanged(color);
          }),
          const SizedBox(width: 8),
          _toolButton(Icons.edit, ToolType.draw, 'Рисование'),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, ToolType tool, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedTool == tool ? Colors.blue : Colors.grey[300],
          foregroundColor: selectedTool == tool ? Colors.white : Colors.black,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(14),
        ),
        onPressed: () => onToolSelected(tool),
        child: Icon(icon, size: 28),
      ),
    );
  }

  Widget _colorPickerButton(Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26, width: 2),
          ),
        ),
      ),
    );
  }
} 