import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'supabase_config.dart';

/// Application configuration and initialization
class AppConfig {
  AppConfig._();

  /// Initialize the application
  /// Optimized with parallel initialization for faster startup
  static Future<void> initialize() async {
    try {
      final stopwatch = Stopwatch()..start();
      if (kDebugMode) print('🚀 Starting app initialization...');

      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Parallelize independent initialization tasks for faster startup
      if (kDebugMode) print('⏳ Initializing Supabase...');
      await Future.wait([
        // Critical: Supabase initialization (needed for auth)
        SupabaseConfig.initialize(),

        // Non-blocking: System preferences (can run in parallel)
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
      ]);
      if (kDebugMode) print('✅ Supabase initialized in ${stopwatch.elapsedMilliseconds}ms');

      // Non-critical: Set system UI overlay style (doesn't need await)
      // This is a visual preference and doesn't block app functionality
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

      stopwatch.stop();
      if (kDebugMode) {
        print('✅ App initialized successfully in ${stopwatch.elapsedMilliseconds}ms');
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
