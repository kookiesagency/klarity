import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/models/profile_model.dart';

/// Low balance alert model
class LowBalanceAlert {
  final AccountModel account;
  final double threshold;
  final DateTime alertTime;

  const LowBalanceAlert({
    required this.account,
    required this.threshold,
    required this.alertTime,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LowBalanceAlert && other.account.id == account.id;
  }

  @override
  int get hashCode => account.id.hashCode;
}

/// Low balance alert state
class LowBalanceAlertState {
  final List<LowBalanceAlert> alerts;
  final bool isChecking;

  const LowBalanceAlertState({
    this.alerts = const [],
    this.isChecking = false,
  });

  LowBalanceAlertState copyWith({
    List<LowBalanceAlert>? alerts,
    bool? isChecking,
  }) {
    return LowBalanceAlertState(
      alerts: alerts ?? this.alerts,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

/// Low balance alert notifier
class LowBalanceAlertNotifier extends StateNotifier<LowBalanceAlertState> {
  final Ref _ref;

  LowBalanceAlertNotifier(this._ref) : super(const LowBalanceAlertState()) {
    // Listen to account changes
    _ref.listen<List<AccountModel>>(
      accountsListProvider,
      (previous, next) {
        Future.microtask(() {
          _checkLowBalanceAccounts();
        });
      },
    );

    // Initial check
    Future.microtask(() {
      _checkLowBalanceAccounts();
    });
  }

  /// Check all accounts for low balance
  Future<void> _checkLowBalanceAccounts() async {
    state = state.copyWith(isChecking: true);

    final accounts = _ref.read(accountsListProvider);
    final activeProfile = _ref.read(activeProfileProvider);

    if (activeProfile == null) {
      state = state.copyWith(alerts: [], isChecking: false);
      return;
    }

    final threshold = activeProfile.lowBalanceThreshold;
    final newAlerts = <LowBalanceAlert>[];

    for (final account in accounts) {
      if (account.currentBalance < threshold) {
        newAlerts.add(LowBalanceAlert(
          account: account,
          threshold: threshold,
          alertTime: DateTime.now(),
        ));
      }
    }

    state = state.copyWith(
      alerts: newAlerts,
      isChecking: false,
    );
  }

  /// Manually trigger alert check (call this after transactions)
  Future<void> checkAfterTransaction(String accountId) async {
    await _ref.read(accountProvider.notifier).refresh();
    await _checkLowBalanceAccounts();
  }

  /// Dismiss alert for an account
  void dismissAlert(String accountId) {
    final updatedAlerts = state.alerts
        .where((alert) => alert.account.id != accountId)
        .toList();
    state = state.copyWith(alerts: updatedAlerts);
  }

  /// Dismiss all alerts
  void dismissAll() {
    state = state.copyWith(alerts: []);
  }

  /// Get alert for specific account
  LowBalanceAlert? getAlertForAccount(String accountId) {
    try {
      return state.alerts.firstWhere(
        (alert) => alert.account.id == accountId,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Low balance alert provider
final lowBalanceAlertProvider = StateNotifierProvider<LowBalanceAlertNotifier, LowBalanceAlertState>((ref) {
  return LowBalanceAlertNotifier(ref);
});

/// Has low balance alerts provider
final hasLowBalanceAlertsProvider = Provider<bool>((ref) {
  final alertState = ref.watch(lowBalanceAlertProvider);
  return alertState.alerts.isNotEmpty;
});

/// Low balance accounts count provider
final lowBalanceAccountsCountProvider = Provider<int>((ref) {
  final alertState = ref.watch(lowBalanceAlertProvider);
  return alertState.alerts.length;
});
