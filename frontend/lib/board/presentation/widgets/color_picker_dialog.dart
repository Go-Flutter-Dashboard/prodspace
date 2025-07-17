import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:prodspace/l10n/app_localizations.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  
  const ColorPickerDialog({super.key, required this.initialColor});
  
  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _color;
  
  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.chooseColor),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: _color,
          onColorChanged: (c) => setState(() => _color = c),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('OK'),
        ),
      ],
    );
  }
} 