import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'recurring_transaction_service.dart';
import '../utils/logger.dart';

/// Observer for app lifecycle events
/// Handles processing recurring transactions when app starts or resumes
class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref _ref;
  DateTime? _lastProcessedDate;

  AppLifecycleObserver(this._ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes or starts
    if (state == AppLifecycleState.resumed) {
      _checkAndProcessRecurringTransactions();
    }
  }

  /// Check if we need to process recurring transactions
  /// Only process once per day
  Future<void> _checkAndProcessRecurringTransactions() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Check if we already processed today
    if (_lastProcessedDate != null) {
      final lastProcessedDate = DateTime(
        _lastProcessedDate!.year,
        _lastProcessedDate!.month,
        _lastProcessedDate!.day,
      );

      if (todayDate == lastProcessedDate) {
        Logger.info('Recurring transactions already processed today');
        return;
      }
    }

    Logger.info('Processing recurring transactions...');

    try {
      final service = _ref.read(recurringTransactionServiceProvider);
      final result = await service.processDueRecurringTransactions();

      result.fold(
        onSuccess: (processingResult) {
          _lastProcessedDate = DateTime.now();
          Logger.info(processingResult.message);
        },
        onFailure: (exception) {
          Logger.error(
            'Failed to process recurring transactions: ${exception.message}',
          );
        },
      );
    } catch (e) {
      Logger.error('Error processing recurring transactions: $e');
    }
  }

  /// Manually trigger processing (for testing or user-initiated refresh)
  Future<void> processNow() async {
    _lastProcessedDate = null; // Reset to force processing
    await _checkAndProcessRecurringTransactions();
  }
}

/// Provider for AppLifecycleObserver
final appLifecycleObserverProvider = Provider<AppLifecycleObserver>((ref) {
  return AppLifecycleObserver(ref);
});
