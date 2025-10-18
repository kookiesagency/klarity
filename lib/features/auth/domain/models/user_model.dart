/// User model representing authenticated user
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final bool hasPin;
  final bool biometricEnabled;
  final int failedLoginAttempts;
  final DateTime? accountLockedUntil;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.hasPin = false,
    required this.biometricEnabled,
    required this.failedLoginAttempts,
    this.accountLockedUntil,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Check for has_pin flag first (from local cache), then pin_hash (from database)
    final bool hasPin;
    if (json.containsKey('has_pin')) {
      hasPin = json['has_pin'] as bool? ?? false;
    } else {
      hasPin = (json['pin_hash'] as String?)?.isNotEmpty ?? false;
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      hasPin: hasPin,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      failedLoginAttempts: json['failed_login_attempts'] as int? ?? 0,
      accountLockedUntil: json['account_locked_until'] != null
          ? DateTime.parse(json['account_locked_until'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'has_pin': hasPin,
      'biometric_enabled': biometricEnabled,
      'failed_login_attempts': failedLoginAttempts,
      'account_locked_until': accountLockedUntil?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    bool? hasPin,
    bool? biometricEnabled,
    int? failedLoginAttempts,
    DateTime? accountLockedUntil,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      hasPin: hasPin ?? this.hasPin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      accountLockedUntil: accountLockedUntil ?? this.accountLockedUntil,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if account is locked
  bool get isAccountLocked {
    if (accountLockedUntil == null) return false;
    return DateTime.now().isBefore(accountLockedUntil!);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.fullName == fullName &&
        other.hasPin == hasPin;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      fullName.hashCode ^
      hasPin.hashCode;
}
