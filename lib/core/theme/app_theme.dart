import 'package:flutter/material.dart';

class AppTheme {
  static const terracotta = Color(0xFFD9684F);
  static const deepOrange = Color(0xFFB84F38);
  static const peach = Color(0xFFF2A07E);
  static const cream = Color(0xFFFAF4EA);
  static const warmCharcoal = Color(0xFF2B2623);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: terracotta,
      brightness: Brightness.light,
      surface: cream,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: terracotta,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: peach,
      brightness: Brightness.dark,
      surface: warmCharcoal,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF211D1B),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
