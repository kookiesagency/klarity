import 'user_model.dart';

/// Authentication state
sealed class AuthState {
  const AuthState();
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state
class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Authenticated && other.user == user;
  }

  @override
  int get hashCode => user.hashCode;
}

/// Unauthenticated state
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication error state
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Session expired state (with optional userId for PIN unlock)
class SessionExpired extends AuthState {
  final String? userId;

  const SessionExpired({this.userId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionExpired && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
