import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F7FA),
      cardTheme: const CardThemeData(elevation: 0, color: Colors.white, surfaceTintColor: Colors.white),
    );
  }
}
