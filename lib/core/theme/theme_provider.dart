import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

/// State notifier for managing theme mode
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.light) {
    _loadTheme();
  }

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    final savedTheme = await AppTheme.loadThemePreference();
    state = savedTheme;
  }

  /// Set theme mode and save preference
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await AppTheme.saveThemePreference(mode);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final effectiveMode = AppTheme.getEffectiveThemeMode(state);
    final newMode = effectiveMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Set to system theme
  Future<void> useSystemTheme() async {
    await setThemeMode(AppThemeMode.system);
  }

  /// Get the effective theme mode (resolves system to light/dark)
  AppThemeMode get effectiveThemeMode => AppTheme.getEffectiveThemeMode(state);

  /// Check if currently in dark mode
  bool get isDarkMode => effectiveThemeMode == AppThemeMode.dark;

  /// Check if currently in light mode
  bool get isLightMode => effectiveThemeMode == AppThemeMode.light;

  /// Check if using system theme
  bool get isSystemTheme => state == AppThemeMode.system;
}

/// Provider for theme mode
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>(
  (ref) => ThemeNotifier(),
);

/// Provider to get the current ThemeMode for MaterialApp
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appThemeMode = ref.watch(themeProvider);
  return AppTheme.toThemeMode(appThemeMode);
});

/// Provider to check if current theme is dark
final isDarkModeProvider = Provider<bool>((ref) {
  final themeNotifier = ref.watch(themeProvider.notifier);
  return themeNotifier.isDarkMode;
});

/// Provider to check if using system theme
final isSystemThemeProvider = Provider<bool>((ref) {
  final themeNotifier = ref.watch(themeProvider.notifier);
  return themeNotifier.isSystemTheme;
});
