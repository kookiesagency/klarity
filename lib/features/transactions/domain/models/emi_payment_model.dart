/// Model for individual EMI payment
class EmiPaymentModel {
  final String id;
  final String emiId;
  final String transactionId; // Links to the transaction created
  final int installmentNumber;
  final double amount;
  final DateTime paymentDate;
  final DateTime dueDate;
  final bool isPaid;
  final String? notes;
  final DateTime createdAt;

  const EmiPaymentModel({
    required this.id,
    required this.emiId,
    required this.transactionId,
    required this.installmentNumber,
    required this.amount,
    required this.paymentDate,
    required this.dueDate,
    required this.isPaid,
    this.notes,
    required this.createdAt,
  });

  /// Check if payment is overdue
  bool get isOverdue {
    final today = DateTime.now();
    return !isPaid && dueDate.isBefore(today);
  }

  /// Check if payment is due today
  bool get isDueToday {
    final today = DateTime.now();
    return dueDate.year == today.year &&
        dueDate.month == today.month &&
        dueDate.day == today.day;
  }

  /// Number of days overdue (negative if not yet due)
  int get daysOverdue {
    final today = DateTime.now();
    return today.difference(dueDate).inDays;
  }

  /// Create from JSON
  factory EmiPaymentModel.fromJson(Map<String, dynamic> json) {
    return EmiPaymentModel(
      id: json['id'] as String,
      emiId: json['emi_id'] as String,
      transactionId: json['transaction_id'] as String,
      installmentNumber: json['installment_number'] as int,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      isPaid: json['is_paid'] as bool,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emi_id': emiId,
      'transaction_id': transactionId,
      'installment_number': installmentNumber,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'is_paid': isPaid,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with method
  EmiPaymentModel copyWith({
    String? id,
    String? emiId,
    String? transactionId,
    int? installmentNumber,
    double? amount,
    DateTime? paymentDate,
    DateTime? dueDate,
    bool? isPaid,
    String? notes,
    DateTime? createdAt,
  }) {
    return EmiPaymentModel(
      id: id ?? this.id,
      emiId: emiId ?? this.emiId,
      transactionId: transactionId ?? this.transactionId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
