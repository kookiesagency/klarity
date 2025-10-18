import '../constants/app_constants.dart';

/// Input validation utilities
class Validators {
  Validators._();

  /// Validate email address
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password must not exceed ${AppConstants.maxPasswordLength} characters';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validate password confirmation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate name
  static String? name(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < AppConstants.minNameLength) {
      return '$fieldName must be at least ${AppConstants.minNameLength} characters';
    }

    if (value.trim().length > AppConstants.maxNameLength) {
      return '$fieldName must not exceed ${AppConstants.maxNameLength} characters';
    }

    return null;
  }

  /// Validate PIN
  static String? pin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }

    if (value.length != AppConstants.pinLength) {
      return 'PIN must be ${AppConstants.pinLength} digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }

    return null;
  }

  /// Validate amount
  static String? amount(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount < AppConstants.minTransactionAmount) {
      return '$fieldName must be at least ${AppConstants.currencySymbol}${AppConstants.minTransactionAmount}';
    }

    if (amount > AppConstants.maxTransactionAmount) {
      return '$fieldName cannot exceed ${AppConstants.currencySymbol}${AppConstants.maxTransactionAmount}';
    }

    return null;
  }

  /// Validate description
  static String? description(String? value, {bool required = false}) {
    if (required && (value == null || value.trim().isEmpty)) {
      return 'Description is required';
    }

    if (value != null && value.length > AppConstants.maxDescriptionLength) {
      return 'Description must not exceed ${AppConstants.maxDescriptionLength} characters';
    }

    return null;
  }

  /// Validate category name
  static String? categoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }

    if (value.trim().length > AppConstants.maxCategoryNameLength) {
      return 'Category name must not exceed ${AppConstants.maxCategoryNameLength} characters';
    }

    return null;
  }

  /// Validate account name
  static String? accountName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account name is required';
    }

    if (value.trim().length > AppConstants.maxAccountNameLength) {
      return 'Account name must not exceed ${AppConstants.maxAccountNameLength} characters';
    }

    return null;
  }

  /// Validate interest rate
  static String? interestRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Interest rate is required';
    }

    final rate = double.tryParse(value.trim());
    if (rate == null) {
      return 'Please enter a valid interest rate';
    }

    if (rate < AppConstants.minInterestRate) {
      return 'Interest rate must be at least ${AppConstants.minInterestRate}%';
    }

    if (rate > AppConstants.maxInterestRate) {
      return 'Interest rate cannot exceed ${AppConstants.maxInterestRate}%';
    }

    return null;
  }

  /// Validate EMI tenure (in months)
  static String? emiTenure(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tenure is required';
    }

    final tenure = int.tryParse(value.trim());
    if (tenure == null) {
      return 'Please enter a valid tenure';
    }

    if (tenure < AppConstants.minEmiTenureMonths) {
      return 'Tenure must be at least ${AppConstants.minEmiTenureMonths} month';
    }

    if (tenure > AppConstants.maxEmiTenureMonths) {
      return 'Tenure cannot exceed ${AppConstants.maxEmiTenureMonths} months';
    }

    return null;
  }

  /// Validate phone number (basic validation)
  static String? phoneNumber(String? value, {bool required = false}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (required && (value == null || value.trim().isEmpty)) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (value != null && !phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? minLength(String? value, int min, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < min) {
      return '$fieldName must be at least $min characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int max, {String fieldName = 'This field'}) {
    if (value != null && value.length > max) {
      return '$fieldName must not exceed $max characters';
    }
    return null;
  }
}
