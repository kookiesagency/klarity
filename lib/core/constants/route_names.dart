/// Route names for navigation
class RouteNames {
  RouteNames._();

  // ==================== Authentication Routes ====================
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';
  static const String pinSetup = '/pin-setup';
  static const String pinLogin = '/pin-login';
  static const String biometricSetup = '/biometric-setup';

  // ==================== Main App Routes ====================
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // ==================== Profile Routes ====================
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String profileSelection = '/profile/selection';
  static const String createProfile = '/profile/create';
  static const String settings = '/settings';
  static const String changePassword = '/settings/change-password';
  static const String changePIN = '/settings/change-pin';
  static const String securitySettings = '/settings/security';
  static const String notificationSettings = '/settings/notifications';
  static const String themeSettings = '/settings/theme';

  // ==================== Account Routes ====================
  static const String accounts = '/accounts';
  static const String accountDetails = '/accounts/:id';
  static const String addAccount = '/accounts/add';
  static const String editAccount = '/accounts/:id/edit';
  static const String accountTransactions = '/accounts/:id/transactions';

  // ==================== Category Routes ====================
  static const String categories = '/categories';
  static const String addCategory = '/categories/add';
  static const String editCategory = '/categories/:id/edit';

  // ==================== Transaction Routes ====================
  static const String transactions = '/transactions';
  static const String transactionDetails = '/transactions/:id';
  static const String addTransaction = '/transactions/add';
  static const String addExpense = '/transactions/add/expense';
  static const String addIncome = '/transactions/add/income';
  static const String editTransaction = '/transactions/:id/edit';
  static const String bulkDeleteTransactions = '/transactions/bulk-delete';
  static const String bulkEditTransactions = '/transactions/bulk-edit';

  // ==================== Transfer Routes ====================
  static const String transfers = '/transfers';
  static const String transferDetails = '/transfers/:id';
  static const String addTransfer = '/transfers/add';
  static const String editTransfer = '/transfers/:id/edit';

  // ==================== Recurring Transaction Routes ====================
  static const String recurringTransactions = '/recurring';
  static const String recurringDetails = '/recurring/:id';
  static const String addRecurring = '/recurring/add';
  static const String editRecurring = '/recurring/:id/edit';

  // ==================== Scheduled Payment Routes ====================
  static const String scheduledPayments = '/scheduled';
  static const String scheduledDetails = '/scheduled/:id';
  static const String addScheduled = '/scheduled/add';
  static const String editScheduled = '/scheduled/:id/edit';
  static const String partialPayment = '/scheduled/:id/partial-payment';

  // ==================== EMI Routes ====================
  static const String emis = '/emis';
  static const String emiDetails = '/emis/:id';
  static const String addEmi = '/emis/add';
  static const String editEmi = '/emis/:id/edit';
  static const String emiCalculator = '/emis/calculator';
  static const String emiPayments = '/emis/:id/payments';

  // ==================== Budget Routes ====================
  static const String budgets = '/budgets';
  static const String budgetDetails = '/budgets/:id';
  static const String addBudget = '/budgets/add';
  static const String editBudget = '/budgets/:id/edit';

  // ==================== Analytics Routes ====================
  static const String analytics = '/analytics';
  static const String expenseAnalytics = '/analytics/expenses';
  static const String incomeAnalytics = '/analytics/income';
  static const String categoryAnalytics = '/analytics/categories';
  static const String accountAnalytics = '/analytics/accounts';
  static const String budgetAnalytics = '/analytics/budgets';
  static const String customDateRange = '/analytics/custom-range';

  // ==================== Reports Routes ====================
  static const String reports = '/reports';
  static const String exportReport = '/reports/export';
  static const String customReport = '/reports/custom';

  // ==================== Backup & Sync Routes ====================
  static const String backup = '/backup';
  static const String restore = '/restore';

  // ==================== About & Help Routes ====================
  static const String about = '/about';
  static const String help = '/help';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
}
