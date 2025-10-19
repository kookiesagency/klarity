/// Payment history entry for scheduled payments
class PaymentHistoryModel {
  final String id;
  final String scheduledPaymentId;
  final String? transactionId;
  final double amount;
  final DateTime paymentDate;
  final String paymentType; // manual, auto, partial
  final String? notes;
  final DateTime createdAt;

  const PaymentHistoryModel({
    required this.id,
    required this.scheduledPaymentId,
    this.transactionId,
    required this.amount,
    required this.paymentDate,
    required this.paymentType,
    this.notes,
    required this.createdAt,
  });

  /// Create from JSON
  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: json['id'] as String,
      scheduledPaymentId: json['scheduled_payment_id'] as String,
      transactionId: json['transaction_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      paymentType: json['payment_type'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduled_payment_id': scheduledPaymentId,
      'transaction_id': transactionId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_type': paymentType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get payment type display name
  String get paymentTypeDisplay {
    switch (paymentType) {
      case 'manual':
        return 'Manual Payment';
      case 'auto':
        return 'Auto-created';
      case 'partial':
        return 'Partial Payment';
      default:
        return paymentType;
    }
  }

  PaymentHistoryModel copyWith({
    String? id,
    String? scheduledPaymentId,
    String? transactionId,
    double? amount,
    DateTime? paymentDate,
    String? paymentType,
    String? notes,
    DateTime? createdAt,
  }) {
    return PaymentHistoryModel(
      id: id ?? this.id,
      scheduledPaymentId: scheduledPaymentId ?? this.scheduledPaymentId,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentType: paymentType ?? this.paymentType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
