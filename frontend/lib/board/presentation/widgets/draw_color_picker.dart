import 'package:flutter/material.dart';
import 'package:prodspace/l10n/app_localizations.dart';
import 'color_picker_dialog.dart';

class DrawColorPicker extends StatelessWidget {
  final Color drawColor;
  final Function(Color) onColorChanged;

  const DrawColorPicker({
    super.key,
    required this.drawColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Text(AppLocalizations.of(context)!.markerColor),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final color = await showDialog<Color>(
                context: context,
                builder: (context) => ColorPickerDialog(initialColor: drawColor),
              );
              if (color != null) onColorChanged(color);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: drawColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 