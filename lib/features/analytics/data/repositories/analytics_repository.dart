import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../domain/models/analytics_summary.dart';

/// Repository for analytics data aggregation
class AnalyticsRepository {
  final TransactionRepository _transactionRepository;

  AnalyticsRepository(this._transactionRepository);

  /// Get analytics summary for date range
  Future<Result<AnalyticsSummary>> getAnalyticsSummary({
    required String profileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch transactions for the date range
      final transactionsResult = await _transactionRepository.getTransactionsByDateRange(
        profileId: profileId,
        startDate: startDate,
        endDate: endDate,
      );

      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.exception!);
      }

      final transactions = transactionsResult.data!;

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;

      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          totalExpense += transaction.amount;
        }
      }

      // Calculate category breakdown (expenses only)
      final Map<String, CategorySpending> categoryBreakdown = {};
      final expenseTransactions = transactions.where(
        (t) => t.type == TransactionType.expense,
      );

      for (final transaction in expenseTransactions) {
        final categoryKey = transaction.categoryId;

        if (categoryBreakdown.containsKey(categoryKey)) {
          final existing = categoryBreakdown[categoryKey]!;
          categoryBreakdown[categoryKey] = CategorySpending(
            categoryId: existing.categoryId,
            categoryName: existing.categoryName,
            categoryIcon: existing.categoryIcon,
            amount: existing.amount + transaction.amount,
            transactionCount: existing.transactionCount + 1,
          );
        } else {
          categoryBreakdown[categoryKey] = CategorySpending(
            categoryId: transaction.categoryId,
            categoryName: transaction.categoryName ?? 'Unknown',
            categoryIcon: transaction.categoryIcon ?? '📌',
            amount: transaction.amount,
            transactionCount: 1,
          );
        }
      }

      // Calculate daily balances for trend chart
      final Map<String, double> dailyBalances = {};

      // Group transactions by date
      final Map<String, List<double>> dailyIncomes = {};
      final Map<String, List<double>> dailyExpenses = {};

      for (final transaction in transactions) {
        final dateKey = transaction.transactionDate.toIso8601String().split('T')[0];

        if (transaction.type == TransactionType.income) {
          dailyIncomes.putIfAbsent(dateKey, () => []);
          dailyIncomes[dateKey]!.add(transaction.amount);
        } else if (transaction.type == TransactionType.expense) {
          dailyExpenses.putIfAbsent(dateKey, () => []);
          dailyExpenses[dateKey]!.add(transaction.amount);
        }
      }

      // Calculate running balance for each day
      double runningBalance = 0;
      final allDates = <DateTime>{};

      // Generate all dates in range
      DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
        allDates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Sort dates and calculate balance
      final sortedDates = allDates.toList()..sort();

      for (final date in sortedDates) {
        final dateKey = date.toIso8601String().split('T')[0];
        final dayIncome = dailyIncomes[dateKey]?.fold(0.0, (sum, amount) => sum + amount) ?? 0;
        final dayExpense = dailyExpenses[dateKey]?.fold(0.0, (sum, amount) => sum + amount) ?? 0;

        runningBalance += (dayIncome - dayExpense);
        dailyBalances[dateKey] = runningBalance;
      }

      // Find largest expense
      LargestExpense? largestExpense;
      if (expenseTransactions.isNotEmpty) {
        final largest = expenseTransactions.reduce(
          (a, b) => a.amount > b.amount ? a : b,
        );
        largestExpense = LargestExpense(
          amount: largest.amount,
          categoryName: largest.categoryName ?? 'Unknown',
          categoryIcon: largest.categoryIcon ?? '📌',
          date: largest.transactionDate,
        );
      }

      final summary = AnalyticsSummary(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        categoryBreakdown: categoryBreakdown,
        dailyBalances: dailyBalances,
        transactionCount: transactions.length,
        largestExpense: largestExpense,
      );

      return Success(summary);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }

  /// Get top spending categories
  Future<Result<List<CategorySpending>>> getTopCategories({
    required String profileId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    try {
      final summaryResult = await getAnalyticsSummary(
        profileId: profileId,
        startDate: startDate,
        endDate: endDate,
      );

      if (summaryResult.isFailure) {
        return Failure(summaryResult.exception!);
      }

      final categories = summaryResult.data!.categoryBreakdown.values.toList();

      // Sort by amount descending
      categories.sort((a, b) => b.amount.compareTo(a.amount));

      // Take top N
      final topCategories = categories.take(limit).toList();

      return Success(topCategories);
    } catch (e, stackTrace) {
      return Failure(ErrorHandler.handle(e, stackTrace: stackTrace));
    }
  }
}
