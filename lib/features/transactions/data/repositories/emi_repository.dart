import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/emi_model.dart';
import '../../domain/models/emi_payment_model.dart';

/// Repository for EMI operations
class EmiRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all EMIs for profile
  Future<Result<List<EmiModel>>> getEmis(String profileId) async {
    try {
      print('🔍 Loading EMIs for profile: $profileId');
      final response = await _supabase
          .from(ApiConstants.emisTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .order('next_payment_date', ascending: true)
          .order('created_at', ascending: false);

      print('📦 EMI Response: ${response.length} items');

      final emis = (response as List).map((json) {
        return EmiModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      print('✅ Loaded ${emis.length} EMIs');
      return Success(emis);
    } catch (e, stackTrace) {
      print('❌ Error loading EMIs: $e');
      print('Stack trace: $stackTrace');
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get active EMIs for profile
  Future<Result<List<EmiModel>>> getActiveEmis(String profileId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.emisTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .order('next_payment_date', ascending: true);

      final emis = (response as List).map((json) {
        return EmiModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(emis);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get EMI by ID
  Future<Result<EmiModel>> getEmiById(String emiId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.emisTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('id', emiId)
          .single();

      final emi = EmiModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(emi);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create new EMI
  Future<Result<EmiModel>> createEmi({
    required String profileId,
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
    try {
      // Auto-calculate next payment date
      // Next payment is for installment (paidInstallments + 1)
      // So: next_payment_date = startDate + paidInstallments months
      DateTime nextPaymentDate = DateTime(
        startDate.year,
        startDate.month + paidInstallments,
        paymentDayOfMonth,
      );

      // Handle month-end edge cases
      // If payment day is 31 but month only has 30 days, use last day of month
      if (nextPaymentDate.day < paymentDayOfMonth) {
        // Set to last day of the month
        nextPaymentDate = DateTime(
          nextPaymentDate.year,
          nextPaymentDate.month + 1,
          0,  // Day 0 = last day of previous month
        );
      }

      final response = await _supabase
          .from(ApiConstants.emisTable)
          .insert({
            'profile_id': profileId,
            'account_id': accountId,
            'category_id': categoryId,
            'name': name,
            'description': description,
            'total_amount': totalAmount,
            'monthly_payment': monthlyPayment,
            'total_installments': totalInstallments,
            'paid_installments': paidInstallments,
            'start_date': startDate.toIso8601String(),
            'payment_day_of_month': paymentDayOfMonth,
            'next_payment_date': nextPaymentDate.toIso8601String(),
            'is_active': true,
          })
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final emi = EmiModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      // Create historical transactions if paid installments > 0
      if (paidInstallments > 0) {
        await _createHistoricalTransactions(
          emiId: emi.id,
          profileId: profileId,
          accountId: accountId,
          categoryId: categoryId,
          name: name,
          monthlyPayment: monthlyPayment,
          totalInstallments: totalInstallments,
          paidInstallments: paidInstallments,
          startDate: startDate,
          paymentDayOfMonth: paymentDayOfMonth,
        );
      }

      return Success(emi);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Create historical transactions for EMIs with paid installments
  /// startDate is the ACTUAL EMI start date (when loan was taken)
  Future<void> _createHistoricalTransactions({
    required String emiId,
    required String profileId,
    required String accountId,
    required String categoryId,
    required String name,
    required double monthlyPayment,
    required int totalInstallments,
    required int paidInstallments,
    required DateTime startDate,
    required int paymentDayOfMonth,
  }) async {
    // Create payments going FORWARD from EMI start date
    // Example: startDate = Feb 15, 2024, paidInstallments = 12
    // Payment 1: Feb 15, 2024 (startDate + 0 months)
    // Payment 2: Mar 15, 2024 (startDate + 1 month)
    // Payment 12: Jan 15, 2025 (startDate + 11 months)

    for (int i = 1; i <= paidInstallments; i++) {
      // Calculate payment date going forward from start date
      final monthsFromStart = i - 1;  // Payment 1 = 0 months from start
      DateTime paymentDate = DateTime(
        startDate.year,
        startDate.month + monthsFromStart,
        paymentDayOfMonth,
      );

      // Handle month-end edge cases
      // If payment day is 31 but month only has 30 days, use last day of month
      if (paymentDate.day < paymentDayOfMonth) {
        // Set to last day of the month
        paymentDate = DateTime(
          paymentDate.year,
          paymentDate.month + 1,
          0,  // Day 0 = last day of previous month
        );
      }

      // Create transaction with historical payment date
      final transactionResponse = await _supabase
          .from(ApiConstants.transactionsTable)
          .insert({
            'profile_id': profileId,
            'account_id': accountId,
            'category_id': categoryId,
            'type': 'expense',
            'amount': monthlyPayment,
            'description': '$name - EMI Payment $i/$totalInstallments',
            'transaction_date': paymentDate.toIso8601String(),
            'is_locked': false,
          })
          .select('id, profile_id, account_id, category_id, type, amount, description, transaction_date, is_locked, created_at, updated_at')
          .single();

      final transactionId = transactionResponse['id'] as String;

      // Create EMI payment record
      await _supabase
          .from(ApiConstants.emiPaymentsTable)
          .insert({
            'emi_id': emiId,
            'transaction_id': transactionId,
            'installment_number': i,
            'amount': monthlyPayment,
            'payment_date': paymentDate.toIso8601String(),
            'due_date': paymentDate.toIso8601String(),
            'is_paid': true,
            'notes': 'Historical payment',
          });
    }
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
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (accountId != null) updates['account_id'] = accountId;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (isActive != null) updates['is_active'] = isActive;

      final response = await _supabase
          .from(ApiConstants.emisTable)
          .update(updates)
          .eq('id', emiId)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final emi = EmiModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(emi);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete EMI and all related transactions
  Future<Result<void>> deleteEmi(String emiId) async {
    try {
      // Get all emi_payment records to find related transactions
      final paymentsResponse = await _supabase
          .from(ApiConstants.emiPaymentsTable)
          .select('transaction_id')
          .eq('emi_id', emiId);

      // Extract transaction IDs
      final transactionIds = (paymentsResponse as List)
          .map((payment) => payment['transaction_id'] as String)
          .toList();

      // Delete all related transactions
      if (transactionIds.isNotEmpty) {
        await _supabase
            .from(ApiConstants.transactionsTable)
            .delete()
            .inFilter('id', transactionIds);
      }

      // Delete the EMI (this will CASCADE delete emi_payments)
      await _supabase
          .from(ApiConstants.emisTable)
          .delete()
          .eq('id', emiId);

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Toggle active status
  Future<Result<EmiModel>> toggleActiveStatus({
    required String emiId,
    required bool isActive,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.emisTable)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', emiId)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final emi = EmiModel.fromJson({
        ...response,
        'account_name': response['accounts']?['name'],
        'category_name': response['categories']?['name'],
        'category_icon': response['categories']?['icon'],
      });

      return Success(emi);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  // ==================== EMI PAYMENT OPERATIONS ====================

  /// Get payment history for an EMI
  Future<Result<List<EmiPaymentModel>>> getEmiPayments(String emiId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.emiPaymentsTable)
          .select('*')
          .eq('emi_id', emiId)
          .order('installment_number', ascending: true);

      final payments = (response as List).map((json) {
        return EmiPaymentModel.fromJson(json);
      }).toList();

      return Success(payments);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Process due EMI payments (calls database function)
  Future<Result<Map<String, dynamic>>> processDueEmiPayments() async {
    try {
      final response = await _supabase
          .rpc('process_due_emi_payments');

      final result = {
        'created_count': response[0]['created_count'] as int,
        'processed_emi_ids': (response[0]['processed_emi_ids'] as List).cast<String>(),
      };

      return Success(result);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get upcoming EMI payments (next 7 days)
  Future<Result<List<EmiModel>>> getUpcomingEmiPayments(String profileId) async {
    try {
      final sevenDaysLater = DateTime.now().add(const Duration(days: 7));

      final response = await _supabase
          .from(ApiConstants.emisTable)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .lte('next_payment_date', sevenDaysLater.toIso8601String())
          .order('next_payment_date', ascending: true);

      final emis = (response as List).map((json) {
        return EmiModel.fromJson({
          ...json,
          'account_name': json['accounts']?['name'],
          'category_name': json['categories']?['name'],
          'category_icon': json['categories']?['icon'],
        });
      }).toList();

      return Success(emis);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Delete EMI payment record
  Future<Result<EmiModel>> deleteEmiPayment({
    required String emiId,
    required String paymentId,
  }) async {
    try {
      // Get EMI details first
      final emiResult = await getEmiById(emiId);
      if (emiResult is! Success<EmiModel>) {
        return emiResult as Failure<EmiModel>;
      }
      final emi = emiResult.value;

      // Get the payment details
      final paymentResponse = await _supabase
          .from(ApiConstants.emiPaymentsTable)
          .select('*')
          .eq('id', paymentId)
          .single();

      final transactionId = paymentResponse['transaction_id'] as String;

      // Delete the transaction
      await _supabase
          .from(ApiConstants.transactionsTable)
          .delete()
          .eq('id', transactionId);

      // Delete the EMI payment record
      await _supabase
          .from(ApiConstants.emiPaymentsTable)
          .delete()
          .eq('id', paymentId);

      // Calculate new paid installments
      final newPaidInstallments = emi.paidInstallments - 1;

      // Calculate new next payment date (go back one month)
      DateTime newNextPayment = DateTime(
        emi.nextPaymentDate.year,
        emi.nextPaymentDate.month - 1,
        emi.paymentDayOfMonth,
      );

      // Handle month-end edge cases
      if (newNextPayment.day < emi.paymentDayOfMonth) {
        // Set to last day of the month
        newNextPayment = DateTime(
          newNextPayment.year,
          newNextPayment.month + 1,
          0,
        );
      }

      // Update EMI record
      final updatedEmiResponse = await _supabase
          .from(ApiConstants.emisTable)
          .update({
            'paid_installments': newPaidInstallments,
            'next_payment_date': newNextPayment.toIso8601String(),
            'is_active': true, // Reactivate if it was completed
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', emiId)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final updatedEmi = EmiModel.fromJson({
        ...updatedEmiResponse,
        'account_name': updatedEmiResponse['accounts']?['name'],
        'category_name': updatedEmiResponse['categories']?['name'],
        'category_icon': updatedEmiResponse['categories']?['icon'],
      });

      return Success(updatedEmi);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Record manual EMI payment - creates ALL missed payments
  Future<Result<EmiModel>> recordManualPayment({
    required String emiId,
    required DateTime paymentDate,
  }) async {
    try {
      // Get EMI details first
      final emiResult = await getEmiById(emiId);
      if (emiResult is! Success<EmiModel>) {
        return emiResult as Failure<EmiModel>;
      }
      final emi = emiResult.value;

      // Check if EMI is already completed
      if (emi.paidInstallments >= emi.totalInstallments) {
        return Failure(ErrorHandler.handle(
          Exception('EMI is already completed'),
        ));
      }

      // Calculate how many payments are due (missed)
      // Count payments from next due date up to today
      int paymentsToCreate = 0;
      DateTime checkDate = emi.nextPaymentDate;
      final now = DateTime.now();

      while (checkDate.isBefore(now) || checkDate.isAtSameMomentAs(now)) {
        paymentsToCreate++;
        // Calculate next month
        checkDate = DateTime(
          checkDate.year,
          checkDate.month + 1,
          emi.paymentDayOfMonth,
        );
        // Handle month-end edge cases
        if (checkDate.day < emi.paymentDayOfMonth) {
          checkDate = DateTime(checkDate.year, checkDate.month + 1, 0);
        }

        // Safety check - don't exceed remaining installments
        if (emi.paidInstallments + paymentsToCreate >= emi.totalInstallments) {
          paymentsToCreate = emi.totalInstallments - emi.paidInstallments;
          break;
        }
      }

      // If no payments due yet, create just one payment
      if (paymentsToCreate == 0) {
        paymentsToCreate = 1;
      }

      // Create all missed payments
      DateTime currentDueDate = emi.nextPaymentDate;
      for (int i = 0; i < paymentsToCreate; i++) {
        final installmentNumber = emi.paidInstallments + i + 1;

        // Create transaction with CURRENT DATE as payment_date
        final transactionResponse = await _supabase
            .from(ApiConstants.transactionsTable)
            .insert({
              'profile_id': emi.profileId,
              'account_id': emi.accountId,
              'category_id': emi.categoryId,
              'type': 'expense',
              'amount': emi.monthlyPayment,
              'description': '${emi.name} - EMI Payment $installmentNumber/${emi.totalInstallments}',
              'transaction_date': paymentDate.toIso8601String(),  // Use CURRENT date
              'is_locked': false,
            })
            .select('id, profile_id, account_id, category_id, type, amount, description, transaction_date, is_locked, created_at, updated_at')
            .single();

        final transactionId = transactionResponse['id'] as String;

        // Record EMI payment
        await _supabase
            .from(ApiConstants.emiPaymentsTable)
            .insert({
              'emi_id': emiId,
              'transaction_id': transactionId,
              'installment_number': installmentNumber,
              'amount': emi.monthlyPayment,
              'payment_date': paymentDate.toIso8601String(),  // Use CURRENT date
              'due_date': currentDueDate.toIso8601String(),  // Use actual due date
              'is_paid': true,
              'notes': 'Manual payment',
            });

        // Calculate next due date for the loop
        currentDueDate = DateTime(
          currentDueDate.year,
          currentDueDate.month + 1,
          emi.paymentDayOfMonth,
        );
        // Handle month-end edge cases
        if (currentDueDate.day < emi.paymentDayOfMonth) {
          currentDueDate = DateTime(
            currentDueDate.year,
            currentDueDate.month + 1,
            0,
          );
        }
      }

      // Calculate final next payment date
      DateTime nextPayment = currentDueDate;

      // Update EMI record
      final updatedPaidInstallments = emi.paidInstallments + paymentsToCreate;
      final isCompleted = updatedPaidInstallments >= emi.totalInstallments;

      final updatedEmiResponse = await _supabase
          .from(ApiConstants.emisTable)
          .update({
            'paid_installments': updatedPaidInstallments,
            'next_payment_date': nextPayment.toIso8601String(),
            'is_active': !isCompleted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', emiId)
          .select('''
            *,
            accounts!inner(name),
            categories!inner(name, icon)
          ''')
          .single();

      final updatedEmi = EmiModel.fromJson({
        ...updatedEmiResponse,
        'account_name': updatedEmiResponse['accounts']?['name'],
        'category_name': updatedEmiResponse['categories']?['name'],
        'category_icon': updatedEmiResponse['categories']?['icon'],
      });

      return Success(updatedEmi);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }
}
