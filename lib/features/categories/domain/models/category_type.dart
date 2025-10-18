/// Category type enum for income or expense categories
enum CategoryType {
  income('income'),
  expense('expense');

  const CategoryType(this.value);
  final String value;

  /// Get display name
  String get displayName {
    return switch (this) {
      CategoryType.income => 'Income',
      CategoryType.expense => 'Expense',
    };
  }

  /// Parse from string
  static CategoryType fromString(String value) {
    return switch (value.toLowerCase()) {
      'income' => CategoryType.income,
      'expense' => CategoryType.expense,
      _ => throw ArgumentError('Invalid category type: $value'),
    };
  }
}
