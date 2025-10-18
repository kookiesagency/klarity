import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Formatting utilities for currency, dates, and numbers
class Formatters {
  Formatters._();

  /// Format currency amount
  static String currency(
    double amount, {
    String symbol = AppConstants.currencySymbol,
    int decimalDigits = AppConstants.currencyDecimalDigits,
    bool showSymbol = true,
  }) {
    final formatter = NumberFormat.currency(
      symbol: showSymbol ? symbol : '',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Format currency with compact notation (e.g., 1.2K, 3.5M)
  static String currencyCompact(
    double amount, {
    String symbol = AppConstants.currencySymbol,
  }) {
    final formatter = NumberFormat.compactCurrency(
      symbol: symbol,
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  /// Format date
  static String date(
    DateTime dateTime, {
    String format = AppConstants.dateFormat,
  }) {
    return DateFormat(format).format(dateTime);
  }

  /// Format date and time
  static String dateTime(
    DateTime dateTime, {
    String format = AppConstants.dateTimeFormat,
  }) {
    return DateFormat(format).format(dateTime);
  }

  /// Format time only
  static String time(
    DateTime dateTime, {
    String format = AppConstants.timeFormat,
  }) {
    return DateFormat(format).format(dateTime);
  }

  /// Format month and year
  static String monthYear(DateTime dateTime) {
    return DateFormat(AppConstants.monthYearFormat).format(dateTime);
  }

  /// Format full date (e.g., "Monday, 15 January 2024")
  static String fullDate(DateTime dateTime) {
    return DateFormat(AppConstants.fullDateFormat).format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago", "3 days ago")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Format percentage
  static String percentage(
    double value, {
    int decimalDigits = 1,
    bool showSymbol = true,
  }) {
    final formatted = value.toStringAsFixed(decimalDigits);
    return showSymbol ? '$formatted%' : formatted;
  }

  /// Format number with thousand separators
  static String number(
    num value, {
    int decimalDigits = 0,
  }) {
    final formatter = NumberFormat('#,##0${decimalDigits > 0 ? '.${'0' * decimalDigits}' : ''}');
    return formatter.format(value);
  }

  /// Format duration (e.g., "2h 30m", "45m")
  static String duration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format file size (e.g., "1.2 MB", "500 KB")
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Capitalize first letter of each word
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Format account number (mask middle digits)
  static String accountNumber(String accountNumber, {int visibleDigits = 4}) {
    if (accountNumber.length <= visibleDigits) return accountNumber;
    final masked = '*' * (accountNumber.length - visibleDigits);
    final visible = accountNumber.substring(accountNumber.length - visibleDigits);
    return '$masked$visible';
  }

  /// Format card number (e.g., "**** **** **** 1234")
  static String cardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    final lastFour = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $lastFour';
  }
}
