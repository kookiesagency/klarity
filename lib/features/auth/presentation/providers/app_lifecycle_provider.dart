import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/recurring_transaction_service.dart';
import 'pin_verification_provider.dart';
import '../../../scheduled_payments/presentation/providers/scheduled_payment_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/providers/recurring_transaction_provider.dart';
import '../../../transactions/presentation/providers/emi_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';

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
  DateTime? _lastDailyProcessDate;
  bool _isProcessingDailyTasks = false;

  AppLifecycleNotifier(this._ref) : super(AppLifecycleState.resumed) {
    WidgetsBinding.instance.addObserver(this);
    _loadAutoLockDuration();
    // Run daily jobs shortly after startup
    Future.microtask(_processDailyTasks);
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
        unawaited(_processDailyTasks());
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

  Future<void> _processDailyTasks() async {
    if (_isProcessingDailyTasks) return;
    _isProcessingDailyTasks = true;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (_lastDailyProcessDate != null) {
        final last = DateTime(
          _lastDailyProcessDate!.year,
          _lastDailyProcessDate!.month,
          _lastDailyProcessDate!.day,
        );
        if (last == today) {
          _isProcessingDailyTasks = false;
          // Still refresh data on app resume even if already processed today
          await _refreshAllData();
          return;
        }
      }

      print('🔄 Processing daily tasks...');
      await _processRecurringTransactions();
      await _processScheduledPayments();

      _lastDailyProcessDate = today;

      // Refresh all data after processing
      print('🔄 Refreshing all data after processing...');
      await _refreshAllData();
      print('✅ Daily tasks complete');
    } catch (e) {
      print('⚠️ Failed to process daily tasks: $e');
    } finally {
      _isProcessingDailyTasks = false;
    }
  }

  /// Refresh all data providers to show updated information
  Future<void> _refreshAllData() async {
    try {
      final activeProfile = _ref.read(activeProfileProvider);
      if (activeProfile == null) {
        print('ℹ️ No active profile, skipping data refresh');
        return;
      }

      final profileId = activeProfile.id;

      // Reload all data in parallel for better performance
      await Future.wait([
        // Reload accounts
        _ref.read(accountProvider.notifier).loadAccounts(profileId),
        // Reload transactions
        _ref.read(transactionProvider.notifier).loadTransactionsPaginated(profileId, limit: 100),
        // Reload recurring transactions
        _ref.read(recurringTransactionProvider.notifier).loadRecurringTransactions(profileId),
        // Reload EMIs
        _ref.read(emiProvider.notifier).loadEmis(profileId),
        // Reload budgets
        _ref.read(budgetProvider.notifier).loadBudgets(profileId),
        // Reload scheduled payments
        _ref.read(scheduledPaymentProvider.notifier).loadScheduledPayments(profileId),
        // Reload categories
        _ref.read(categoryProvider.notifier).loadCategories(profileId),
      ]);

      print('✅ All data refreshed successfully');
    } catch (e) {
      print('⚠️ Failed to refresh all data: $e');
    }
  }

  Future<void> _processRecurringTransactions() async {
    try {
      final service = _ref.read(recurringTransactionServiceProvider);
      final result = await service.processDueRecurringTransactions();

      result.fold(
        onSuccess: (processingResult) {
          print('🔄 Recurring processing: ${processingResult.message}');
        },
        onFailure: (exception) {
          print('⚠️ Recurring processing failed: ${exception.message}');
        },
      );
    } catch (e) {
      print('⚠️ Recurring processing error: $e');
    }
  }

  Future<void> _processScheduledPayments() async {
    try {
      final result = await _ref.read(scheduledPaymentProvider.notifier).processDuePayments();

      result.fold(
        onSuccess: (count) {
          if (count > 0) {
            print('✅ Processed $count scheduled payment(s)');
          } else {
            print('ℹ️ No scheduled payments due today');
          }
        },
        onFailure: (exception) {
          print('⚠️ Scheduled payments processing failed: ${exception.message}');
        },
      );
    } catch (e) {
      print('⚠️ Scheduled payments processing error: $e');
    }
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

  /// Public method to refresh all data (can be called from UI)
  Future<void> refreshAllData() async {
    await _refreshAllData();
  }

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
