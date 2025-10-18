import 'package:flutter/material.dart';

/// Analytics summary model
class AnalyticsSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final Map<String, CategorySpending> categoryBreakdown;
  final Map<String, double> dailyBalances;
  final int transactionCount;
  final LargestExpense? largestExpense;

  const AnalyticsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.categoryBreakdown,
    required this.dailyBalances,
    required this.transactionCount,
    this.largestExpense,
  });

  double get savingsRate {
    if (totalIncome == 0) return 0;
    return ((totalIncome - totalExpense) / totalIncome) * 100;
  }

  int get healthScore {
    if (totalIncome == 0) return 0;
    final rate = savingsRate;

    if (rate >= 40) return 100;
    if (rate >= 30) return 85;
    if (rate >= 20) return 70;
    if (rate >= 10) return 55;
    if (rate >= 0) return 40;
    if (rate >= -10) return 25;
    if (rate >= -20) return 10;
    return 0;
  }

  String get healthStatus {
    final score = healthScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  Color get healthColor {
    final score = healthScore;
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFF3B82F6); // Blue
    if (score >= 40) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }
}

/// Category spending model
class CategorySpending {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final int transactionCount;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.transactionCount,
  });

  double getPercentage(double total) {
    if (total == 0) return 0;
    return (amount / total) * 100;
  }
}

/// Daily balance point for trend chart
class DailyBalance {
  final DateTime date;
  final double balance;
  final double income;
  final double expense;

  const DailyBalance({
    required this.date,
    required this.balance,
    required this.income,
    required this.expense,
  });
}

/// Largest expense transaction info
class LargestExpense {
  final double amount;
  final String categoryName;
  final String categoryIcon;
  final DateTime date;

  const LargestExpense({
    required this.amount,
    required this.categoryName,
    required this.categoryIcon,
    required this.date,
  });
}
