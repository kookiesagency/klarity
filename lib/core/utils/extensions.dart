import 'package:flutter/material.dart';

/// Extension methods for String
extension StringExtensions on String {
  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Capitalize first letter
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Convert to double (returns 0 if not valid)
  double get toDoubleOrZero => double.tryParse(this) ?? 0.0;

  /// Convert to int (returns 0 if not valid)
  int get toIntOrZero => int.tryParse(this) ?? 0;

  /// Truncate with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }
}

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Check if date is in the current week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return isAfter(weekStart.subtract(const Duration(days: 1))) &&
        isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Check if date is in the current month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Check if date is in the current year
  bool get isThisYear {
    final now = DateTime.now();
    return year == now.year;
  }

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Get start of year
  DateTime get startOfYear => DateTime(year, 1, 1);

  /// Get end of year
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59, 999);

  /// Add months
  DateTime addMonths(int months) {
    return DateTime(year, month + months, day);
  }

  /// Subtract months
  DateTime subtractMonths(int months) {
    return DateTime(year, month - months, day);
  }

  /// Get days in month
  int get daysInMonth {
    final nextMonth = DateTime(year, month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    return lastDayOfMonth.day;
  }

  /// Copy with optional parameters
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
    );
  }
}

/// Extension methods for BuildContext
extension ContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if device is in landscape mode
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  /// Check if device is in portrait mode
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  /// Get safe area padding
  EdgeInsets get padding => mediaQuery.padding;

  /// Get view insets (keyboard height, etc.)
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Show snackbar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Pop navigator
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  /// Push route
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Push replacement
  Future<T?> pushReplacement<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push and remove until
  Future<T?> pushAndRemoveUntil<T>(Widget page, bool Function(Route<dynamic>) predicate) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
      predicate,
    );
  }
}

/// Extension methods for double
extension DoubleExtensions on double {
  /// Round to decimal places
  double roundToDecimal(int decimalPlaces) {
    final multiplier = 10 * decimalPlaces;
    return (this * multiplier).round() / multiplier;
  }
}

/// Extension methods for List<T>
extension ListExtensions<T> on List<T> {
  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if list is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Safely get element at index
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
