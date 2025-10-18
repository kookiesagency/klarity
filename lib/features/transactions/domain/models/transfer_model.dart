/// Transfer model for moving money between accounts
class TransferModel {
  final String id;
  final String profileId;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String? description;
  final DateTime transferDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: For display purposes (not stored in DB)
  final String? fromAccountName;
  final String? toAccountName;

  const TransferModel({
    required this.id,
    required this.profileId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.description,
    required this.transferDate,
    required this.createdAt,
    required this.updatedAt,
    this.fromAccountName,
    this.toAccountName,
  });

  /// Create from JSON
  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      fromAccountId: json['from_account_id'] as String,
      toAccountId: json['to_account_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      transferDate: DateTime.parse(json['transfer_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Optional display fields from joins
      fromAccountName: json['from_account_name'] as String?,
      toAccountName: json['to_account_name'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'description': description,
      'transfer_date': transferDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with
  TransferModel copyWith({
    String? id,
    String? profileId,
    String? fromAccountId,
    String? toAccountId,
    double? amount,
    String? description,
    DateTime? transferDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fromAccountName,
    String? toAccountName,
  }) {
    return TransferModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transferDate: transferDate ?? this.transferDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fromAccountName: fromAccountName ?? this.fromAccountName,
      toAccountName: toAccountName ?? this.toAccountName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransferModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransferModel(id: $id, amount: $amount, from: $fromAccountId, to: $toAccountId)';
  }
}
