import 'package:flutter/material.dart';

class AppColors {
  // Base
  static const Color background = Color(0xff090909);
  static const Color card = Color(0xff151515);
  static const Color card2 = Color(0xff1E1E1E);

  // Brand
  static const Color primary = Color(0xff4F8CFF);
  static const Color accent = Color(0xff00D2FF);

  // Semantic
  static const Color success = Color(0xff00E676);
  static const Color danger = Color(0xffFF5252);
  static const Color warning = Color(0xffFFC107);
  static const Color info = Color(0xff4F8CFF);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xffB8B8B8);
  static const Color textMuted = Color(0xff777777);

  // Surfaces
  static const Color cardBackground = Color(0xff151515);
  static const Color surfaceLight = Color(0xff1E1E1E);

  // Borders
  static const Color cardBorder = Color(0xff292929);
  static const Color glassBorder = Color(0xff303030);

  // Compatibility aliases
  static const Color secondary = accent;
  static const Color tertiary = success;

  static const Color white = Colors.white;
  static const Color grey = Colors.grey;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      primary,
      accent,
    ],
  );
}