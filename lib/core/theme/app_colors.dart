import 'package:flutter/material.dart';

/// Application color palette - Banking App Design System
class AppColors {
  AppColors._();

  // PRIMARY COLORS (Sage & Tan Theme)
  static const Color primary = Color(0xFF5D866C); // Sage Green
  static const Color primaryVariant1 = Color(0xFF7A9D88); // Light Sage
  static const Color primaryVariant2 = Color(0xFFC2A68C); // Medium Tan
  static const Color primaryVariant3 = Color(0xFFE6D8C3); // Light Beige

  // NEUTRAL COLORS
  static const Color neutral900 = Color(0xFF343434); // Darkest
  static const Color neutral700 = Color(0xFF898989);
  static const Color neutral600 = Color(0xFF989898);
  static const Color neutral400 = Color(0xFFCACACA);
  static const Color neutral200 = Color(0xFFE0E0E0);
  static const Color neutral100 = Color(0xFFFFFFFF); // White

  // SEMANTIC COLORS
  static const Color error = Color(0xFFFF4267); // Red
  static const Color info = Color(0xFF7A9D88); // Light sage
  static const Color warning = Color(0xFFFFAF2A); // Orange
  static const Color success = Color(0xFF5D866C); // Sage green
  static const Color accent = Color(0xFFC2A68C); // Tan accent

  // Dark Mode Colors
  static const Color darkPrimary = Color(0xFF281C9D);
  static const Color darkSecondary = Color(0xFF52D5BA);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkSurfaceVariant = Color(0xFF3A3A3A);
  static const Color darkError = Color(0xFFFF4267);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnSecondary = Color(0xFF000000);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFE5E5E5);
  static const Color darkOnError = Color(0xFFFFFFFF);

  // Light Mode Colors
  static const Color lightPrimary = Color(0xFF5D866C); // Sage green primary
  static const Color lightSecondary = Color(0xFFC2A68C); // Medium tan accent
  static const Color lightBackground = Color(0xFFF5F5F0); // Light grayish white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white for cards
  static const Color lightSurfaceVariant = Color(0xFFE6D8C3); // Light beige
  static const Color lightError = Color(0xFFFF4267);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSecondary = Color(0xFF000000);
  static const Color lightOnBackground = Color(0xFF343434);
  static const Color lightOnSurface = Color(0xFF343434);
  static const Color lightOnError = Color(0xFFFFFFFF);

  // Text Colors (Light Mode)
  static const Color textPrimary = Color(0xFF343434);
  static const Color textSecondary = Color(0xFF898989);
  static const Color textTertiary = Color(0xFF989898);

  // Text Colors (Dark Mode)
  static const Color darkTextPrimary = Color(0xFFE5E5E5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF808080);

  // Chart Colors - Warm Natural Tones
  static const List<Color> chartColors = [
    Color(0xFF5D866C), // Sage Green
    Color(0xFFC2A68C), // Medium Tan
    Color(0xFF7A9D88), // Light Sage
    Color(0xFFE6D8C3), // Light Beige
    Color(0xFFD4B896), // Warm Beige
    Color(0xFF8BAA97), // Soft Sage
    Color(0xFFB8967D), // Terra Cotta
    Color(0xFF9FB8A8), // Pale Sage
  ];

  // Category Background Colors (warm, natural tones)
  static const Color categoryGreen = Color(0xFFE8F0EC); // Soft sage
  static const Color categoryPurple = Color(0xFFE6D8C3); // Light beige
  static const Color categoryPink = Color(0xFFF5E8DD); // Warm pink
  static const Color categoryOrange = Color(0xFFFFEBDB); // Warm orange
  static const Color categoryBlue = Color(0xFFDCE8E4); // Soft blue-green
  static const Color categoryTeal = Color(0xFFD4E3DE); // Muted teal
  static const Color categoryYellow = Color(0xFFFFF8E5); // Soft yellow
  static const Color categoryRed = Color(0xFFFFE5E5); // Soft red
}
