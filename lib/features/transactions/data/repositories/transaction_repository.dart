import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/models/transfer_model.dart';

/// Repository for transaction operations
class TransactionRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all transactions for current profile
  Future<Result<List<TransactionModel>>> getTransactions(String profileId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .select('''
            id, profile_id, account_id, category_id, type, amount, description,
            transaction_date, is_locked, created_at, updated_at,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      final transactions = (response as List).map((json) {
        return TransactionModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(transactions);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get paginated transactions for current profile
  /// Optimized for lazy loading with limit and offset
  Future<Result<List<TransactionModel>>> getTransactionsPaginated({
    required String profileId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .select('''
            id, profile_id, account_id, category_id, type, amount, description,
            transaction_date, is_locked, created_at, updated_at,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final transactions = (response as List).map((json) {
        return TransactionModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(transactions);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get transactions by account
  Future<Result<List<TransactionModel>>> getTransactionsByAccount({
    required String profileId,
    required String accountId,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .select('''
            id, profile_id, account_id, category_id, type, amount, description,
            transaction_date, is_locked, created_at, updated_at,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .eq('account_id', accountId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      final transactions = (response as List).map((json) {
        return TransactionModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(transactions);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get transactions by date range
  Future<Result<List<TransactionModel>>> getTransactionsByDateRange({
    required String profileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .select('''
            id, profile_id, account_id, category_id, type, amount, description,
            transaction_date, is_locked, created_at, updated_at,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .gte('transaction_date', startDate.toIso8601String())
          .lte('transaction_date', endDate.toIso8601String())
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      final transactions = (response as List).map((json) {
        return TransactionModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(transactions);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get transaction by ID
  Future<Result<TransactionModel>> getTransactionById(String transactionId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .select('''
            id, profile_id, account_id, category_id, type, amount, description,
            transaction_date, is_locked, created_at, updated_at,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('id', transactionId)
          .single();

      final transaction = TransactionModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(transaction);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create new transaction
  Future<Result<TransactionModel>> createTransaction({
    required String profileId,
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    String? description,
    required DateTime transactionDate,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .insert({
            'profile_id': profileId,
            'account_id': accountId,
            'category_id': categoryId,
            'type': type.value,
            'amount': amount,
            'description': description,
            'transaction_date': transactionDate.toIso8601String(),
            'is_locked': false,
          })
          .select('''
            id, profile_id, account_id, category_id, type, amount, description,
            transaction_date, is_locked, created_at, updated_at,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final transaction = TransactionModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(transaction);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
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
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (accountId != null) updates['account_id'] = accountId;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (type != null) updates['type'] = type.value;
      if (amount != null) updates['amount'] = amount;
      if (description != null) updates['description'] = description;
      if (transactionDate != null) updates['transaction_date'] = transactionDate.toIso8601String();

      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .update(updates)
          .eq('id', transactionId)
          .select('''
            id, profile_id, account_id, category_id, type, amount, description,
            transaction_date, is_locked, created_at, updated_at,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final transaction = TransactionModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(transaction);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete transaction
  Future<Result<void>> deleteTransaction(String transactionId) async {
    try {
      await _supabase
          .from(ApiConstants.transactionsTable)
          .delete()
          .eq('id', transactionId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Bulk delete transactions
  Future<Result<void>> bulkDeleteTransactions(List<String> transactionIds) async {
    try {
      await _supabase
          .from(ApiConstants.transactionsTable)
          .delete()
          .inFilter('id', transactionIds);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Bulk update category
  Future<Result<void>> bulkUpdateCategory({
    required List<String> transactionIds,
    required String categoryId,
  }) async {
    try {
      await _supabase
          .from(ApiConstants.transactionsTable)
          .update({
            'category_id': categoryId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', transactionIds);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Bulk update account
  Future<Result<void>> bulkUpdateAccount({
    required List<String> transactionIds,
    required String accountId,
  }) async {
    try {
      await _supabase
          .from(ApiConstants.transactionsTable)
          .update({
            'account_id': accountId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', transactionIds);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  // ==================== TRANSFER OPERATIONS ====================

  /// Get all transfers for profile
  Future<Result<List<TransferModel>>> getTransfers(String profileId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.transfersTable)
          .select('''
            *,
            from_account:accounts!transfers_from_account_id_fkey(name),
            to_account:accounts!transfers_to_account_id_fkey(name)
          ''')
          .eq('profile_id', profileId)
          .order('transfer_date', ascending: false)
          .order('created_at', ascending: false);

      final transfers = (response as List).map((json) {
        return TransferModel.fromJson({
          ...json,
          'from_account_name': json['from_account']?['name'],
          'to_account_name': json['to_account']?['name'],
        });
      }).toList();

      return Success(transfers);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create new transfer
  Future<Result<TransferModel>> createTransfer({
    required String profileId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
    required DateTime transferDate,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.transfersTable)
          .insert({
            'profile_id': profileId,
            'from_account_id': fromAccountId,
            'to_account_id': toAccountId,
            'amount': amount,
            'description': description,
            'transfer_date': transferDate.toIso8601String(),
          })
          .select('''
            *,
            from_account:accounts!transfers_from_account_id_fkey(name),
            to_account:accounts!transfers_to_account_id_fkey(name)
          ''')
          .single();

      final transfer = TransferModel.fromJson({
        ...response,
        'from_account_name': response['from_account']?['name'],
        'to_account_name': response['to_account']?['name'],
      });

      return Success(transfer);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete transfer
  Future<Result<void>> deleteTransfer(String transferId) async {
    try {
      await _supabase
          .from(ApiConstants.transfersTable)
          .delete()
          .eq('id', transferId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  // ==================== TRANSACTION LOCKING OPERATIONS ====================

  /// Auto-lock transactions older than 2 months
  Future<Result<int>> autoLockOldTransactions(String profileId) async {
    try {
      final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));

      print('🔒 Auto-lock: Checking transactions before ${twoMonthsAgo.toIso8601String()}');

      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .update({
            'is_locked': true,
            'locked_at': DateTime.now().toIso8601String(),
          })
          .eq('profile_id', profileId)
          .lt('transaction_date', twoMonthsAgo.toIso8601String())
          .eq('is_locked', false)
          .select('id');

      final count = (response as List).length;
      print('🔒 Auto-lock: Locked $count transactions');
      return Success(count);
    } catch (e, stackTrace) {
      print('❌ Auto-lock failed: $e');
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Unlock a specific transaction
  Future<Result<void>> unlockTransaction(String transactionId) async {
    try {
      await _supabase
          .from(ApiConstants.transactionsTable)
          .update({
            'is_locked': false,
            'locked_at': null,
          })
          .eq('id', transactionId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }
}
