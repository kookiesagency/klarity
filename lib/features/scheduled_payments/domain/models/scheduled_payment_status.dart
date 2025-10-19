/// Status of a scheduled payment
enum ScheduledPaymentStatus {
  pending('pending'),
  partial('partial'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const ScheduledPaymentStatus(this.value);

  static ScheduledPaymentStatus fromString(String value) {
    return ScheduledPaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ScheduledPaymentStatus.pending,
    );
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case ScheduledPaymentStatus.pending:
        return 'Pending';
      case ScheduledPaymentStatus.partial:
        return 'Partially Paid';
      case ScheduledPaymentStatus.completed:
        return 'Completed';
      case ScheduledPaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get color for UI
  String get colorCode {
    switch (this) {
      case ScheduledPaymentStatus.pending:
        return '#FFA726'; // Orange
      case ScheduledPaymentStatus.partial:
        return '#42A5F5'; // Blue
      case ScheduledPaymentStatus.completed:
        return '#66BB6A'; // Green
      case ScheduledPaymentStatus.cancelled:
        return '#EF5350'; // Red
    }
  }
}
