/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App Information
  static const String appName = 'Klarity'; // TEMPORARY - will be changed later
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Modern expense tracking app with EMI management, budgets, and analytics';

  /// Authentication
  static const int pinLength = 4;
  static const int maxLoginAttempts = 5;
  static const Duration sessionTimeout = Duration(minutes: 15);
  static const Duration biometricTimeout = Duration(seconds: 30);

  /// Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxCategoryNameLength = 30;
  static const int maxAccountNameLength = 50;

  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Transaction
  static const double maxTransactionAmount = 999999999.99;
  static const double minTransactionAmount = 0.01;

  /// Budget
  static const double maxBudgetAmount = 999999999.99;
  static const double minBudgetAmount = 0.01;

  /// EMI
  static const int maxEmiTenureMonths = 360; // 30 years
  static const int minEmiTenureMonths = 1;
  static const double maxInterestRate = 100.0;
  static const double minInterestRate = 0.0;

  /// Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String timeFormat = 'hh:mm a';
  static const String monthYearFormat = 'MMM yyyy';
  static const String fullDateFormat = 'EEEE, dd MMMM yyyy';

  /// Currency
  static const String currencySymbol = '\$';
  static const String currencyCode = 'USD';
  static const int currencyDecimalDigits = 2;

  /// Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  /// Debounce Durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration inputDebounce = Duration(milliseconds: 300);

  /// Cache Durations
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(minutes: 15);
  static const Duration longCacheDuration = Duration(hours: 1);

  /// Alerts & Notifications
  static const double lowBalanceThreshold = 100.0;
  static const int budgetWarningPercentage = 80;
  static const int budgetExceededPercentage = 100;

  /// Glassmorphism Effect
  static const double glassBlur = 10.0;
  static const double glassOpacity = 0.1;

  /// Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;

  /// Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  /// Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  /// Chart
  static const int maxChartDataPoints = 12;
  static const double chartBarWidth = 16.0;
  static const double chartLineWidth = 3.0;

  /// Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unexpected error occurred.';
  static const String sessionExpired = 'Your session has expired. Please login again.';
  static const String invalidCredentials = 'Invalid email or password.';
  static const String accountLocked = 'Account locked due to too many failed attempts.';

  /// Success Messages
  static const String loginSuccess = 'Welcome back!';
  static const String signupSuccess = 'Account created successfully!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';
  static const String transactionAddedSuccess = 'Transaction added successfully!';
  static const String transactionUpdatedSuccess = 'Transaction updated successfully!';
  static const String transactionDeletedSuccess = 'Transaction deleted successfully!';
}
