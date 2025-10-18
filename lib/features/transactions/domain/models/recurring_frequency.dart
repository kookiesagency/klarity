/// Frequency options for recurring transactions
enum RecurringFrequency {
  daily('Daily', 'daily'),
  weekly('Weekly', 'weekly'),
  monthly('Monthly', 'monthly'),
  yearly('Yearly', 'yearly');

  final String label;
  final String value;

  const RecurringFrequency(this.label, this.value);

  /// Convert from database value
  static RecurringFrequency fromValue(String value) {
    return RecurringFrequency.values.firstWhere(
      (f) => f.value == value,
      orElse: () => RecurringFrequency.monthly,
    );
  }

  /// Calculate next due date based on frequency
  DateTime calculateNextDueDate(DateTime currentDate) {
    switch (this) {
      case RecurringFrequency.daily:
        return DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day + 1,
        );
      case RecurringFrequency.weekly:
        return DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day + 7,
        );
      case RecurringFrequency.monthly:
        // Handle month-end edge cases
        final nextMonth = currentDate.month == 12 ? 1 : currentDate.month + 1;
        final nextYear = currentDate.month == 12 ? currentDate.year + 1 : currentDate.year;
        final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = currentDate.day > lastDayOfNextMonth ? lastDayOfNextMonth : currentDate.day;
        return DateTime(nextYear, nextMonth, day);
      case RecurringFrequency.yearly:
        return DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
        );
    }
  }
}
