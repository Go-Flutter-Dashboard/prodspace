import 'package:flutter/material.dart';

Widget settingsButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(Icons.settings, size: 28),
      color: colorScheme.onTertiary,
      tooltip: "Settings",
      onPressed: () => Navigator.pushNamed(context, '/settings'),
    );
  }