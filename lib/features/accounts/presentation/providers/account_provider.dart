import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/account_repository.dart';
import '../../domain/models/account_model.dart';
import '../../domain/models/account_type.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/models/profile_model.dart';

/// Provider for AccountRepository
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// Account state
class AccountState {
  final List<AccountModel> accounts;
  final AccountModel? activeAccount;
  final bool isLoading;
  final String? error;

  const AccountState({
    this.accounts = const [],
    this.activeAccount,
    this.isLoading = false,
    this.error,
  });

  AccountState copyWith({
    List<AccountModel>? accounts,
    AccountModel? activeAccount,
    bool? isLoading,
    String? error,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      activeAccount: activeAccount ?? this.activeAccount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Account notifier
class AccountNotifier extends StateNotifier<AccountState> {
  final AccountRepository _repository;
  final Ref _ref;
  static const String _activeAccountKey = 'active_account_id';

  AccountNotifier(this._repository, this._ref) : super(const AccountState()) {
    // Listen to profile changes
    _ref.listen<ProfileModel?>(
      activeProfileProvider,
      (previous, next) {
        if (next != null) {
          // Delay state modification to avoid build-time updates
          Future.microtask(() {
            loadAccounts(next.id);
          });
        }
      },
    );

    // Try initial load
    _initialize();
  }

  /// Initialize accounts
  Future<void> _initialize() async {
    // Delay to avoid modifying state during widget build
    Future.microtask(() async {
      final activeProfile = _ref.read(activeProfileProvider);
      if (activeProfile == null) return;

      await loadAccounts(activeProfile.id);
    });
  }

  /// Load all accounts for profile
  Future<void> loadAccounts(String profileId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.getAccounts(profileId);

    result.fold(
      onSuccess: (accounts) async {
        state = state.copyWith(
          accounts: accounts,
          isLoading: false,
          error: null,
        );

        // Load active account from storage
        if (accounts.isNotEmpty) {
          await _loadActiveAccount();
        }
      },
      onFailure: (exception) {
        state = state.copyWith(
          isLoading: false,
          error: exception.message,
        );
      },
    );
  }

  /// Create default accounts (Cash, Bank, Credit Card)
  Future<void> _createDefaultAccounts(String profileId) async {
    final result = await _repository.createDefaultAccounts(profileId);

    result.fold(
      onSuccess: (accounts) async {
        state = state.copyWith(
          accounts: accounts,
          activeAccount: accounts.isNotEmpty ? accounts.first : null,
        );

        // Save first account as active
        if (accounts.isNotEmpty) {
          await _saveActiveAccount(accounts.first.id);
        }
      },
      onFailure: (exception) {
        state = state.copyWith(error: exception.message);
      },
    );
  }

  /// Load active account from storage
  Future<void> _loadActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final activeAccountId = prefs.getString(_activeAccountKey);

    if (activeAccountId != null) {
      final account = state.accounts.firstWhere(
        (a) => a.id == activeAccountId,
        orElse: () => state.accounts.first,
      );
      state = state.copyWith(activeAccount: account);
    } else if (state.accounts.isNotEmpty) {
      // Default to first account
      state = state.copyWith(activeAccount: state.accounts.first);
      await _saveActiveAccount(state.accounts.first.id);
    }
  }

  /// Save active account to storage
  Future<void> _saveActiveAccount(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeAccountKey, accountId);
  }

  /// Switch active account
  Future<void> switchAccount(String accountId) async {
    final account = state.accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => throw DatabaseException.notFound(),
    );

    state = state.copyWith(activeAccount: account);
    await _saveActiveAccount(accountId);
  }

  /// Create new account
  Future<Result<AccountModel>> createAccount({
    required String name,
    required AccountType type,
    double openingBalance = 0.0,
  }) async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile == null) {
      return Failure(ValidationException('No active profile'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.createAccount(
      profileId: activeProfile.id,
      name: name,
      type: type,
      openingBalance: openingBalance,
    );

    result.fold(
      onSuccess: (account) {
        state = state.copyWith(
          accounts: [...state.accounts, account],
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

  /// Update account
  Future<Result<AccountModel>> updateAccount({
    required String accountId,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.updateAccount(
      accountId: accountId,
      name: name,
    );

    result.fold(
      onSuccess: (updatedAccount) {
        final List<AccountModel> updatedAccounts = state.accounts.map((a) {
          return a.id == accountId ? updatedAccount : a;
        }).toList();

        state = state.copyWith(
          accounts: updatedAccounts,
          activeAccount: state.activeAccount?.id == accountId
              ? updatedAccount
              : state.activeAccount,
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

  /// Delete account
  Future<Result<void>> deleteAccount(String accountId) async {
    // Prevent deleting the last account
    if (state.accounts.length <= 1) {
      return Failure(ValidationException('Cannot delete the last account'));
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteAccount(accountId);

    result.fold(
      onSuccess: (_) async {
        final updatedAccounts =
            state.accounts.where((a) => a.id != accountId).toList();

        // If deleted account was active, switch to first available
        AccountModel? newActiveAccount = state.activeAccount;
        if (state.activeAccount?.id == accountId) {
          newActiveAccount = updatedAccounts.isNotEmpty ? updatedAccounts.first : null;
          if (newActiveAccount != null) {
            await _saveActiveAccount(newActiveAccount.id);
          }
        }

        state = state.copyWith(
          accounts: updatedAccounts,
          activeAccount: newActiveAccount,
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

  /// Refresh accounts
  Future<void> refresh() async {
    final activeProfile = _ref.read(activeProfileProvider);
    if (activeProfile != null) {
      await loadAccounts(activeProfile.id);
    }
  }
}

/// Account provider
final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  return AccountNotifier(repository, ref);
});

/// Active account provider
final activeAccountProvider = Provider<AccountModel?>((ref) {
  final accountState = ref.watch(accountProvider);
  return accountState.activeAccount;
});

/// Accounts list provider
final accountsListProvider = Provider<List<AccountModel>>((ref) {
  final accountState = ref.watch(accountProvider);
  return accountState.accounts;
});
