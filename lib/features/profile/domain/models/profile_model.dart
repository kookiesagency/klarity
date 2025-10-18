/// Profile model for expense tracking
class ProfileModel {
  final String id;
  final String userId;
  final String name;
  final bool isDefault;
  final double lowBalanceThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.isDefault = false,
    this.lowBalanceThreshold = 1000.00,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      lowBalanceThreshold: (json['low_balance_threshold'] as num?)?.toDouble() ?? 1000.00,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'is_default': isDefault,
      'low_balance_threshold': lowBalanceThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with
  ProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDefault,
    double? lowBalanceThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      lowBalanceThreshold: lowBalanceThreshold ?? this.lowBalanceThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProfileModel(id: $id, name: $name)';
  }
}
