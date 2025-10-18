import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recurring_transaction_repository.dart';
import '../../domain/models/recurring_transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/models/recurring_frequency.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/models/profile_model.dart';

/// Provider for RecurringTransactionRepository
final recurringTransactionRepositoryProvider = Provider<RecurringTransactionRepository>((ref) {
  return RecurringTransactionRepository();
});

/// Recurring transaction state
class RecurringTransactionState {
  final List<RecurringTransactionModel> recurringTransactions;
  final bool isLoading;
  final String? error;

  const RecurringTransactionState({
    this.recurringTransactions = const [],
    this.isLoading = false,
    this.error,
  });

  /// Get active recurring transactions
  List<RecurringTransactionModel> get activeRecurringTransactions {
    return recurringTransactions.where((rt) => rt.isActive).toList();
  }

  /// Get inactive recurring transactions
  List<RecurringTransactionModel> get inactiveRecurringTransactions {
    return recurringTransactions.where((rt) => !rt.isActive).toList();
  }

  /// Get income recurring transactions
  List<RecurringTransactionModel> get incomeRecurringTransactions {
    return recurringTransactions
        .where((rt) => rt.type == TransactionType.income)
        .toList();
  }

  /// Get expense recurring transactions
  List<RecurringTransactionModel> get expenseRecurringTransactions {
    return recurringTransactions
        .where((rt) => rt.type == TransactionType.expense)
        .toList();
  }

  /// Get upcoming recurring transactions (next 30 days)
  List<RecurringTransactionModel> get upcomingRecurringTransactions {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final thirtyDaysLater = startOfToday.add(const Duration(days: 30));

    return activeRecurringTransactions
        .where((rt) {
          final nextDueDate = DateTime(
            rt.nextDueDate.year,
            rt.nextDueDate.month,
            rt.nextDueDate.day,
          );
          return nextDueDate.isAfter(startOfToday.subtract(const Duration(days: 1))) &&
              nextDueDate.isBefore(thirtyDaysLater);
        })
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  RecurringTransactionState copyWith({
    List<RecurringTransactionModel>? recurringTransactions,
    bool? isLoading,
    String? error,
  }) {
    return RecurringTransactionState(
      recurringTransactions: recurringTransactions ?? this.recurringTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Recurring transaction notifier
class RecurringTransactionNotifier extends StateNotifier<RecurringTransactionState> {
  final RecurringTransactionRepository _repository;
  final Ref _ref;

  RecurringTransactionNotifier(this._repository, this._ref)
      : super(const RecurringTransactionState()) {
    // Listen to profile changes
    _ref.listen<ProfileModel?>(
      activeProfileProvider,
      (previous, next) {
        if (next != null) {
          // Delay state modification to avoid build-time updates
          Future.microtask(() {
            loadRecurringTransactions(next.id);
          });
        }
      },
    );

    // Try initial load
    _initialize();
  }

  /// Initialize recurring transactions
  Future<void> _initialize() async {
    // Delay to avoid modifying state during widget build
    Future.microtask(() async {
      final activeProfile = _ref.read(activeProfileProvider);
      if (activeProfile == null) return;

      await loadRecurringTransactions(activeProfile.id);
    });
  }

  /// Load all recurring transactions for profile
  Future<void> loadRecurringTransactions(String profileId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getRecurringTransactions(profileId);

    result.fold(
      onSuccess: (recurringTransactions) {
        state = state.copyWith(
          recurringTransactions: recurringTransactions,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );
  }

  /// Load active recurring transactions
  Future<void> loadActiveRecurringTransactions(String profileId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getActiveRecurringTransactions(profileId);

    result.fold(
      onSuccess: (recurringTransactions) {
        state = state.copyWith(
          recurringTransactions: recurringTransactions,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );
  }

  /// Load recurring transactions by type
  Future<void> loadRecurringTransactionsByType({
    required String profileId,
    required TransactionType type,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getRecurringTransactionsByType(
      profileId: profileId,
      type: type,
    );

    result.fold(
      onSuccess: (recurringTransactions) {
        state = state.copyWith(
          recurringTransactions: recurringTransactions,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );
  }

  /// Create new recurring transaction
  Future<Result<RecurringTransactionModel>> createRecurringTransaction({
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    String? description,
    required RecurringFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime nextDueDate,
  }) async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile == null) {
      return Failure(ValidationException('No active profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createRecurringTransaction(
      profileId: activeProfile.id,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      description: description,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      nextDueDate: nextDueDate,
    );

    result.fold(
      onSuccess: (recurringTransaction) {
        state = state.copyWith(
          recurringTransactions: [recurringTransaction, ...state.recurringTransactions],
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Update recurring transaction
  Future<Result<RecurringTransactionModel>> updateRecurringTransaction({
    required String recurringTransactionId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? description,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.updateRecurringTransaction(
      recurringTransactionId: recurringTransactionId,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      description: description,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      nextDueDate: nextDueDate,
      isActive: isActive,
    );

    result.fold(
      onSuccess: (updatedRecurringTransaction) {
        final updatedList = state.recurringTransactions.map((rt) {
          return rt.id == recurringTransactionId ? updatedRecurringTransaction : rt;
        }).toList();

        state = state.copyWith(
          recurringTransactions: updatedList,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Delete recurring transaction
  Future<Result<void>> deleteRecurringTransaction(
    String recurringTransactionId,
  ) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteRecurringTransaction(
      recurringTransactionId,
    );

    result.fold(
      onSuccess: (_) {
        final updatedList = state.recurringTransactions
            .where((rt) => rt.id != recurringTransactionId)
            .toList();

        state = state.copyWith(
          recurringTransactions: updatedList,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Toggle active status
  Future<Result<RecurringTransactionModel>> toggleActiveStatus({
    required String recurringTransactionId,
    required bool isActive,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.toggleActiveStatus(
      recurringTransactionId: recurringTransactionId,
      isActive: isActive,
    );

    result.fold(
      onSuccess: (updatedRecurringTransaction) {
        final updatedList = state.recurringTransactions.map((rt) {
          return rt.id == recurringTransactionId ? updatedRecurringTransaction : rt;
        }).toList();

        state = state.copyWith(
          recurringTransactions: updatedList,
          isLoading: false,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );

    return result;
  }

  /// Process due recurring transactions
  Future<Result<Map<String, dynamic>>> processDueRecurringTransactions() async {
    final result = await _repository.processDueRecurringTransactions();

    result.fold(
      onSuccess: (processResult) {
        // Reload recurring transactions after processing
        final activeProfile = _ref.read(activeProfileProvider);
        if (activeProfile != null) {
          loadRecurringTransactions(activeProfile.id);
        }
      },
      onFailure: (exception) {
        state = state.copyWith(error: exception.message);
      },
    );

    return result;
  }

  /// Refresh recurring transactions
  Future<void> refresh() async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile != null) {
      await loadRecurringTransactions(activeProfile.id);
    }
  }
}

/// Recurring transaction provider
final recurringTransactionProvider = StateNotifierProvider<RecurringTransactionNotifier, RecurringTransactionState>((ref) {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  return RecurringTransactionNotifier(repository, ref);
});

/// Recurring transactions list provider
final recurringTransactionsListProvider = Provider<List<RecurringTransactionModel>>((ref) {
  final state = ref.watch(recurringTransactionProvider);
  return state.recurringTransactions;
});

/// Active recurring transactions provider
final activeRecurringTransactionsProvider = Provider<List<RecurringTransactionModel>>((ref) {
  final state = ref.watch(recurringTransactionProvider);
  return state.activeRecurringTransactions;
});

/// Upcoming recurring transactions provider (next 7 days)
final upcomingRecurringTransactionsProvider = Provider<List<RecurringTransactionModel>>((ref) {
  final state = ref.watch(recurringTransactionProvider);
  return state.upcomingRecurringTransactions;
});

/// Income recurring transactions provider
final incomeRecurringTransactionsProvider = Provider<List<RecurringTransactionModel>>((ref) {
  final state = ref.watch(recurringTransactionProvider);
  return state.incomeRecurringTransactions;
});

/// Expense recurring transactions provider
final expenseRecurringTransactionsProvider = Provider<List<RecurringTransactionModel>>((ref) {
  final state = ref.watch(recurringTransactionProvider);
  return state.expenseRecurringTransactions;
});
