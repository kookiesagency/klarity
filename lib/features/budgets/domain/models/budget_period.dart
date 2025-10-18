/// Budget period enum
enum BudgetPeriod {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  yearly('yearly', 'Yearly');

  final String value;
  final String displayName;

  const BudgetPeriod(this.value, this.displayName);

  /// Create from string value
  static BudgetPeriod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
        return BudgetPeriod.daily;
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'monthly':
        return BudgetPeriod.monthly;
      case 'yearly':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly; // Default to monthly
    }
  }

  @override
  String toString() => displayName;
}
