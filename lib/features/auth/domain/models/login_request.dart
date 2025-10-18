/// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
    };
  }

  @override
  String toString() => 'LoginRequest(email: $email)';
}

/// Signup request model
class SignupRequest {
  final String email;
  final String password;
  final String fullName;
  final String? phone;

  SignupRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
    };
  }

  Map<String, dynamic> toMetadata() {
    return {
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
    };
  }

  @override
  String toString() => 'SignupRequest(email: $email, fullName: $fullName)';
}

/// PIN request model
class PinRequest {
  final String pin;

  PinRequest({required this.pin});

  @override
  String toString() => 'PinRequest(pin: ****)';
}

/// Reset password request model
class ResetPasswordRequest {
  final String email;

  ResetPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
    };
  }

  @override
  String toString() => 'ResetPasswordRequest(email: $email)';
}
