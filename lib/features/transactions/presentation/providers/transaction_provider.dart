import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/models/transfer_model.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/models/profile_model.dart';
import '../../../alerts/presentation/providers/low_balance_alert_provider.dart';

/// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Transaction state
class TransactionState {
  final List<TransactionModel> transactions;
  final List<TransferModel> transfers;
  final bool isLoading;
  final String? error;
  final Set<String> selectedTransactionIds;

  const TransactionState({
    this.transactions = const [],
    this.transfers = const [],
    this.isLoading = false,
    this.error,
    this.selectedTransactionIds = const {},
  });

  /// Get income transactions
  List<TransactionModel> get incomeTransactions {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
  }

  /// Get expense transactions
  List<TransactionModel> get expenseTransactions {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
  }

  /// Calculate total income
  double get totalIncome {
    return incomeTransactions.fold<double>(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  /// Calculate total expense
  double get totalExpense {
    return expenseTransactions.fold<double>(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  /// Calculate net balance
  double get netBalance {
    return totalIncome - totalExpense;
  }

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    List<TransferModel>? transfers,
    bool? isLoading,
    String? error,
    Set<String>? selectedTransactionIds,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      transfers: transfers ?? this.transfers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedTransactionIds: selectedTransactionIds ?? this.selectedTransactionIds,
    );
  }
}

/// Transaction notifier
class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository _repository;
  final Ref _ref;

  TransactionNotifier(this._repository, this._ref) : super(const TransactionState()) {
    // Listen to profile changes
    _ref.listen<ProfileModel?>(
      activeProfileProvider,
      (previous, next) {
        if (next != null) {
          // Delay state modification to avoid build-time updates
          Future.microtask(() {
            loadTransactions(next.id);
            loadTransfers(next.id);
          });
        }
      },
    );

    // Try initial load
    _initialize();
  }

  /// Initialize transactions
  Future<void> _initialize() async {
    // Delay to avoid modifying state during widget build
    Future.microtask(() async {
      final activeProfile = _ref.read(activeProfileProvider);
      if (activeProfile == null) return;

      await loadTransactions(activeProfile.id);
      await loadTransfers(activeProfile.id);
    });
  }

  /// Load all transactions for profile
  Future<void> loadTransactions(String profileId) async {
    state = state.copyWith(isLoading: true);

    // Auto-lock transactions older than 2 months
    await _repository.autoLockOldTransactions(profileId);

    final result = await _repository.getTransactions(profileId);

    result.fold(
      onSuccess: (transactions) {
        state = state.copyWith(
          transactions: transactions,
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

  /// Load transactions by account
  Future<void> loadTransactionsByAccount({
    required String profileId,
    required String accountId,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getTransactionsByAccount(
      profileId: profileId,
      accountId: accountId,
    );

    result.fold(
      onSuccess: (transactions) {
        state = state.copyWith(
          transactions: transactions,
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

  /// Load transactions by date range
  Future<void> loadTransactionsByDateRange({
    required String profileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getTransactionsByDateRange(
      profileId: profileId,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      onSuccess: (transactions) {
        state = state.copyWith(
          transactions: transactions,
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

  /// Create new transaction
  Future<Result<TransactionModel>> createTransaction({
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    String? description,
    required DateTime transactionDate,
  }) async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile == null) {
      return Failure(ValidationException('No active profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createTransaction(
      profileId: activeProfile.id,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      description: description,
      transactionDate: transactionDate,
    );

    result.fold(
      onSuccess: (transaction) {
        state = state.copyWith(
          transactions: [transaction, ...state.transactions],
          isLoading: false,
          error: null,
        );
        // Check for low balance after transaction
        _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(accountId);
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

  /// Update transaction
  Future<Result<TransactionModel>> updateTransaction({
    required String transactionId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? description,
    DateTime? transactionDate,
  }) async {
    // Get old transaction to track account changes
    final oldTransaction = state.transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );

    state = state.copyWith(isLoading: true);

    final result = await _repository.updateTransaction(
      transactionId: transactionId,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      description: description,
      transactionDate: transactionDate,
    );

    result.fold(
      onSuccess: (updatedTransaction) {
        final updatedTransactions = state.transactions.map((t) {
          return t.id == transactionId ? updatedTransaction : t;
        }).toList();

        state = state.copyWith(
          transactions: updatedTransactions,
          isLoading: false,
          error: null,
        );

        // Check for low balance after transaction update
        // If account changed, check both old and new accounts
        if (accountId != null && accountId != oldTransaction.accountId) {
          _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(oldTransaction.accountId);
          _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(accountId);
        } else {
          _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(updatedTransaction.accountId);
        }
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

  /// Delete transaction
  Future<Result<void>> deleteTransaction(String transactionId) async {
    // Get transaction before deleting to track affected account
    final transaction = state.transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );

    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteTransaction(transactionId);

    result.fold(
      onSuccess: (_) {
        final updatedTransactions =
            state.transactions.where((t) => t.id != transactionId).toList();

        state = state.copyWith(
          transactions: updatedTransactions,
          isLoading: false,
          error: null,
        );

        // Check for low balance after transaction deletion
        _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(transaction.accountId);
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

  /// Unlock a specific transaction
  Future<Result<void>> unlockTransaction(String transactionId) async {
    final result = await _repository.unlockTransaction(transactionId);

    result.fold(
      onSuccess: (_) {
        // Update transaction in state
        final updatedTransactions = state.transactions.map((t) {
          if (t.id == transactionId) {
            return t.copyWith(isLocked: false, lockedAt: null);
          }
          return t;
        }).toList();

        state = state.copyWith(transactions: updatedTransactions);
      },
      onFailure: (_) {
        // Error is handled by caller
      },
    );

    return result;
  }

  /// Toggle transaction selection
  void toggleTransactionSelection(String transactionId) {
    final selectedIds = Set<String>.from(state.selectedTransactionIds);
    if (selectedIds.contains(transactionId)) {
      selectedIds.remove(transactionId);
    } else {
      selectedIds.add(transactionId);
    }
    state = state.copyWith(selectedTransactionIds: selectedIds);
  }

  /// Select all transactions
  void selectAllTransactions() {
    final allIds = state.transactions.map((t) => t.id).toSet();
    state = state.copyWith(selectedTransactionIds: allIds);
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(selectedTransactionIds: {});
  }

  /// Bulk delete selected transactions
  Future<Result<void>> bulkDeleteTransactions() async {
    if (state.selectedTransactionIds.isEmpty) {
      return Failure(ValidationException('No transactions selected'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.bulkDeleteTransactions(
      state.selectedTransactionIds.toList(),
    );

    result.fold(
      onSuccess: (_) {
        final updatedTransactions = state.transactions
            .where((t) => !state.selectedTransactionIds.contains(t.id))
            .toList();

        state = state.copyWith(
          transactions: updatedTransactions,
          isLoading: false,
          error: null,
          selectedTransactionIds: {},
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

  /// Bulk update category
  Future<Result<void>> bulkUpdateCategory(String categoryId) async {
    if (state.selectedTransactionIds.isEmpty) {
      return Failure(ValidationException('No transactions selected'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.bulkUpdateCategory(
      transactionIds: state.selectedTransactionIds.toList(),
      categoryId: categoryId,
    );

    result.fold(
      onSuccess: (_) async {
        // Reload transactions to get updated data
        final activeProfile = _ref.read(activeProfileProvider);
        if (activeProfile != null) {
          await loadTransactions(activeProfile.id);
        }
        state = state.copyWith(selectedTransactionIds: {});
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

  /// Bulk update account
  Future<Result<void>> bulkUpdateAccount(String accountId) async {
    if (state.selectedTransactionIds.isEmpty) {
      return Failure(ValidationException('No transactions selected'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.bulkUpdateAccount(
      transactionIds: state.selectedTransactionIds.toList(),
      accountId: accountId,
    );

    result.fold(
      onSuccess: (_) async {
        // Reload transactions to get updated data
        final activeProfile = _ref.read(activeProfileProvider);
        if (activeProfile != null) {
          await loadTransactions(activeProfile.id);
        }
        state = state.copyWith(selectedTransactionIds: {});
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

  // ==================== TRANSFER OPERATIONS ====================

  /// Load transfers
  Future<void> loadTransfers(String profileId) async {
    final result = await _repository.getTransfers(profileId);

    result.fold(
      onSuccess: (transfers) {
        state = state.copyWith(
          transfers: transfers,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          error: exception.message,
        );
      },
    );
  }

  /// Create new transfer
  Future<Result<TransferModel>> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
    required DateTime transferDate,
  }) async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile == null) {
      return Failure(ValidationException('No active profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createTransfer(
      profileId: activeProfile.id,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      description: description,
      transferDate: transferDate,
    );

    result.fold(
      onSuccess: (transfer) {
        state = state.copyWith(
          transfers: [transfer, ...state.transfers],
          isLoading: false,
          error: null,
        );
        // Check for low balance after transfer (both accounts affected)
        _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(fromAccountId);
        _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(toAccountId);
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

  /// Delete transfer
  Future<Result<void>> deleteTransfer(String transferId) async {
    // Get transfer before deleting to track affected accounts
    final transfer = state.transfers.firstWhere(
      (t) => t.id == transferId,
      orElse: () => throw Exception('Transfer not found'),
    );

    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteTransfer(transferId);

    result.fold(
      onSuccess: (_) {
        final updatedTransfers =
            state.transfers.where((t) => t.id != transferId).toList();

        state = state.copyWith(
          transfers: updatedTransfers,
          isLoading: false,
          error: null,
        );

        // Check for low balance after transfer deletion (both accounts affected)
        _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(transfer.fromAccountId);
        _ref.read(lowBalanceAlertProvider.notifier).checkAfterTransaction(transfer.toAccountId);
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

  /// Refresh transactions
  Future<void> refresh() async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile != null) {
      await loadTransactions(activeProfile.id);
      await loadTransfers(activeProfile.id);
    }
  }
}

/// Transaction provider
final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repository, ref);
});

/// Transactions list provider
final transactionsListProvider = Provider<List<TransactionModel>>((ref) {
  final transactionState = ref.watch(transactionProvider);
  return transactionState.transactions;
});

/// Income transactions provider
final incomeTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactionState = ref.watch(transactionProvider);
  return transactionState.incomeTransactions;
});

/// Expense transactions provider
final expenseTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactionState = ref.watch(transactionProvider);
  return transactionState.expenseTransactions;
});

/// Transfers list provider
final transfersListProvider = Provider<List<TransferModel>>((ref) {
  final transactionState = ref.watch(transactionProvider);
  return transactionState.transfers;
});
