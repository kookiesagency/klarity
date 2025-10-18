/// Keys for local storage (SharedPreferences & SecureStorage)
class StorageKeys {
  StorageKeys._();

  // ==================== Secure Storage Keys ====================
  // These are stored in flutter_secure_storage (encrypted)

  /// User authentication token
  static const String authToken = 'auth_token';

  /// Refresh token for authentication
  static const String refreshToken = 'refresh_token';

  /// User's 4-digit PIN for quick unlock
  static const String userPin = 'user_pin';

  /// Biometric authentication enabled flag
  static const String biometricEnabled = 'biometric_enabled';

  /// User's encrypted password (for backup)
  static const String encryptedPassword = 'encrypted_password';

  // ==================== Shared Preferences Keys ====================
  // These are stored in SharedPreferences (not encrypted)

  /// User ID
  static const String userId = 'user_id';

  /// User email
  static const String userEmail = 'user_email';

  /// User's full name
  static const String userName = 'user_name';

  /// Selected profile ID (Personal/Company)
  static const String selectedProfileId = 'selected_profile_id';

  /// Theme mode preference
  static const String themeMode = 'theme_mode';

  /// Onboarding completed flag
  static const String onboardingCompleted = 'onboarding_completed';

  /// First launch flag
  static const String isFirstLaunch = 'is_first_launch';

  /// Last sync timestamp
  static const String lastSyncTimestamp = 'last_sync_timestamp';

  /// App language code
  static const String languageCode = 'language_code';

  /// Notifications enabled flag
  static const String notificationsEnabled = 'notifications_enabled';

  /// Low balance alerts enabled
  static const String lowBalanceAlertsEnabled = 'low_balance_alerts_enabled';

  /// Budget alerts enabled
  static const String budgetAlertsEnabled = 'budget_alerts_enabled';

  /// EMI reminders enabled
  static const String emiRemindersEnabled = 'emi_reminders_enabled';

  /// Default currency
  static const String defaultCurrency = 'default_currency';

  /// Date format preference
  static const String dateFormatPreference = 'date_format_preference';

  /// Show running balance flag
  static const String showRunningBalance = 'show_running_balance';

  /// Auto-backup enabled
  static const String autoBackupEnabled = 'auto_backup_enabled';

  /// Last backup timestamp
  static const String lastBackupTimestamp = 'last_backup_timestamp';

  /// Analytics opt-in flag
  static const String analyticsOptIn = 'analytics_opt_in';

  /// Failed login attempts count
  static const String failedLoginAttempts = 'failed_login_attempts';

  /// Account locked timestamp
  static const String accountLockedTimestamp = 'account_locked_timestamp';

  /// Session start timestamp
  static const String sessionStartTimestamp = 'session_start_timestamp';

  /// Remember me flag
  static const String rememberMe = 'remember_me';
}
