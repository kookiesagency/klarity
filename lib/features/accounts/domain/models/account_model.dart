import 'account_type.dart';

/// Account model for bank accounts and wallets
class AccountModel {
  final String id;
  final String profileId;
  final String name;
  final AccountType type;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: json['name'] as String,
      type: AccountType.fromString(json['type'] as String),
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
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
      'name': name,
      'type': type.value,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with
  AccountModel copyWith({
    String? id,
    String? profileId,
    String? name,
    AccountType? type,
    double? openingBalance,
    double? currentBalance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AccountModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AccountModel(id: $id, name: $name, type: ${type.displayName}, balance: $currentBalance)';
  }
}
