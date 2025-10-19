import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../data/repositories/scheduled_payment_repository.dart';
import '../../domain/models/scheduled_payment_model.dart';
import '../../domain/models/scheduled_payment_status.dart';
import '../../domain/models/payment_history_model.dart';

/// Provider for ScheduledPaymentRepository
final scheduledPaymentRepositoryProvider = Provider<ScheduledPaymentRepository>((ref) {
  return ScheduledPaymentRepository();
});

/// Scheduled payment state
class ScheduledPaymentState {
  final List<ScheduledPaymentModel> payments;
  final List<PaymentHistoryModel> paymentHistory;
  final bool isLoading;
  final String? error;

  const ScheduledPaymentState({
    this.payments = const [],
    this.paymentHistory = const [],
    this.isLoading = false,
    this.error,
  });

  /// Get pending payments
  List<ScheduledPaymentModel> get pendingPayments {
    return payments
        .where((p) => p.status == ScheduledPaymentStatus.pending)
        .toList();
  }

  /// Get partial payments
  List<ScheduledPaymentModel> get partialPayments {
    return payments
        .where((p) => p.status == ScheduledPaymentStatus.partial)
        .toList();
  }

  /// Get completed payments
  List<ScheduledPaymentModel> get completedPayments {
    return payments
        .where((p) => p.status == ScheduledPaymentStatus.completed)
        .toList();
  }

  /// Get overdue payments
  List<ScheduledPaymentModel> get overduePayments {
    return payments.where((p) => p.isOverdue).toList();
  }

  /// Get upcoming payments (due within 30 days)
  List<ScheduledPaymentModel> get upcomingPayments {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));

    return payments
        .where((p) =>
            (p.status == ScheduledPaymentStatus.pending ||
                p.status == ScheduledPaymentStatus.partial) &&
            p.dueDate.isAfter(now) &&
            p.dueDate.isBefore(thirtyDaysLater))
        .toList();
  }

  ScheduledPaymentState copyWith({
    List<ScheduledPaymentModel>? payments,
    List<PaymentHistoryModel>? paymentHistory,
    bool? isLoading,
    String? error,
  }) {
    return ScheduledPaymentState(
      payments: payments ?? this.payments,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Scheduled payment notifier
class ScheduledPaymentNotifier extends StateNotifier<ScheduledPaymentState> {
  final ScheduledPaymentRepository _repository;
  final Ref _ref;

  ScheduledPaymentNotifier(this._repository, this._ref)
      : super(const ScheduledPaymentState()) {
    // Listen to profile changes
    _ref.listen<dynamic>(
      activeProfileProvider,
      (previous, next) {
        if (next != null) {
          Future.microtask(() {
            loadScheduledPayments(next.id);
          });
        }
      },
    );

    // Try initial load
    _initialize();
  }

  /// Initialize payments
  Future<void> _initialize() async {
    Future.microtask(() async {
      final activeProfile = _ref.read(activeProfileProvider);
      if (activeProfile == null) return;

      await loadScheduledPayments(activeProfile.id);
    });
  }

  /// Load all scheduled payments
  Future<void> loadScheduledPayments(String profileId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getScheduledPayments(profileId);

    result.fold(
      onSuccess: (payments) {
        state = state.copyWith(
          payments: payments,
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

  /// Load upcoming payments
  Future<void> loadUpcomingPayments(String profileId) async {
    final result = await _repository.getUpcomingPayments(profileId);

    result.fold(
      onSuccess: (payments) {
        state = state.copyWith(
          payments: payments,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(error: exception.message);
      },
    );
  }

  /// Create a scheduled payment
  Future<Result<ScheduledPaymentModel>> createScheduledPayment({
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    required String payeeName,
    String? description,
    required DateTime dueDate,
    DateTime? reminderDate,
    bool allowPartialPayment = false,
    bool autoCreateTransaction = true,
  }) async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile == null) {
      return Failure(ValidationException('No active profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createScheduledPayment(
      profileId: activeProfile.id,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      payeeName: payeeName,
      description: description,
      dueDate: dueDate,
      reminderDate: reminderDate,
      allowPartialPayment: allowPartialPayment,
      autoCreateTransaction: autoCreateTransaction,
    );

    result.fold(
      onSuccess: (payment) {
        state = state.copyWith(
          payments: [payment, ...state.payments],
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

  /// Update a scheduled payment
  Future<Result<ScheduledPaymentModel>> updateScheduledPayment({
    required String paymentId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? payeeName,
    String? description,
    DateTime? dueDate,
    DateTime? reminderDate,
    bool? allowPartialPayment,
    bool? autoCreateTransaction,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.updateScheduledPayment(
      paymentId: paymentId,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      payeeName: payeeName,
      description: description,
      dueDate: dueDate,
      reminderDate: reminderDate,
      allowPartialPayment: allowPartialPayment,
      autoCreateTransaction: autoCreateTransaction,
    );

    result.fold(
      onSuccess: (updatedPayment) {
        final updatedPayments = state.payments.map((p) {
          return p.id == paymentId ? updatedPayment : p;
        }).toList();

        state = state.copyWith(
          payments: updatedPayments,
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

  /// Delete a scheduled payment
  Future<Result<void>> deleteScheduledPayment(String paymentId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteScheduledPayment(paymentId);

    result.fold(
      onSuccess: (_) {
        final updatedPayments =
            state.payments.where((p) => p.id != paymentId).toList();

        state = state.copyWith(
          payments: updatedPayments,
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

  /// Cancel a scheduled payment
  Future<Result<void>> cancelScheduledPayment(String paymentId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.cancelScheduledPayment(paymentId);

    result.fold(
      onSuccess: (_) {
        final updatedPayments = state.payments.map((p) {
          if (p.id == paymentId) {
            return p.copyWith(status: ScheduledPaymentStatus.cancelled);
          }
          return p;
        }).toList();

        state = state.copyWith(
          payments: updatedPayments,
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

  /// Load payment history
  Future<void> loadPaymentHistory(String scheduledPaymentId) async {
    final result = await _repository.getPaymentHistory(scheduledPaymentId);

    result.fold(
      onSuccess: (history) {
        state = state.copyWith(
          paymentHistory: history,
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(error: exception.message);
      },
    );
  }

  /// Record a payment
  Future<Result<PaymentHistoryModel>> recordPayment({
    required String scheduledPaymentId,
    required double amount,
    String? transactionId,
    String? notes,
  }) async {
    final result = await _repository.recordPayment(
      scheduledPaymentId: scheduledPaymentId,
      amount: amount,
      transactionId: transactionId,
      notes: notes,
    );

    result.fold(
      onSuccess: (history) {
        state = state.copyWith(
          paymentHistory: [history, ...state.paymentHistory],
        );

        // Reload payments to get updated status
        final activeProfile = _ref.read(activeProfileProvider);
        if (activeProfile != null) {
          loadScheduledPayments(activeProfile.id);
        }
      },
      onFailure: (_) {},
    );

    return result;
  }

  /// Process due payments
  Future<Result<int>> processDuePayments() async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.processDuePayments();

    result.fold(
      onSuccess: (count) {
        state = state.copyWith(isLoading: false);

        // Reload payments
        final activeProfile = _ref.read(activeProfileProvider);
        if (activeProfile != null) {
          loadScheduledPayments(activeProfile.id);
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

  /// Refresh payments
  Future<void> refresh() async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile != null) {
      await loadScheduledPayments(activeProfile.id);
    }
  }
}

/// Scheduled payment provider
final scheduledPaymentProvider =
    StateNotifierProvider<ScheduledPaymentNotifier, ScheduledPaymentState>((ref) {
  final repository = ref.watch(scheduledPaymentRepositoryProvider);
  return ScheduledPaymentNotifier(repository, ref);
});

/// Upcoming payments provider
final upcomingPaymentsProvider = Provider<List<ScheduledPaymentModel>>((ref) {
  final paymentState = ref.watch(scheduledPaymentProvider);
  return paymentState.upcomingPayments;
});

/// Overdue payments provider
final overduePaymentsProvider = Provider<List<ScheduledPaymentModel>>((ref) {
  final paymentState = ref.watch(scheduledPaymentProvider);
  return paymentState.overduePayments;
});
