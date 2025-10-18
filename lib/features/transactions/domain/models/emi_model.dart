/// Model for EMI (Equated Monthly Installment)
class EmiModel {
  final String id;
  final String profileId;
  final String accountId;
  final String categoryId;
  final String name;
  final String? description;
  final double totalAmount;
  final double monthlyPayment;
  final int totalInstallments;
  final int paidInstallments;
  final DateTime startDate;
  final int paymentDayOfMonth; // Day of month for payment (1-31)
  final DateTime nextPaymentDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional fields from joined tables
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;

  const EmiModel({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.totalAmount,
    required this.monthlyPayment,
    required this.totalInstallments,
    required this.paidInstallments,
    required this.startDate,
    required this.paymentDayOfMonth,
    required this.nextPaymentDate,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
  });

  /// Calculate remaining installments
  int get remainingInstallments => totalInstallments - paidInstallments;

  /// Calculate remaining amount
  double get remainingAmount {
    return monthlyPayment * remainingInstallments;
  }

  /// Calculate paid amount
  double get paidAmount {
    return monthlyPayment * paidInstallments;
  }

  /// Calculate progress percentage
  double get progressPercentage {
    if (totalInstallments == 0) return 0.0;
    return (paidInstallments / totalInstallments) * 100;
  }

  /// Check if EMI is completed
  bool get isCompleted => paidInstallments >= totalInstallments;

  /// Check if payment is due today
  bool get isDueToday {
    final today = DateTime.now();
    return nextPaymentDate.year == today.year &&
        nextPaymentDate.month == today.month &&
        nextPaymentDate.day == today.day;
  }

  /// Check if payment is overdue
  bool get isOverdue {
    final today = DateTime.now();
    return nextPaymentDate.isBefore(today) && !isCompleted;
  }

  /// Create from JSON
  factory EmiModel.fromJson(Map<String, dynamic> json) {
    return EmiModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      monthlyPayment: (json['monthly_payment'] as num).toDouble(),
      totalInstallments: json['total_installments'] as int,
      paidInstallments: json['paid_installments'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      paymentDayOfMonth: json['payment_day_of_month'] as int,
      nextPaymentDate: DateTime.parse(json['next_payment_date'] as String),
      isActive: json['is_active'] as bool,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      accountName: json['account_name'] as String?,
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'account_id': accountId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'total_amount': totalAmount,
      'monthly_payment': monthlyPayment,
      'total_installments': totalInstallments,
      'paid_installments': paidInstallments,
      'start_date': startDate.toIso8601String(),
      'payment_day_of_month': paymentDayOfMonth,
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method
  EmiModel copyWith({
    String? id,
    String? profileId,
    String? accountId,
    String? categoryId,
    String? name,
    String? description,
    double? totalAmount,
    double? monthlyPayment,
    int? totalInstallments,
    int? paidInstallments,
    DateTime? startDate,
    int? paymentDayOfMonth,
    DateTime? nextPaymentDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountName,
    String? categoryName,
    String? categoryIcon,
  }) {
    return EmiModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      startDate: startDate ?? this.startDate,
      paymentDayOfMonth: paymentDayOfMonth ?? this.paymentDayOfMonth,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }

  /// Calculate next payment date
  DateTime calculateNextPaymentDate() {
    final current = nextPaymentDate;
    final nextMonth = current.month == 12 ? 1 : current.month + 1;
    final nextYear = current.month == 12 ? current.year + 1 : current.year;

    // Handle month-end edge cases
    final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    final day = paymentDayOfMonth > lastDayOfNextMonth
        ? lastDayOfNextMonth
        : paymentDayOfMonth;

    return DateTime(nextYear, nextMonth, day);
  }
}
