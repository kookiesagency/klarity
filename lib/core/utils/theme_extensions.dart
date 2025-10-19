import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Extension to easily get theme-aware colors
extension ThemeAwareColors on BuildContext {
  /// Get text primary color based on theme
  Color get textPrimary {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
  }

  /// Get text secondary color based on theme
  Color get textSecondary {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
  }

  /// Get text tertiary color based on theme
  Color get textTertiary {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColors.darkTextTertiary
        : AppColors.textTertiary;
  }

  /// Check if current theme is dark
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }
}
