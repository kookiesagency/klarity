/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.details});

  factory AuthException.invalidCredentials() {
    return AuthException(
      'Invalid email or password',
      code: 'INVALID_CREDENTIALS',
    );
  }

  factory AuthException.emailAlreadyInUse() {
    return AuthException(
      'This email is already registered',
      code: 'EMAIL_ALREADY_IN_USE',
    );
  }

  factory AuthException.weakPassword() {
    return AuthException(
      'Password is too weak',
      code: 'WEAK_PASSWORD',
    );
  }

  factory AuthException.userNotFound() {
    return AuthException(
      'No user found with this email',
      code: 'USER_NOT_FOUND',
    );
  }

  factory AuthException.emailNotVerified() {
    return AuthException(
      'Please verify your email first',
      code: 'EMAIL_NOT_VERIFIED',
    );
  }

  factory AuthException.sessionExpired() {
    return AuthException(
      'Your session has expired. Please login again',
      code: 'SESSION_EXPIRED',
    );
  }

  factory AuthException.accountLocked() {
    return AuthException(
      'Account locked due to too many failed attempts',
      code: 'ACCOUNT_LOCKED',
    );
  }

  factory AuthException.invalidPIN() {
    return AuthException(
      'Invalid PIN',
      code: 'INVALID_PIN',
    );
  }

  factory AuthException.biometricFailed() {
    return AuthException(
      'Biometric authentication failed',
      code: 'BIOMETRIC_FAILED',
    );
  }

  factory AuthException.biometricNotAvailable() {
    return AuthException(
      'Biometric authentication is not available on this device',
      code: 'BIOMETRIC_NOT_AVAILABLE',
    );
  }
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});

  factory NetworkException.noInternet() {
    return NetworkException(
      'No internet connection',
      code: 'NO_INTERNET',
    );
  }

  factory NetworkException.timeout() {
    return NetworkException(
      'Request timed out',
      code: 'TIMEOUT',
    );
  }

  factory NetworkException.serverError() {
    return NetworkException(
      'Server error. Please try again later',
      code: 'SERVER_ERROR',
    );
  }
}

/// Database related exceptions
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.details});

  factory DatabaseException.notFound() {
    return DatabaseException(
      'Record not found',
      code: 'NOT_FOUND',
    );
  }

  factory DatabaseException.duplicate() {
    return DatabaseException(
      'Record already exists',
      code: 'DUPLICATE',
    );
  }

  factory DatabaseException.constraintViolation() {
    return DatabaseException(
      'Operation violates database constraints',
      code: 'CONSTRAINT_VIOLATION',
    );
  }

  factory DatabaseException.queryFailed() {
    return DatabaseException(
      'Database query failed',
      code: 'QUERY_FAILED',
    );
  }
}

/// Validation related exceptions
class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.details});

  factory ValidationException.invalidInput(String field) {
    return ValidationException(
      'Invalid input for $field',
      code: 'INVALID_INPUT',
      details: field,
    );
  }

  factory ValidationException.requiredField(String field) {
    return ValidationException(
      '$field is required',
      code: 'REQUIRED_FIELD',
      details: field,
    );
  }

  factory ValidationException.invalidAmount() {
    return ValidationException(
      'Invalid amount',
      code: 'INVALID_AMOUNT',
    );
  }

  factory ValidationException.invalidDate() {
    return ValidationException(
      'Invalid date',
      code: 'INVALID_DATE',
    );
  }

  factory ValidationException.amountExceedsBalance() {
    return ValidationException(
      'Amount exceeds available balance',
      code: 'AMOUNT_EXCEEDS_BALANCE',
    );
  }
}

/// Business logic exceptions
class BusinessException extends AppException {
  BusinessException(super.message, {super.code, super.details});

  factory BusinessException.insufficientBalance() {
    return BusinessException(
      'Insufficient balance',
      code: 'INSUFFICIENT_BALANCE',
    );
  }

  factory BusinessException.budgetExceeded() {
    return BusinessException(
      'Budget limit exceeded',
      code: 'BUDGET_EXCEEDED',
    );
  }

  factory BusinessException.transactionLocked() {
    return BusinessException(
      'Transaction is locked and cannot be modified',
      code: 'TRANSACTION_LOCKED',
    );
  }

  factory BusinessException.invalidTransfer() {
    return BusinessException(
      'Cannot transfer between the same account',
      code: 'INVALID_TRANSFER',
    );
  }

  factory BusinessException.emiAlreadyPaid() {
    return BusinessException(
      'EMI payment already made for this period',
      code: 'EMI_ALREADY_PAID',
    );
  }

  factory BusinessException.scheduledPaymentCompleted() {
    return BusinessException(
      'Scheduled payment is already completed',
      code: 'SCHEDULED_PAYMENT_COMPLETED',
    );
  }
}

/// Storage related exceptions
class StorageException extends AppException {
  StorageException(super.message, {super.code, super.details});

  factory StorageException.readFailed() {
    return StorageException(
      'Failed to read from storage',
      code: 'READ_FAILED',
    );
  }

  factory StorageException.writeFailed() {
    return StorageException(
      'Failed to write to storage',
      code: 'WRITE_FAILED',
    );
  }

  factory StorageException.deleteFailed() {
    return StorageException(
      'Failed to delete from storage',
      code: 'DELETE_FAILED',
    );
  }
}

/// Generic/Unknown exception
class UnknownException extends AppException {
  UnknownException(super.message, {super.code, super.details});

  factory UnknownException.generic() {
    return UnknownException(
      'An unexpected error occurred',
      code: 'UNKNOWN_ERROR',
    );
  }
}
