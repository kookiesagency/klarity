import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../data/repositories/emi_repository.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../presentation/providers/emi_provider.dart';

/// Service for automatic EMI payment processing
class EmiAutoPaymentService {
  final EmiRepository _repository;
  final Ref _ref;
  Timer? _timer;
  bool _isProcessing = false;

  EmiAutoPaymentService(this._repository, this._ref);

  /// Start automatic payment processing
  /// Checks for due payments every [interval] duration
  void start({Duration interval = const Duration(hours: 1)}) {
    // Cancel existing timer if any
    stop();

    // Process immediately on start
    processPayments();

    // Schedule periodic processing
    _timer = Timer.periodic(interval, (_) {
      processPayments();
    });
  }

  /// Stop automatic payment processing
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Process due EMI payments manually
  Future<Result<Map<String, dynamic>>> processPayments() async {
    // Prevent concurrent processing
    if (_isProcessing) {
      return const Success({
        'created_count': 0,
        'processed_emi_ids': [],
        'message': 'Already processing',
      });
    }

    _isProcessing = true;

    try {
      // Call database function to process due payments
      final result = await _repository.processDueEmiPayments();

      result.fold(
        onSuccess: (data) {
          final createdCount = data['created_count'] as int;
          final processedEmiIds = data['processed_emi_ids'] as List<String>;

          // Refresh EMI list if any payments were processed
          if (createdCount > 0) {
            final activeProfile = _ref.read(activeProfileProvider);
            if (activeProfile != null) {
              _ref.read(emiProvider.notifier).loadEmis(activeProfile.id);
            }
          }
        },
        onFailure: (exception) {
          // Log error
          print('EMI Auto-Payment Error: ${exception.message}');
        },
      );

      return result;
    } finally {
      _isProcessing = false;
    }
  }

  /// Check if service is running
  bool get isRunning => _timer?.isActive ?? false;

  /// Check if currently processing
  bool get isProcessing => _isProcessing;

  /// Dispose the service
  void dispose() {
    stop();
  }
}

/// Provider for EMI auto-payment service
final emiAutoPaymentServiceProvider = Provider<EmiAutoPaymentService>((ref) {
  final repository = ref.watch(emiRepositoryProvider);
  final service = EmiAutoPaymentService(repository, ref);

  // Clean up when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// State for auto-payment service
class AutoPaymentState {
  final bool isEnabled;
  final bool isProcessing;
  final DateTime? lastProcessedAt;
  final String? error;

  const AutoPaymentState({
    this.isEnabled = false,
    this.isProcessing = false,
    this.lastProcessedAt,
    this.error,
  });

  AutoPaymentState copyWith({
    bool? isEnabled,
    bool? isProcessing,
    DateTime? lastProcessedAt,
    String? error,
  }) {
    return AutoPaymentState(
      isEnabled: isEnabled ?? this.isEnabled,
      isProcessing: isProcessing ?? this.isProcessing,
      lastProcessedAt: lastProcessedAt ?? this.lastProcessedAt,
      error: error,
    );
  }
}

/// Notifier for auto-payment service state
class AutoPaymentNotifier extends StateNotifier<AutoPaymentState> {
  final EmiAutoPaymentService _service;

  AutoPaymentNotifier(this._service) : super(const AutoPaymentState());

  /// Enable auto-payment
  void enable({Duration interval = const Duration(hours: 1)}) {
    _service.start(interval: interval);
    state = state.copyWith(isEnabled: true);
  }

  /// Disable auto-payment
  void disable() {
    _service.stop();
    state = state.copyWith(isEnabled: false);
  }

  /// Process payments manually
  Future<void> processNow() async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _service.processPayments();

    result.fold(
      onSuccess: (data) {
        state = state.copyWith(
          isProcessing: false,
          lastProcessedAt: DateTime.now(),
          error: null,
        );
      },
      onFailure: (exception) {
        state = state.copyWith(
          isProcessing: false,
          error: exception.message,
        );
      },
    );
  }

  /// Toggle auto-payment
  void toggle({Duration interval = const Duration(hours: 1)}) {
    if (state.isEnabled) {
      disable();
    } else {
      enable(interval: interval);
    }
  }
}

/// Provider for auto-payment state
final autoPaymentProvider =
    StateNotifierProvider<AutoPaymentNotifier, AutoPaymentState>((ref) {
  final service = ref.watch(emiAutoPaymentServiceProvider);
  return AutoPaymentNotifier(service);
});
