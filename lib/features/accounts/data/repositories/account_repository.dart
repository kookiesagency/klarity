import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/account_model.dart';
import '../../domain/models/account_type.dart';

/// Repository for account operations
class AccountRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all accounts for current profile
  Future<Result<List<AccountModel>>> getAccounts(String profileId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.accountsTable)
          .select()
          .eq('profile_id', profileId)
          .order('created_at', ascending: true);

      final accounts = (response as List)
          .map((json) => AccountModel.fromJson(json))
          .toList();

      return Success(accounts);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get account by ID
  Future<Result<AccountModel>> getAccountById(String accountId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.accountsTable)
          .select()
          .eq('id', accountId)
          .single();

      final account = AccountModel.fromJson(response);
      return Success(account);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create new account
  Future<Result<AccountModel>> createAccount({
    required String profileId,
    required String name,
    required AccountType type,
    double openingBalance = 0.0,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.accountsTable)
          .insert({
            'profile_id': profileId,
            'name': name,
            'type': type.value,
            'opening_balance': openingBalance,
            'current_balance': openingBalance,
            'is_active': true,
          })
          .select()
          .single();

      final account = AccountModel.fromJson(response);
      return Success(account);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Update account
  Future<Result<AccountModel>> updateAccount({
    required String accountId,
    required String name,
  }) async {
    try {
      final updates = <String, dynamic>{
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(ApiConstants.accountsTable)
          .update(updates)
          .eq('id', accountId)
          .select()
          .single();

      final account = AccountModel.fromJson(response);
      return Success(account);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete account (hard delete)
  Future<Result<void>> deleteAccount(String accountId) async {
    try {
      await _supabase
          .from(ApiConstants.accountsTable)
          .delete()
          .eq('id', accountId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Update account balance (for transactions)
  Future<Result<AccountModel>> updateAccountBalance({
    required String accountId,
    required double newBalance,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.accountsTable)
          .update({
            'current_balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', accountId)
          .select()
          .single();

      final account = AccountModel.fromJson(response);
      return Success(account);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create default accounts for new profile (SBI, HDFC, ICICI banks)
  Future<Result<List<AccountModel>>> createDefaultAccounts(String profileId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.accountsTable)
          .insert([
            {
              'profile_id': profileId,
              'name': 'SBI Savings',
              'type': AccountType.savings.value,
              'opening_balance': 0.0,
              'current_balance': 0.0,
              'is_active': true,
            },
            {
              'profile_id': profileId,
              'name': 'HDFC Savings',
              'type': AccountType.savings.value,
              'opening_balance': 0.0,
              'current_balance': 0.0,
              'is_active': true,
            },
            {
              'profile_id': profileId,
              'name': 'ICICI Savings',
              'type': AccountType.savings.value,
              'opening_balance': 0.0,
              'current_balance': 0.0,
              'is_active': true,
            },
          ])
          .select();

      final accounts = (response as List)
          .map((json) => AccountModel.fromJson(json))
          .toList();

      return Success(accounts);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }
}
