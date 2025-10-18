import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'supabase_config.dart';

/// Application configuration and initialization
class AppConfig {
  AppConfig._();

  /// Initialize the application
  static Future<void> initialize() async {
    try {
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Set preferred orientations (portrait only)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

      // Initialize Supabase
      await SupabaseConfig.initialize();

      if (kDebugMode) {
        print('✅ App initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error initializing app: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Cleanup on app disposal
  static Future<void> dispose() async {
    await SupabaseConfig.dispose();
  }
}
