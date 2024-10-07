import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF111827); // bg-gray-900
  static const Color surface = Color(0xFF1F2937); // bg-gray-800
  static const Color primary = Color(0xFF8B5CF6); // text-purple-500
  static const Color onPrimary = Color(0xFFFFFFFF); // text-white
  static const Color secondary = Color(0xFF4B5563); // text-gray-600
  static const Color onSecondary = Color(0xFFE5E7EB); // text-gray-200
  static const Color accent =
      Color(0xFFEF4444); // text-red-500 (para icono de corazón en Favoritos)
  static const Color text = Color(0xFFFFFFFF); // text-white
  static const Color textSecondary = Color(0xFF9CA3AF); // text-gray-400

  static const List<Color> colorList = [
    background,
    surface,
    primary,
    onPrimary,
    secondary,
    onSecondary,
    accent,
    text,
    textSecondary,
  ];
  ThemeData themedata() {
    return ThemeData(
        brightness: Brightness.dark, colorSchemeSeed: colorList[2]);
  }
}
