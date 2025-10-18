import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/emi_repository.dart';
import '../../domain/models/emi_model.dart';
import '../../domain/models/emi_payment_model.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/models/profile_model.dart';

/// Provider for EmiRepository
final emiRepositoryProvider = Provider<EmiRepository>((ref) {
  return EmiRepository();
});

/// EMI state
class EmiState {
  final List<EmiModel> emis;
  final bool isLoading;
  final String? error;

  const EmiState({
    this.emis = const [],
    this.isLoading = false,
    this.error,
  });

  /// Get active EMIs
  List<EmiModel> get activeEmis {
    return emis.where((emi) => emi.isActive).toList();
  }

  /// Get completed EMIs
  List<EmiModel> get completedEmis {
    return emis.where((emi) => emi.isCompleted).toList();
  }

  /// Get overdue EMIs
  List<EmiModel> get overdueEmis {
    return emis.where((emi) => emi.isOverdue && emi.isActive).toList();
  }

  /// Get upcoming EMIs (next 7 days)
  List<EmiModel> get upcomingEmis {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));

    return activeEmis
        .where((emi) => emi.nextPaymentDate.isBefore(sevenDaysLater))
        .toList();
  }

  /// Calculate total monthly EMI payment
  double get totalMonthlyPayment {
    return activeEmis.fold<double>(
      0.0,
      (sum, emi) => sum + emi.monthlyPayment,
    );
  }

  /// Calculate total remaining amount across all EMIs
  double get totalRemainingAmount {
    return activeEmis.fold<double>(
      0.0,
      (sum, emi) => sum + emi.remainingAmount,
    );
  }

  EmiState copyWith({
    List<EmiModel>? emis,
    bool? isLoading,
    String? error,
  }) {
    return EmiState(
      emis: emis ?? this.emis,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// EMI notifier
class EmiNotifier extends StateNotifier<EmiState> {
  final EmiRepository _repository;
  final Ref _ref;

  EmiNotifier(this._repository, this._ref) : super(const EmiState()) {
    // Listen to profile changes
    _ref.listen<ProfileModel?>(
      activeProfileProvider,
      (previous, next) {
        print('👤 Profile changed: ${previous?.id} → ${next?.id}');
        if (next != null) {
          // Delay state modification to avoid build-time updates
          Future.microtask(() {
            print('🔄 Loading EMIs for profile: ${next.id}');
            loadEmis(next.id);
          });
        }
      },
    );

    // Try initial load
    _initialize();
  }

  /// Initialize EMIs
  Future<void> _initialize() async {
    // Delay to avoid modifying state during widget build
    Future.microtask(() async {
      print('🚀 EMI Provider initializing...');
      final activeProfile = _ref.read(activeProfileProvider);
      print('📌 Active profile: ${activeProfile?.id ?? "NULL"}');
      if (activeProfile == null) {
        print('⚠️ No active profile, skipping EMI load');
        return;
      }

      print('🔄 Loading EMIs for profile...');
      await loadEmis(activeProfile.id);
    });
  }

  /// Load all EMIs for profile
  Future<void> loadEmis(String profileId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getEmis(profileId);

    result.fold(
      onSuccess: (emis) {
        state = state.copyWith(
          emis: emis,
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

  /// Load active EMIs
  Future<void> loadActiveEmis(String profileId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getActiveEmis(profileId);

    result.fold(
      onSuccess: (emis) {
        state = state.copyWith(
          emis: emis,
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

  /// Create new EMI
  Future<Result<EmiModel>> createEmi({
    required String accountId,
    required String categoryId,
    required String name,
    String? description,
    required double totalAmount,
    required double monthlyPayment,
    required int totalInstallments,
    int paidInstallments = 0,
    required DateTime startDate,
    required int paymentDayOfMonth,
  }) async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile == null) {
      return Failure(ValidationException('No active profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createEmi(
      profileId: activeProfile.id,
      accountId: accountId,
      categoryId: categoryId,
      name: name,
      description: description,
      totalAmount: totalAmount,
      monthlyPayment: monthlyPayment,
      totalInstallments: totalInstallments,
      paidInstallments: paidInstallments,
      startDate: startDate,
      paymentDayOfMonth: paymentDayOfMonth,
    );

    result.fold(
      onSuccess: (emi) {
        state = state.copyWith(
          emis: [emi, ...state.emis],
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

  /// Update EMI
  Future<Result<EmiModel>> updateEmi({
    required String emiId,
    String? accountId,
    String? categoryId,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.updateEmi(
      emiId: emiId,
      accountId: accountId,
      categoryId: categoryId,
      name: name,
      description: description,
      isActive: isActive,
    );

    result.fold(
      onSuccess: (updatedEmi) {
        final updatedList = state.emis.map((emi) {
          return emi.id == emiId ? updatedEmi : emi;
        }).toList();

        state = state.copyWith(
          emis: updatedList,
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

  /// Delete EMI
  Future<Result<void>> deleteEmi(String emiId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteEmi(emiId);

    result.fold(
      onSuccess: (_) {
        final updatedList = state.emis.where((emi) => emi.id != emiId).toList();

        state = state.copyWith(
          emis: updatedList,
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
  Future<Result<EmiModel>> toggleActiveStatus({
    required String emiId,
    required bool isActive,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.toggleActiveStatus(
      emiId: emiId,
      isActive: isActive,
    );

    result.fold(
      onSuccess: (updatedEmi) {
        final updatedList = state.emis.map((emi) {
          return emi.id == emiId ? updatedEmi : emi;
        }).toList();

        state = state.copyWith(
          emis: updatedList,
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

  /// Process due EMI payments
  Future<Result<Map<String, dynamic>>> processDueEmiPayments() async {
    final result = await _repository.processDueEmiPayments();

    result.fold(
      onSuccess: (processResult) {
        // Reload EMIs after processing
        final activeProfile = _ref.read(activeProfileProvider);
        if (activeProfile != null) {
          loadEmis(activeProfile.id);
        }
      },
      onFailure: (exception) {
        state = state.copyWith(error: exception.message);
      },
    );

    return result;
  }

  /// Delete EMI payment
  Future<Result<EmiModel>> deleteEmiPayment({
    required String emiId,
    required String paymentId,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteEmiPayment(
      emiId: emiId,
      paymentId: paymentId,
    );

    result.fold(
      onSuccess: (updatedEmi) {
        final updatedList = state.emis.map((emi) {
          return emi.id == emiId ? updatedEmi : emi;
        }).toList();

        state = state.copyWith(
          emis: updatedList,
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

  /// Record manual EMI payment
  Future<Result<EmiModel>> recordManualPayment({
    required String emiId,
    required DateTime paymentDate,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.recordManualPayment(
      emiId: emiId,
      paymentDate: paymentDate,
    );

    result.fold(
      onSuccess: (updatedEmi) {
        final updatedList = state.emis.map((emi) {
          return emi.id == emiId ? updatedEmi : emi;
        }).toList();

        state = state.copyWith(
          emis: updatedList,
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

  /// Refresh EMIs
  Future<void> refresh() async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile != null) {
      await loadEmis(activeProfile.id);
    }
  }
}

/// EMI provider
final emiProvider = StateNotifierProvider<EmiNotifier, EmiState>((ref) {
  final repository = ref.watch(emiRepositoryProvider);
  return EmiNotifier(repository, ref);
});

/// EMIs list provider
final emisListProvider = Provider<List<EmiModel>>((ref) {
  final state = ref.watch(emiProvider);
  return state.emis;
});

/// Active EMIs provider
final activeEmisProvider = Provider<List<EmiModel>>((ref) {
  final state = ref.watch(emiProvider);
  return state.activeEmis;
});

/// Upcoming EMIs provider (next 7 days)
final upcomingEmisProvider = Provider<List<EmiModel>>((ref) {
  final state = ref.watch(emiProvider);
  return state.upcomingEmis;
});

/// Overdue EMIs provider
final overdueEmisProvider = Provider<List<EmiModel>>((ref) {
  final state = ref.watch(emiProvider);
  return state.overdueEmis;
});

/// Total monthly payment provider
final totalMonthlyEmiPaymentProvider = Provider<double>((ref) {
  final state = ref.watch(emiProvider);
  return state.totalMonthlyPayment;
});
