import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import 'pin_verification_provider.dart';

/// Provider for tracking app lifecycle state
final appLifecycleProvider = StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
  (ref) => AppLifecycleNotifier(ref),
);

/// Notifier for managing app lifecycle and auto-lock
class AppLifecycleNotifier extends StateNotifier<AppLifecycleState> with WidgetsBindingObserver {
  final Ref _ref;
  DateTime? _backgroundTime;
  Duration _autoLockDuration = Duration.zero; // Default: lock immediately
  static const String _autoLockDurationKey = 'auto_lock_duration_seconds';

  AppLifecycleNotifier(this._ref) : super(AppLifecycleState.resumed) {
    WidgetsBinding.instance.addObserver(this);
    _loadAutoLockDuration();
  }

  /// Load auto-lock duration from settings
  Future<void> _loadAutoLockDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt(_autoLockDurationKey);
      if (seconds != null) {
        _autoLockDuration = Duration(seconds: seconds);
        print('⚙️ Loaded auto-lock duration: ${_autoLockDuration.inMinutes}m ${_autoLockDuration.inSeconds % 60}s');
      } else {
        print('⚙️ Using default auto-lock: immediate');
      }
    } catch (e) {
      print('⚠️ Failed to load auto-lock duration: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    state = lifecycleState;

    switch (lifecycleState) {
      case AppLifecycleState.paused:
        // App went to background - only set time on paused, not inactive
        // Inactive happens during quick transitions (notification shade, navigation)
        _backgroundTime = DateTime.now();
        print('📱 App paused at ${_backgroundTime}');
        break;

      case AppLifecycleState.inactive:
        // App is inactive (quick transition) - don't set background time
        print('📱 App inactive (quick transition)');
        break;

      case AppLifecycleState.resumed:
        // App came back to foreground
        print('📱 App resumed');
        unawaited(SupabaseConfig.ensureValidSession());
        _checkAutoLock();
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _checkAutoLock() {
    if (_backgroundTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_backgroundTime!);

    // IMPORTANT: Don't lock if background time is less than 1 second
    // This prevents locking during quick navigation or system UI interactions
    const minBackgroundTime = Duration(seconds: 1);

    if (elapsed < minBackgroundTime) {
      print('⏱️ App unlocked - only ${elapsed.inMilliseconds}ms elapsed (too short for lock)');
      _backgroundTime = null;
      return;
    }

    // If Duration.zero, lock immediately (but only if > 1s). Otherwise check if elapsed time exceeds duration
    if (_autoLockDuration == Duration.zero || elapsed >= _autoLockDuration) {
      _ref.read(pinVerificationProvider.notifier).setPinVerified(false);
      print('🔒 App locked after ${elapsed.inSeconds}s - PIN/biometric required');
    } else {
      print('⏱️ App unlocked - only ${elapsed.inSeconds}s elapsed (threshold: ${_autoLockDuration.inMinutes}m)');
    }

    _backgroundTime = null;
  }

  /// Update auto-lock duration (can be called from settings)
  Future<void> updateAutoLockDuration(Duration duration) async {
    _autoLockDuration = duration;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_autoLockDurationKey, duration.inSeconds);
      print('⚙️ Auto-lock duration updated: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    } catch (e) {
      print('⚠️ Failed to save auto-lock duration: $e');
    }
  }

  /// Get current auto-lock duration
  Duration get autoLockDuration => _autoLockDuration;

  /// Common auto-lock durations for settings UI
  static List<Duration> get commonDurations => [
    Duration.zero,                    // Immediate
    const Duration(seconds: 30),      // 30 seconds
    const Duration(minutes: 1),       // 1 minute
    const Duration(minutes: 5),       // 5 minutes
    const Duration(minutes: 10),      // 10 minutes
    const Duration(minutes: 30),      // 30 minutes
  ];
}
