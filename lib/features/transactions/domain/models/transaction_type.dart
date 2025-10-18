import 'package:flutter/material.dart';

/// Transaction type enum
enum TransactionType {
  income('income'),
  expense('expense');

  final String value;
  const TransactionType(this.value);

  /// Get display name
  String get displayName {
    return switch (this) {
      TransactionType.income => 'Income',
      TransactionType.expense => 'Expense',
    };
  }

  /// Get icon
  IconData get icon {
    return switch (this) {
      TransactionType.income => Icons.arrow_upward,
      TransactionType.expense => Icons.arrow_downward,
    };
  }

  /// Get color
  Color get color {
    return switch (this) {
      TransactionType.income => const Color(0xFF22C55E), // Green
      TransactionType.expense => const Color(0xFFEF4444), // Red
    };
  }

  /// From string value
  static TransactionType fromString(String value) {
    return switch (value.toLowerCase()) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      _ => throw ArgumentError('Invalid transaction type: $value'),
    };
  }
}
