import 'budget_period.dart';

/// Budget model for category budget limits
class BudgetModel {
  final String id;
  final String profileId;
  final String categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final int alertThreshold; // Percentage (0-100), default 80%
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    required this.profileId,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    this.endDate,
    this.alertThreshold = 80,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.fromString(json['period'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      alertThreshold: json['alert_threshold'] as int? ?? 80,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'category_id': categoryId,
      'amount': amount,
      'period': period.value,
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'end_date': endDate?.toIso8601String().split('T')[0],
      'alert_threshold': alertThreshold,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with
  BudgetModel copyWith({
    String? id,
    String? profileId,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    int? alertThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BudgetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BudgetModel(id: $id, categoryId: $categoryId, amount: $amount, period: ${period.displayName})';
  }
}

/// Budget status with spending info
class BudgetStatus {
  final BudgetModel budget;
  final double spent;
  final double remaining;
  final double percentage;
  final BudgetAlertLevel alertLevel;

  const BudgetStatus({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.alertLevel,
  });

  /// Check if over budget
  bool get isOverBudget => spent > budget.amount;

  /// Check if at or above alert threshold
  bool get isAtAlertThreshold => percentage >= budget.alertThreshold;

  /// Get over budget amount
  double get overBudgetAmount => isOverBudget ? spent - budget.amount : 0.0;
}

/// Budget alert levels
enum BudgetAlertLevel {
  safe, // 0-50%
  warning, // 51-80%
  critical, // 81-99%
  overBudget, // 100%+
}
