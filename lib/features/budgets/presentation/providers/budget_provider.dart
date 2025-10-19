import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/models/budget_period.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/models/profile_model.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

/// Provider for BudgetRepository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

/// Budget state with spending info
class BudgetState {
  final List<BudgetModel> budgets;
  final Map<String, BudgetStatus> budgetStatuses; // category_id -> BudgetStatus
  final bool isLoading;
  final String? error;

  const BudgetState({
    this.budgets = const [],
    this.budgetStatuses = const {},
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    List<BudgetModel>? budgets,
    Map<String, BudgetStatus>? budgetStatuses,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      budgetStatuses: budgetStatuses ?? this.budgetStatuses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Budget notifier
class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository _repository;
  final Ref _ref;

  BudgetNotifier(this._repository, this._ref) : super(const BudgetState()) {
    _initialize();
  }

  /// Initialize budgets
  Future<void> _initialize() async {
    // Delay to avoid modifying state during widget build
    Future.microtask(() async {
      final profile = _ref.read(activeProfileProvider);
      if (profile == null) return;

      await loadBudgets(profile.id);
    });

    // Listen to transaction changes and update budget statuses
    _ref.listen<TransactionState>(
      transactionProvider,
      (previous, next) {
        Future.microtask(() async {
          final profile = _ref.read(activeProfileProvider);
          // Only refresh if we have budgets loaded
          if (profile != null && state.budgets.isNotEmpty) {
            await _refreshBudgetStatuses(profile.id);
          }
        });
      },
    );

    // Listen to profile changes
    _ref.listen<ProfileModel?>(
      activeProfileProvider,
      (previous, next) {
        if (next != null && previous?.id != next.id) {
          Future.microtask(() => loadBudgets(next.id));
        }
      },
    );
  }

  /// Load all budgets for profile
  Future<void> loadBudgets(String profileId) async {
    print('🟢 loadBudgets called for profile: $profileId');
    state = state.copyWith(isLoading: true);

    final result = await _repository.getBudgets(profileId);

    await result.fold(
      onSuccess: (budgets) async {
        print('🟢 Loaded ${budgets.length} budgets from database');
        for (final budget in budgets) {
          print('  - Budget for category ${budget.categoryId}: ₹${budget.amount} (${budget.period.displayName})');
        }

        state = state.copyWith(
          budgets: budgets,
          isLoading: false,
          error: null,
        );

        // Calculate spending for each budget
        await _refreshBudgetStatuses(profileId);
      },
      onFailure: (exception) async {
        print('⚠️ Failed to load budgets: ${exception.message}');
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );
  }

  /// Refresh budget statuses with spending calculation
  Future<void> _refreshBudgetStatuses(String profileId) async {
    // Don't refresh if no budgets are loaded
    if (state.budgets.isEmpty) {
      print('⚠️ Skipping budget status refresh - no budgets loaded');
      return;
    }

    print('🟢 Refreshing budget statuses for ${state.budgets.length} budgets');
    final budgetStatuses = <String, BudgetStatus>{};

    for (final budget in state.budgets) {
      print('  🔄 Calculating spending for category: ${budget.categoryId}');
      final spendingResult = await _repository.getCategorySpending(
        profileId: profileId,
        categoryId: budget.categoryId,
        period: budget.period,
        startDate: budget.startDate,
      );

      spendingResult.fold(
        onSuccess: (spent) {
          final remaining = budget.amount - spent;
          final percentage = budget.amount > 0 ? (spent / budget.amount * 100) : 0.0;
          final alertLevel = _getAlertLevel(percentage, budget.alertThreshold);

          print('    ✅ Spent: ₹$spent, Remaining: ₹$remaining, Percentage: ${percentage.toStringAsFixed(1)}%');

          budgetStatuses[budget.categoryId] = BudgetStatus(
            budget: budget,
            spent: spent,
            remaining: remaining,
            percentage: percentage,
            alertLevel: alertLevel,
          );
        },
        onFailure: (exception) {
          print('    ⚠️ Failed to calculate spending for ${budget.categoryId}: ${exception.message}');
        },
      );
    }

    print('🟢 Budget statuses calculated: ${budgetStatuses.length} categories');
    state = state.copyWith(budgetStatuses: budgetStatuses);
  }

  /// Get budget alert level based on percentage
  BudgetAlertLevel _getAlertLevel(double percentage, int threshold) {
    if (percentage >= 100) return BudgetAlertLevel.overBudget;
    if (percentage >= threshold) return BudgetAlertLevel.critical;
    if (percentage >= 50) return BudgetAlertLevel.warning;
    return BudgetAlertLevel.safe;
  }

  /// Create new budget
  Future<Result<BudgetModel>> createBudget({
    required String categoryId,
    required double amount,
    BudgetPeriod period = BudgetPeriod.monthly,
    DateTime? startDate,
    DateTime? endDate,
    int alertThreshold = 80,
  }) async {
    final profile = _ref.read(activeProfileProvider);
    if (profile == null) {
      return Failure(AuthException('No active profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createBudget(
      profileId: profile.id,
      categoryId: categoryId,
      amount: amount,
      period: period,
      startDate: startDate,
      endDate: endDate,
      alertThreshold: alertThreshold,
    );

    result.fold(
      onSuccess: (budget) async {
        final updatedBudgets = [...state.budgets, budget];
        state = state.copyWith(
          budgets: updatedBudgets,
          isLoading: false,
          error: null,
        );

        // Refresh spending statuses
        await _refreshBudgetStatuses(profile.id);
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

  /// Update budget
  Future<Result<BudgetModel>> updateBudget({
    required String budgetId,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    int? alertThreshold,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.updateBudget(
      budgetId: budgetId,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      alertThreshold: alertThreshold,
      isActive: isActive,
    );

    result.fold(
      onSuccess: (updatedBudget) async {
        final updatedBudgets = state.budgets.map((b) {
          return b.id == budgetId ? updatedBudget : b;
        }).toList();

        state = state.copyWith(
          budgets: updatedBudgets,
          isLoading: false,
          error: null,
        );

        // Refresh spending statuses
        final profile = _ref.read(activeProfileProvider);
        if (profile != null) {
          await _refreshBudgetStatuses(profile.id);
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

  /// Delete budget
  Future<Result<void>> deleteBudget(String budgetId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteBudget(budgetId);

    result.fold(
      onSuccess: (_) async {
        final budgetToDelete = state.budgets.firstWhere((b) => b.id == budgetId);
        final updatedBudgets = state.budgets.where((b) => b.id != budgetId).toList();
        final updatedStatuses = Map<String, BudgetStatus>.from(state.budgetStatuses);
        updatedStatuses.remove(budgetToDelete.categoryId);

        state = state.copyWith(
          budgets: updatedBudgets,
          budgetStatuses: updatedStatuses,
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

  /// Get budget for category
  BudgetModel? getBudgetForCategory(String categoryId) {
    try {
      return state.budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Get budget status for category
  BudgetStatus? getBudgetStatusForCategory(String categoryId) {
    return state.budgetStatuses[categoryId];
  }

  /// Check if adding amount would exceed budget
  Future<BudgetWarning?> checkBudgetWarning({
    required String categoryId,
    required double amount,
  }) async {
    final status = getBudgetStatusForCategory(categoryId);
    if (status == null) return null;

    final newSpent = status.spent + amount;
    final newPercentage = (newSpent / status.budget.amount * 100);
    final wouldExceed = newSpent > status.budget.amount;
    final exceedAmount = wouldExceed ? newSpent - status.budget.amount : 0.0;

    if (wouldExceed || newPercentage >= status.budget.alertThreshold) {
      return BudgetWarning(
        categoryId: categoryId,
        budget: status.budget,
        currentSpent: status.spent,
        newSpent: newSpent,
        wouldExceedBudget: wouldExceed,
        exceedAmount: exceedAmount,
        newPercentage: newPercentage,
      );
    }

    return null;
  }

  /// Refresh budgets
  Future<void> refresh() async {
    final profile = _ref.read(activeProfileProvider);
    if (profile != null) {
      await loadBudgets(profile.id);
    }
  }
}

/// Budget provider
final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return BudgetNotifier(repository, ref);
});

/// Get budgets with over-budget status
final overBudgetProvider = Provider<List<BudgetStatus>>((ref) {
  final budgetState = ref.watch(budgetProvider);
  return budgetState.budgetStatuses.values
      .where((status) => status.isOverBudget)
      .toList();
});

/// Get budgets at alert threshold
final budgetsAtAlertProvider = Provider<List<BudgetStatus>>((ref) {
  final budgetState = ref.watch(budgetProvider);
  return budgetState.budgetStatuses.values
      .where((status) => status.isAtAlertThreshold && !status.isOverBudget)
      .toList();
});

/// Has any budget warnings
final hasBudgetWarningsProvider = Provider<bool>((ref) {
  final budgetState = ref.watch(budgetProvider);
  return budgetState.budgetStatuses.values.any(
    (status) => status.isOverBudget || status.isAtAlertThreshold,
  );
});

/// Budget warning model
class BudgetWarning {
  final String categoryId;
  final BudgetModel budget;
  final double currentSpent;
  final double newSpent;
  final bool wouldExceedBudget;
  final double exceedAmount;
  final double newPercentage;

  const BudgetWarning({
    required this.categoryId,
    required this.budget,
    required this.currentSpent,
    required this.newSpent,
    required this.wouldExceedBudget,
    required this.exceedAmount,
    required this.newPercentage,
  });
}
