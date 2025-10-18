import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

/// Theme mode preference keys
class ThemePrefs {
  static const String themeModeKey = 'theme_mode';
}

/// Enum for theme modes
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Theme manager to handle theme switching and persistence
class AppTheme {
  // Private constructor
  AppTheme._();

  /// Get light theme
  static ThemeData get lightTheme => LightTheme.theme;

  /// Get dark theme
  static ThemeData get darkTheme => DarkTheme.theme;

  /// Convert AppThemeMode to Flutter's ThemeMode
  static ThemeMode toThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Convert Flutter's ThemeMode to AppThemeMode
  static AppThemeMode fromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      case ThemeMode.system:
        return AppThemeMode.system;
    }
  }

  /// Save theme preference
  static Future<void> saveThemePreference(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ThemePrefs.themeModeKey, mode.name);
  }

  /// Load theme preference
  static Future<AppThemeMode> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(ThemePrefs.themeModeKey);

    if (themeName == null) {
      // Default to light mode on first launch
      return AppThemeMode.light;
    }

    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => AppThemeMode.light,
    );
  }

  /// Get current system brightness
  static Brightness getSystemBrightness() {
    return SchedulerBinding.instance.platformDispatcher.platformBrightness;
  }

  /// Check if system is in dark mode
  static bool isSystemDarkMode() {
    return getSystemBrightness() == Brightness.dark;
  }

  /// Get effective theme mode (resolves system mode to light/dark)
  static AppThemeMode getEffectiveThemeMode(AppThemeMode mode) {
    if (mode == AppThemeMode.system) {
      return isSystemDarkMode() ? AppThemeMode.dark : AppThemeMode.light;
    }
    return mode;
  }
}
