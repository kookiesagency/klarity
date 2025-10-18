import 'transaction_type.dart';
import 'recurring_frequency.dart';

/// Model for recurring transactions (income and expenses)
class RecurringTransactionModel {
  final String id;
  final String profileId;
  final String accountId;
  final String categoryId;
  final TransactionType type;
  final double amount;
  final String? description;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional fields from joined tables
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;

  const RecurringTransactionModel({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
  });

  /// Create from JSON
  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      frequency: RecurringFrequency.fromValue(json['frequency'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      nextDueDate: DateTime.parse(json['next_due_date'] as String),
      isActive: json['is_active'] as bool,
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
      'type': type.value,
      'amount': amount,
      'description': description,
      'frequency': frequency.value,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'next_due_date': nextDueDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method
  RecurringTransactionModel copyWith({
    String? id,
    String? profileId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? description,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountName,
    String? categoryName,
    String? categoryIcon,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }

  /// Check if recurring transaction should be processed today
  bool isDueToday() {
    final today = DateTime.now();
    return nextDueDate.year == today.year &&
        nextDueDate.month == today.month &&
        nextDueDate.day == today.day;
  }

  /// Check if recurring transaction has ended
  bool hasEnded() {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Calculate next occurrence date
  DateTime calculateNextOccurrence() {
    return frequency.calculateNextDueDate(nextDueDate);
  }
}
