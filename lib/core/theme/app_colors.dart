import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Charte Orange
  static const Color primary = Color(0xFFFF7900);
  static const Color black = Color(0xFF000000);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF242424);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFFB0B0B0);

  // Accents fonctionnels
  static const Color success = Color(0xFF32C832);
  static const Color warning = Color(0xFFFFB400);
  static const Color danger = Color(0xFFCD3C14);
  static const Color info = Color(0xFF4BB4E6);

  // Anciennes valeurs conservées pour compat
  static const Color firstLineaColor = Color(0xFFFF7900);
  static const Color secondLineaColor = Color(0xFFFF7900);
  static const Color thirdLineaColor = Color(0xFFFF7900);

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF7900), Color(0xFFFF7900)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
