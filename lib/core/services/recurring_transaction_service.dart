import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/transactions/data/repositories/recurring_transaction_repository.dart';
import '../../features/transactions/presentation/providers/transaction_provider.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';

/// Service for processing recurring transactions
/// This service checks for due recurring transactions and creates actual transactions
class RecurringTransactionService {
  final RecurringTransactionRepository _recurringTransactionRepository;
  final Ref _ref;

  RecurringTransactionService(
    this._recurringTransactionRepository,
    this._ref,
  );

  /// Process all due recurring transactions
  /// This method should be called:
  /// - When app starts
  /// - Daily at a specific time (via background service)
  /// - Manually by the user
  Future<Result<ProcessingResult>> processDueRecurringTransactions() async {
    try {
      // Call the database function that processes recurring transactions
      final result = await _recurringTransactionRepository
          .processDueRecurringTransactions();

      return result.fold(
        onSuccess: (data) {
          final createdCount = data['created_count'] as int;
          final processedIds = data['processed_ids'] as List<String>;

          // Refresh transactions list to show newly created transactions
          _ref.read(transactionProvider.notifier).refresh();

          return Success(ProcessingResult(
            createdCount: createdCount,
            processedIds: processedIds,
            timestamp: DateTime.now(),
          ));
        },
        onFailure: (exception) {
          return Failure(exception);
        },
      );
    } catch (e) {
      return Failure(UnknownException(
        'Failed to process recurring transactions: ${e.toString()}',
      ));
    }
  }

  /// Check if any recurring transactions are due today
  Future<Result<bool>> hasTransactionsDueToday(String profileId) async {
    try {
      final result = await _recurringTransactionRepository
          .getActiveRecurringTransactions(profileId);

      return result.fold(
        onSuccess: (recurringTransactions) {
          final today = DateTime.now();
          final dueToday = recurringTransactions.any((rt) {
            return rt.nextDueDate.year == today.year &&
                rt.nextDueDate.month == today.month &&
                rt.nextDueDate.day == today.day;
          });

          return Success(dueToday);
        },
        onFailure: (exception) {
          return Failure(exception);
        },
      );
    } catch (e) {
      return Failure(UnknownException(
        'Failed to check due transactions: ${e.toString()}',
      ));
    }
  }

  /// Get count of upcoming recurring transactions (next 7 days)
  Future<Result<int>> getUpcomingTransactionsCount(String profileId) async {
    try {
      final result = await _recurringTransactionRepository
          .getUpcomingRecurringTransactions(profileId);

      return result.fold(
        onSuccess: (recurringTransactions) {
          return Success(recurringTransactions.length);
        },
        onFailure: (exception) {
          return Failure(exception);
        },
      );
    } catch (e) {
      return Failure(UnknownException(
        'Failed to get upcoming transactions count: ${e.toString()}',
      ));
    }
  }
}

/// Result of processing recurring transactions
class ProcessingResult {
  final int createdCount;
  final List<String> processedIds;
  final DateTime timestamp;

  ProcessingResult({
    required this.createdCount,
    required this.processedIds,
    required this.timestamp,
  });

  bool get hasProcessedTransactions => createdCount > 0;

  String get message {
    if (createdCount == 0) {
      return 'No recurring transactions due';
    } else if (createdCount == 1) {
      return '1 transaction created from recurring schedule';
    } else {
      return '$createdCount transactions created from recurring schedules';
    }
  }
}

/// Provider for RecurringTransactionService
final recurringTransactionServiceProvider = Provider<RecurringTransactionService>((ref) {
  final repository = RecurringTransactionRepository();
  return RecurringTransactionService(repository, ref);
});
