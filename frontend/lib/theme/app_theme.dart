import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
    secondary: Colors.amber,
  ),
  useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
      secondary: Colors.amber,
    ),
    useMaterial3: true,
  );

  static ThemeMode thememode = ThemeMode.system;
}