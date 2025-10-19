import 'package:flutter/material.dart';

/// Application color palette - Banking App Design System
class AppColors {
  AppColors._();

  // PRIMARY COLORS (Purple Theme)
  static const Color primary = Color(0xFF281C9D); // Deep Purple
  static const Color primaryVariant1 = Color(0xFF5655B9); // Medium Purple
  static const Color primaryVariant2 = Color(0xFFA8A3D7); // Light Purple
  static const Color primaryVariant3 = Color(0xFFF2F1F9); // Very Light Purple

  // NEUTRAL COLORS
  static const Color neutral900 = Color(0xFF343434); // Darkest
  static const Color neutral700 = Color(0xFF898989);
  static const Color neutral600 = Color(0xFF989898);
  static const Color neutral400 = Color(0xFFCACACA);
  static const Color neutral200 = Color(0xFFE0E0E0);
  static const Color neutral100 = Color(0xFFFFFFFF); // White

  // SEMANTIC COLORS
  static const Color error = Color(0xFFFF4267); // Red
  static const Color info = Color(0xFF0890FE); // Blue
  static const Color warning = Color(0xFFFFAF2A); // Orange
  static const Color success = Color(0xFF52D5BA); // Teal
  static const Color accent = Color(0xFFFB6B18); // Orange accent

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
  static const Color lightPrimary = Color(0xFF281C9D); // Purple primary
  static const Color lightSecondary = Color(0xFF52D5BA); // Teal accent
  static const Color lightBackground = Color(0xFFF5F7FA); // Light grayish background
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white for cards
  static const Color lightSurfaceVariant = Color(0xFFF2F1F9); // Very light purple
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

  // Chart Colors - Soft Pastels from the design
  static const List<Color> chartColors = [
    Color(0xFFFFB59A), // Peach - 12%
    Color(0xFFB5D5F5), // Light Blue - 3%
    Color(0xFFFFF5BA), // Light Yellow - 5%
    Color(0xFFAFECC7), // Light Green - 32%
    Color(0xFFCDB4F0), // Light Purple - 21%
    Color(0xFF9FE6E1), // Light Teal - 7%
    Color(0xFFFFACC2), // Light Pink - 13%
    Color(0xFFFED8A8), // Light Beige - 5%
  ];

  // Category Background Colors (lighter variants for icons)
  static const Color categoryGreen = Color(0xFFE8F5E9);
  static const Color categoryPurple = Color(0xFFF3E5F5);
  static const Color categoryPink = Color(0xFFFCE4EC);
  static const Color categoryOrange = Color(0xFFFFF3E0);
  static const Color categoryBlue = Color(0xFFE3F2FD);
  static const Color categoryTeal = Color(0xFFE0F2F1);
  static const Color categoryYellow = Color(0xFFFFFDE7);
  static const Color categoryRed = Color(0xFFFFEBEE);
}
