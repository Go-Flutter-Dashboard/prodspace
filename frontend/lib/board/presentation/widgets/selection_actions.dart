import 'package:flutter/material.dart';
import 'package:prodspace/l10n/app_localizations.dart';
import 'color_picker_dialog.dart';

class SelectionActions extends StatelessWidget {
  final VoidCallback onDelete;
  final Color currentColor;
  final Function(Color) onColorChanged;

  const SelectionActions({
    super.key,
    required this.onDelete,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            label: Text(AppLocalizations.of(context)!.delete),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final color = await showDialog<Color>(
                context: context,
                builder: (context) => ColorPickerDialog(initialColor: currentColor),
              );
              if (color != null) onColorChanged(color);
            },
            icon: const Icon(Icons.color_lens),
            label: Text(AppLocalizations.of(context)!.color),
          ),
        ],
      ),
    );
  }
} 