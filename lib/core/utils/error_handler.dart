import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exceptions.dart' as app_exceptions;

/// Error handler to convert various errors to app exceptions
class ErrorHandler {
  ErrorHandler._();

  /// Handle and convert errors to AppException
  static app_exceptions.AppException handle(dynamic error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }

    // If already an AppException, return as is
    if (error is app_exceptions.AppException) {
      return error;
    }

    // Handle Supabase AuthApiException
    if (error is AuthException) {
      return _handleAuthException(error);
    }

    // Handle Supabase PostgrestException
    if (error is PostgrestException) {
      return _handlePostgrestException(error);
    }

    // Handle by checking error message string
    final errorString = error.toString().toLowerCase();

    // Auth-related errors
    if (errorString.contains('invalid') && errorString.contains('credentials')) {
      return app_exceptions.AuthException.invalidCredentials();
    }
    if (errorString.contains('email') && errorString.contains('already')) {
      return app_exceptions.AuthException.emailAlreadyInUse();
    }
    if (errorString.contains('user') && errorString.contains('already') && errorString.contains('registered')) {
      return app_exceptions.AuthException.emailAlreadyInUse();
    }
    if (errorString.contains('weak') && errorString.contains('password')) {
      return app_exceptions.AuthException.weakPassword();
    }
    if (errorString.contains('user') && errorString.contains('not found')) {
      return app_exceptions.AuthException.userNotFound();
    }
    if (errorString.contains('email') && errorString.contains('not') && errorString.contains('verified')) {
      return app_exceptions.AuthException.emailNotVerified();
    }
    if (errorString.contains('session') && errorString.contains('expired')) {
      return app_exceptions.AuthException.sessionExpired();
    }
    if (errorString.contains('rate') && errorString.contains('limit')) {
      return app_exceptions.AuthException('Please wait a moment before trying again');
    }

    // Handle network/connection errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return app_exceptions.NetworkException.noInternet();
    }
    if (errorString.contains('timeout')) {
      return app_exceptions.NetworkException.timeout();
    }

    // Default to unknown exception
    return app_exceptions.UnknownException.generic();
  }

  /// Handle Supabase AuthException
  static app_exceptions.AppException _handleAuthException(AuthException error) {
    final message = error.message.toLowerCase();

    // Check for specific auth error patterns
    if (message.contains('user already registered') ||
        message.contains('email') && message.contains('already')) {
      return app_exceptions.AuthException.emailAlreadyInUse();
    }
    if (message.contains('invalid') && message.contains('credentials')) {
      return app_exceptions.AuthException.invalidCredentials();
    }
    if (message.contains('invalid login credentials')) {
      return app_exceptions.AuthException.invalidCredentials();
    }
    if (message.contains('email not confirmed')) {
      return app_exceptions.AuthException.emailNotVerified();
    }
    if (message.contains('weak') && message.contains('password')) {
      return app_exceptions.AuthException.weakPassword();
    }
    if (message.contains('rate limit')) {
      return app_exceptions.AuthException('Please wait a moment before trying again');
    }

    // Default to generic auth exception with original message
    return app_exceptions.AuthException(error.message);
  }

  /// Handle Supabase PostgrestException
  static app_exceptions.AppException _handlePostgrestException(PostgrestException error) {
    final code = error.code;
    final message = error.message.toLowerCase();

    // Handle specific error codes
    if (code == '23505') {
      // Unique constraint violation
      return app_exceptions.DatabaseException.duplicate();
    }
    if (code == '23503') {
      // Foreign key constraint violation
      return app_exceptions.DatabaseException.constraintViolation();
    }
    if (code == 'PGRST116') {
      // No rows found
      return app_exceptions.DatabaseException.notFound();
    }

    // Handle error messages
    if (message.contains('not found')) {
      return app_exceptions.DatabaseException.notFound();
    }
    if (message.contains('duplicate') || message.contains('already exists')) {
      return app_exceptions.DatabaseException.duplicate();
    }
    if (message.contains('constraint')) {
      return app_exceptions.DatabaseException.constraintViolation();
    }

    return app_exceptions.DatabaseException.queryFailed();
  }

  /// Get user-friendly error message
  static String getUserMessage(app_exceptions.AppException exception) {
    return exception.message;
  }

  /// Check if error is network related
  static bool isNetworkError(app_exceptions.AppException exception) {
    return exception is app_exceptions.NetworkException;
  }

  /// Check if error is authentication related
  static bool isAuthError(app_exceptions.AppException exception) {
    return exception is app_exceptions.AuthException;
  }

  /// Check if error is validation related
  static bool isValidationError(app_exceptions.AppException exception) {
    return exception is app_exceptions.ValidationException;
  }
}
