import 'transaction_type.dart';

/// Transaction model for income and expense transactions
class TransactionModel {
  final String id;
  final String profileId;
  final String accountId;
  final String categoryId;
  final TransactionType type;
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final bool isLocked;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: For display purposes (not stored in DB)
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;

  const TransactionModel({
    required this.id,
    required this.profileId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    required this.transactionDate,
    this.isLocked = false,
    this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
  });

  /// Create from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      isLocked: json['is_locked'] as bool? ?? false,
      lockedAt: json['locked_at'] != null
          ? DateTime.parse(json['locked_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Optional display fields from joins
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
      'transaction_date': transactionDate.toIso8601String(),
      'is_locked': isLocked,
      'locked_at': lockedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with
  TransactionModel copyWith({
    String? id,
    String? profileId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? description,
    DateTime? transactionDate,
    bool? isLocked,
    DateTime? lockedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountName,
    String? categoryName,
    String? categoryIcon,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: ${type.displayName}, amount: $amount, date: $transactionDate)';
  }
}
