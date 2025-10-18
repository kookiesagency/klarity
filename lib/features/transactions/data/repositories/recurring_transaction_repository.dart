import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/recurring_transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/models/recurring_frequency.dart';

/// Repository for recurring transaction operations
class RecurringTransactionRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all recurring transactions for profile
  Future<Result<List<RecurringTransactionModel>>> getRecurringTransactions(
    String profileId,
  ) async {
    try {
      final response = await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .order('next_due_date', ascending: true)
          .order('created_at', ascending: false);

      final recurringTransactions = (response as List).map((json) {
        return RecurringTransactionModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(recurringTransactions);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get active recurring transactions for profile
  Future<Result<List<RecurringTransactionModel>>> getActiveRecurringTransactions(
    String profileId,
  ) async {
    try {
      final response = await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .order('next_due_date', ascending: true);

      final recurringTransactions = (response as List).map((json) {
        return RecurringTransactionModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(recurringTransactions);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get recurring transactions by type
  Future<Result<List<RecurringTransactionModel>>> getRecurringTransactionsByType({
    required String profileId,
    required TransactionType type,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .eq('type', type.value)
          .order('next_due_date', ascending: true);

      final recurringTransactions = (response as List).map((json) {
        return RecurringTransactionModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(recurringTransactions);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get recurring transaction by ID
  Future<Result<RecurringTransactionModel>> getRecurringTransactionById(
    String recurringTransactionId,
  ) async {
    try {
      final response = await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('id', recurringTransactionId)
          .single();

      final recurringTransaction = RecurringTransactionModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(recurringTransaction);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create new recurring transaction
  Future<Result<RecurringTransactionModel>> createRecurringTransaction({
    required String profileId,
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
    try {
      final response = await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .insert({
            'profile_id': profileId,
            'account_id': accountId,
            'category_id': categoryId,
            'type': type.value,
            'amount': amount,
            'description': description,
            'frequency': frequency.value,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'next_due_date': nextDueDate.toIso8601String(),
            'is_active': true,
          })
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final recurringTransaction = RecurringTransactionModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(recurringTransaction);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
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
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (accountId != null) updates['account_id'] = accountId;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (type != null) updates['type'] = type.value;
      if (amount != null) updates['amount'] = amount;
      if (description != null) updates['description'] = description;
      if (frequency != null) updates['frequency'] = frequency.value;
      if (startDate != null) updates['start_date'] = startDate.toIso8601String();
      if (endDate != null) updates['end_date'] = endDate.toIso8601String();
      if (nextDueDate != null) updates['next_due_date'] = nextDueDate.toIso8601String();
      if (isActive != null) updates['is_active'] = isActive;

      final response = await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .update(updates)
          .eq('id', recurringTransactionId)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final recurringTransaction = RecurringTransactionModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(recurringTransaction);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete recurring transaction
  Future<Result<void>> deleteRecurringTransaction(
    String recurringTransactionId,
  ) async {
    try {
      await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .delete()
          .eq('id', recurringTransactionId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Toggle active status of recurring transaction
  Future<Result<RecurringTransactionModel>> toggleActiveStatus({
    required String recurringTransactionId,
    required bool isActive,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recurringTransactionId)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final recurringTransaction = RecurringTransactionModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(recurringTransaction);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Process due recurring transactions (calls database function)
  /// This should be called by the background service
  Future<Result<Map<String, dynamic>>> processDueRecurringTransactions() async {
    try {
      final response = await _supabase
          .rpc('process_due_recurring_transactions');

      final result = {
        'created_count': response[0]['created_count'] as int,
        'processed_ids': (response[0]['processed_ids'] as List).cast<String>(),
      };

      return Success(result);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get upcoming recurring transactions (next 7 days)
  Future<Result<List<RecurringTransactionModel>>> getUpcomingRecurringTransactions(
    String profileId,
  ) async {
    try {
      final sevenDaysLater = DateTime.now().add(const Duration(days: 7));

      final response = await _supabase
          .from(ApiConstants.recurringTransactionsTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .lte('next_due_date', sevenDaysLater.toIso8601String())
          .order('next_due_date', ascending: true);

      final recurringTransactions = (response as List).map((json) {
        return RecurringTransactionModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(recurringTransactions);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }
}
