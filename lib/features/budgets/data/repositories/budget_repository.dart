import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/exceptions.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/models/budget_period.dart';

/// Budget repository for database operations
class BudgetRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all budgets for a profile
  Future<Result<List<BudgetModel>>> getBudgets(String profileId) async {
    try {
      // Optimized: Single query with composite index on (profile_id, is_active)
      final response = await _supabase
          .from(ApiConstants.budgetsTable)
          .select()
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final budgets = (response as List)
          .map((json) => BudgetModel.fromJson(json))
          .toList();

      return Success(budgets);
    } on PostgrestException catch (e) {
      return Failure(DatabaseException(e.message));
    } catch (e) {
      return Failure(DatabaseException('Failed to load budgets: $e'));
    }
  }

  /// Get budget for a specific category
  Future<Result<BudgetModel?>> getBudgetForCategory({
    required String profileId,
    required String categoryId,
    BudgetPeriod period = BudgetPeriod.monthly,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from(ApiConstants.budgetsTable)
          .select()
          .eq('profile_id', profileId)
          .eq('category_id', categoryId)
          .eq('period', period.value)
          .eq('is_active', true)
          .lte('start_date', now.toIso8601String().split('T')[0])
          .or('end_date.is.null,end_date.gte.${now.toIso8601String().split('T')[0]}')
          .maybeSingle();

      if (response == null) {
        return const Success(null);
      }

      final budget = BudgetModel.fromJson(response);
      return Success(budget);
    } on PostgrestException catch (e) {
      return Failure(DatabaseException(e.message));
    } catch (e) {
      return Failure(DatabaseException('Failed to load budget: $e'));
    }
  }

  /// Create a new budget
  Future<Result<BudgetModel>> createBudget({
    required String profileId,
    required String categoryId,
    required double amount,
    BudgetPeriod period = BudgetPeriod.monthly,
    DateTime? startDate,
    DateTime? endDate,
    int alertThreshold = 80,
  }) async {
    try {
      print('💾 Creating budget:');
      print('  - profile_id: $profileId');
      print('  - category_id: $categoryId');
      print('  - amount: $amount');
      print('  - period: ${period.value}');
      print('  - alert_threshold: $alertThreshold');

      final now = DateTime.now();
      final insertData = {
        'profile_id': profileId,
        'category_id': categoryId,
        'amount': amount,
        'period': period.value,
        'start_date': (startDate ?? now).toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'alert_threshold': alertThreshold,
        'is_active': true,
      };

      print('📤 Inserting data: $insertData');

      final response = await _supabase
          .from(ApiConstants.budgetsTable)
          .insert(insertData)
          .select()
          .single();

      print('✅ Budget created successfully: ${response['id']}');
      print('   Response: $response');

      final budget = BudgetModel.fromJson(response);
      return Success(budget);
    } on PostgrestException catch (e) {
      print('❌ PostgrestException in createBudget: ${e.message} (code: ${e.code})');
      if (e.code == '23505') {
        // Unique constraint violation
        return Failure(ValidationException('Budget already exists for this category'));
      }
      return Failure(DatabaseException(e.message));
    } catch (e) {
      print('❌ Exception in createBudget: $e');
      return Failure(DatabaseException('Failed to create budget: $e'));
    }
  }

  /// Update budget
  Future<Result<BudgetModel>> updateBudget({
    required String budgetId,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    int? alertThreshold,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (amount != null) updateData['amount'] = amount;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String().split('T')[0];
      if (alertThreshold != null) updateData['alert_threshold'] = alertThreshold;
      if (isActive != null) updateData['is_active'] = isActive;

      if (updateData.isEmpty) {
        return Failure(ValidationException('No fields to update'));
      }

      final response = await _supabase
          .from(ApiConstants.budgetsTable)
          .update(updateData)
          .eq('id', budgetId)
          .select()
          .single();

      final budget = BudgetModel.fromJson(response);
      return Success(budget);
    } on PostgrestException catch (e) {
      return Failure(DatabaseException(e.message));
    } catch (e) {
      return Failure(DatabaseException('Failed to update budget: $e'));
    }
  }

  /// Delete budget
  Future<Result<void>> deleteBudget(String budgetId) async {
    try {
      await _supabase
          .from(ApiConstants.budgetsTable)
          .delete()
          .eq('id', budgetId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(DatabaseException(e.message));
    } catch (e) {
      return Failure(DatabaseException('Failed to delete budget: $e'));
    }
  }

  /// Get spent amount for category in current period
  /// Optimized to use database SUM() instead of client-side calculation
  Future<Result<double>> getCategorySpending({
    required String profileId,
    required String categoryId,
    required BudgetPeriod period,
    DateTime? startDate,
  }) async {
    try {
      final now = DateTime.now();
      final periodStart = _getPeriodStart(period, startDate ?? now);
      final periodEnd = _getPeriodEnd(period, periodStart);

      // Use PostgreSQL RPC function for aggregation (more efficient)
      // If RPC is not available, we'll use the old method but with optimization
      final response = await _supabase
          .rpc('get_category_spending', params: {
            'p_profile_id': profileId,
            'p_category_id': categoryId,
            'p_start_date': periodStart.toIso8601String(),
            'p_end_date': periodEnd.toIso8601String(),
          });

      final total = (response as num?)?.toDouble() ?? 0.0;
      return Success(total);
    } on PostgrestException catch (e) {
      // Fallback to client-side sum if RPC function doesn't exist
      if (e.code == '42883') {
        return _getCategorySpendingFallback(
          profileId: profileId,
          categoryId: categoryId,
          period: period,
          startDate: startDate,
        );
      }
      return Failure(DatabaseException(e.message));
    } catch (e) {
      return Failure(DatabaseException('Failed to calculate spending: $e'));
    }
  }

  /// Fallback method using client-side sum (used if RPC function is not available)
  Future<Result<double>> _getCategorySpendingFallback({
    required String profileId,
    required String categoryId,
    required BudgetPeriod period,
    DateTime? startDate,
  }) async {
    try {
      final now = DateTime.now();
      final periodStart = _getPeriodStart(period, startDate ?? now);
      final periodEnd = _getPeriodEnd(period, periodStart);

      final response = await _supabase
          .from(ApiConstants.transactionsTable)
          .select('amount')
          .eq('profile_id', profileId)
          .eq('category_id', categoryId)
          .eq('type', 'expense')
          .gte('transaction_date', periodStart.toIso8601String())
          .lte('transaction_date', periodEnd.toIso8601String());

      double total = 0.0;
      for (final transaction in response as List) {
        total += (transaction['amount'] as num).toDouble();
      }

      return Success(total);
    } on PostgrestException catch (e) {
      return Failure(DatabaseException(e.message));
    } catch (e) {
      return Failure(DatabaseException('Failed to calculate spending: $e'));
    }
  }

  /// Get period start date
  DateTime _getPeriodStart(BudgetPeriod period, DateTime reference) {
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(reference.year, reference.month, reference.day);
      case BudgetPeriod.weekly:
        final weekday = reference.weekday;
        return reference.subtract(Duration(days: weekday - 1));
      case BudgetPeriod.monthly:
        return DateTime(reference.year, reference.month, 1);
      case BudgetPeriod.yearly:
        return DateTime(reference.year, 1, 1);
    }
  }

  /// Get period end date
  DateTime _getPeriodEnd(BudgetPeriod period, DateTime periodStart) {
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(periodStart.year, periodStart.month, periodStart.day, 23, 59, 59);
      case BudgetPeriod.weekly:
        return periodStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      case BudgetPeriod.monthly:
        return DateTime(periodStart.year, periodStart.month + 1, 1).subtract(const Duration(seconds: 1));
      case BudgetPeriod.yearly:
        return DateTime(periodStart.year + 1, 1, 1).subtract(const Duration(seconds: 1));
    }
  }
}
