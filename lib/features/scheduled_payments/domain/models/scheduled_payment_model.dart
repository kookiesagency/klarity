import '../../../transactions/domain/models/transaction_type.dart';
import 'scheduled_payment_status.dart';

/// Scheduled payment model
class ScheduledPaymentModel {
  final String id;
  final String profileId;
  final String accountId;
  final String categoryId;
  final TransactionType type;
  final double amount;
  final String payeeName;
  final String? description;
  final DateTime dueDate;
  final DateTime? reminderDate;

  // Partial payment support
  final bool allowPartialPayment;
  final double totalAmount;
  final double paidAmount;

  // Status
  final ScheduledPaymentStatus status;

  // Auto-creation
  final bool autoCreateTransaction;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  // Joined data (from database joins)
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;

  const ScheduledPaymentModel({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.payeeName,
    this.description,
    required this.dueDate,
    this.reminderDate,
    this.allowPartialPayment = false,
    required this.totalAmount,
    this.paidAmount = 0,
    this.status = ScheduledPaymentStatus.pending,
    this.autoCreateTransaction = true,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
  });

  /// Create from JSON
  factory ScheduledPaymentModel.fromJson(Map<String, dynamic> json) {
    return ScheduledPaymentModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      payeeName: json['payee_name'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      reminderDate: json['reminder_date'] != null
          ? DateTime.parse(json['reminder_date'] as String)
          : null,
      allowPartialPayment: json['allow_partial_payment'] as bool? ?? false,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      status: ScheduledPaymentStatus.fromString(json['status'] as String),
      autoCreateTransaction: json['auto_create_transaction'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
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
      'type': type.value,
      'amount': amount,
      'payee_name': payeeName,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'reminder_date': reminderDate?.toIso8601String(),
      'allow_partial_payment': allowPartialPayment,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': status.value,
      'auto_create_transaction': autoCreateTransaction,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Remaining amount to be paid
  double get remainingAmount => totalAmount - paidAmount;

  /// Payment progress percentage
  double get progressPercentage {
    if (totalAmount == 0) return 0;
    return (paidAmount / totalAmount * 100).clamp(0, 100);
  }

  /// Is overdue
  bool get isOverdue {
    return status == ScheduledPaymentStatus.pending &&
        dueDate.isBefore(DateTime.now());
  }

  /// Is due today
  bool get isDueToday {
    final today = DateTime.now();
    return dueDate.year == today.year &&
        dueDate.month == today.month &&
        dueDate.day == today.day;
  }

  /// Is due within next 7 days
  bool get isDueSoon {
    final sevenDaysFromNow = DateTime.now().add(const Duration(days: 7));
    return dueDate.isBefore(sevenDaysFromNow) && dueDate.isAfter(DateTime.now());
  }

  /// Is reminder due
  bool get isReminderDue {
    if (reminderDate == null) return false;
    return reminderDate!.isBefore(DateTime.now()) || reminderDate!.isAtSameMomentAs(DateTime.now());
  }

  ScheduledPaymentModel copyWith({
    String? id,
    String? profileId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? payeeName,
    String? description,
    DateTime? dueDate,
    DateTime? reminderDate,
    bool? allowPartialPayment,
    double? totalAmount,
    double? paidAmount,
    ScheduledPaymentStatus? status,
    bool? autoCreateTransaction,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? accountName,
    String? categoryName,
    String? categoryIcon,
  }) {
    return ScheduledPaymentModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      payeeName: payeeName ?? this.payeeName,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderDate: reminderDate ?? this.reminderDate,
      allowPartialPayment: allowPartialPayment ?? this.allowPartialPayment,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      autoCreateTransaction: autoCreateTransaction ?? this.autoCreateTransaction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }
}
