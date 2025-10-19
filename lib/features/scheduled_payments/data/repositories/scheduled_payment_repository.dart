import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../domain/models/scheduled_payment_model.dart';
import '../../domain/models/scheduled_payment_status.dart';
import '../../domain/models/payment_history_model.dart';

/// Repository for scheduled payment operations
class ScheduledPaymentRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all scheduled payments for a profile
  Future<Result<List<ScheduledPaymentModel>>> getScheduledPayments(
    String profileId,
  ) async {
    try {
      final response = await _supabase
          .from('scheduled_payments')
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .order('due_date', ascending: true);

      final payments = (response as List).map((json) {
        return ScheduledPaymentModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(payments);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get scheduled payments by status
  Future<Result<List<ScheduledPaymentModel>>> getScheduledPaymentsByStatus({
    required String profileId,
    required ScheduledPaymentStatus status,
  }) async {
    try {
      final response = await _supabase
          .from('scheduled_payments')
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .eq('status', status.value)
          .order('due_date', ascending: true);

      final payments = (response as List).map((json) {
        return ScheduledPaymentModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(payments);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get upcoming scheduled payments (due within next 30 days)
  Future<Result<List<ScheduledPaymentModel>>> getUpcomingPayments(
    String profileId,
  ) async {
    try {
      final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));

      final response = await _supabase
          .from('scheduled_payments')
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .inFilter('status', ['pending', 'partial'])
          .lte('due_date', thirtyDaysFromNow.toIso8601String())
          .gte('due_date', DateTime.now().toIso8601String())
          .order('due_date', ascending: true)
          .limit(10);

      final payments = (response as List).map((json) {
        return ScheduledPaymentModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(payments);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get scheduled payment by ID
  Future<Result<ScheduledPaymentModel>> getScheduledPaymentById(
    String paymentId,
  ) async {
    try {
      final response = await _supabase
          .from('scheduled_payments')
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('id', paymentId)
          .single();

      final payment = ScheduledPaymentModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(payment);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create a scheduled payment
  Future<Result<ScheduledPaymentModel>> createScheduledPayment({
    required String profileId,
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
    try {
      final response = await _supabase
          .from('scheduled_payments')
          .insert({
            'profile_id': profileId,
            'account_id': accountId,
            'category_id': categoryId,
            'type': type.value,
            'amount': amount,
            'total_amount': amount,
            'payee_name': payeeName,
            'description': description,
            'due_date': dueDate.toIso8601String(),
            'reminder_date': reminderDate?.toIso8601String(),
            'allow_partial_payment': allowPartialPayment,
            'auto_create_transaction': autoCreateTransaction,
          })
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final payment = ScheduledPaymentModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(payment);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
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
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (accountId != null) updates['account_id'] = accountId;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (type != null) updates['type'] = type.value;
      if (amount != null) {
        updates['amount'] = amount;
        updates['total_amount'] = amount;
      }
      if (payeeName != null) updates['payee_name'] = payeeName;
      if (description != null) updates['description'] = description;
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (reminderDate != null) {
        updates['reminder_date'] = reminderDate.toIso8601String();
      }
      if (allowPartialPayment != null) {
        updates['allow_partial_payment'] = allowPartialPayment;
      }
      if (autoCreateTransaction != null) {
        updates['auto_create_transaction'] = autoCreateTransaction;
      }

      final response = await _supabase
          .from('scheduled_payments')
          .update(updates)
          .eq('id', paymentId)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final payment = ScheduledPaymentModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(payment);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete a scheduled payment
  Future<Result<void>> deleteScheduledPayment(String paymentId) async {
    try {
      await _supabase
          .from('scheduled_payments')
          .delete()
          .eq('id', paymentId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Cancel a scheduled payment
  Future<Result<void>> cancelScheduledPayment(String paymentId) async {
    try {
      await _supabase
          .from('scheduled_payments')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  // ==================== PAYMENT HISTORY OPERATIONS ====================

  /// Get payment history for a scheduled payment
  Future<Result<List<PaymentHistoryModel>>> getPaymentHistory(
    String scheduledPaymentId,
  ) async {
    try {
      final response = await _supabase
          .from('scheduled_payment_history')
          .select()
          .eq('scheduled_payment_id', scheduledPaymentId)
          .order('payment_date', ascending: false);

      final history = (response as List)
          .map((json) => PaymentHistoryModel.fromJson(json))
          .toList();

      return Success(history);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Record a manual payment
  Future<Result<PaymentHistoryModel>> recordPayment({
    required String scheduledPaymentId,
    required double amount,
    String? transactionId,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('scheduled_payment_history')
          .insert({
            'scheduled_payment_id': scheduledPaymentId,
            'transaction_id': transactionId,
            'amount': amount,
            'payment_date': DateTime.now().toIso8601String(),
            'payment_type': transactionId != null ? 'auto' : 'manual',
            'notes': notes,
          })
          .select()
          .single();

      final history = PaymentHistoryModel.fromJson(response);
      return Success(history);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete a payment history entry
  Future<Result<void>> deletePaymentHistory(String historyId) async {
    try {
      await _supabase
          .from('scheduled_payment_history')
          .delete()
          .eq('id', historyId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  // ==================== AUTO-PROCESSING ====================

  /// Process due scheduled payments
  /// Calls the database function to auto-create transactions
  Future<Result<int>> processDuePayments() async {
    try {
      final response = await _supabase.rpc('process_due_scheduled_payments');

      final result = response as Map<String, dynamic>;
      final processedCount = result['processed_count'] as int? ?? 0;

      return Success(processedCount);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }
}
