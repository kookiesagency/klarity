import 'package:flutter/material.dart';

/// Account type enum for different types of bank accounts
enum AccountType {
  savings('savings'),
  current('current'),
  creditCard('credit_card');

  const AccountType(this.value);
  final String value;

  /// Get display name
  String get displayName {
    return switch (this) {
      AccountType.savings => 'Savings Account',
      AccountType.current => 'Current Account',
      AccountType.creditCard => 'Credit Card',
    };
  }

  /// Get icon
  IconData get icon {
    return switch (this) {
      AccountType.savings => Icons.account_balance,
      AccountType.current => Icons.account_balance,
      AccountType.creditCard => Icons.credit_card,
    };
  }

  /// Get color
  Color get color {
    return switch (this) {
      AccountType.savings => Colors.green,
      AccountType.current => Colors.blue,
      AccountType.creditCard => Colors.purple,
    };
  }

  /// Parse from string
  static AccountType fromString(String value) {
    return switch (value.toLowerCase()) {
      'savings' => AccountType.savings,
      'current' => AccountType.current,
      'wallet' => AccountType.savings, // Legacy support: map old wallet type to savings
      'credit_card' || 'creditcard' => AccountType.creditCard,
      _ => throw ArgumentError('Invalid account type: $value'),
    };
  }
}
