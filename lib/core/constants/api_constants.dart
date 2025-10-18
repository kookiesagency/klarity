/// API and Supabase constants
class ApiConstants {
  ApiConstants._();

  // ==================== Supabase Configuration ====================
  static const String supabaseUrl = 'https://yjzyimlodxwryofqbcvn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqenlpbWxvZHh3cnlvZnFiY3ZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0MjQ5MDQsImV4cCI6MjA3NjAwMDkwNH0.lrRg6WQNcUNEirL8MHkwJAbTnlqS6YXOo6YJeEfbN70';

  // ==================== API Timeouts ====================
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ==================== Table Names ====================
  static const String usersTable = 'users';
  static const String profilesTable = 'profiles';
  static const String accountsTable = 'accounts';
  static const String categoriesTable = 'categories';
  static const String transactionsTable = 'transactions';
  static const String transfersTable = 'transfers';
  static const String recurringTransactionsTable = 'recurring_transactions';
  static const String recurringHistoryTable = 'recurring_history';
  static const String scheduledPaymentsTable = 'scheduled_payments';
  static const String partialPaymentsTable = 'partial_payments';
  static const String emisTable = 'emis';
  static const String emiPaymentsTable = 'emi_payments';
  static const String budgetsTable = 'budgets';
  static const String transactionLocksTable = 'transaction_locks';

  // ==================== RPC Function Names ====================
  static const String calculateRunningBalanceRpc = 'calculate_running_balance';
  static const String getBudgetStatusRpc = 'get_budget_status';
  static const String getCategoryExpensesRpc = 'get_category_expenses';
  static const String getAccountBalanceRpc = 'get_account_balance';
  static const String processRecurringTransactionsRpc = 'process_recurring_transactions';
  static const String processScheduledPaymentsRpc = 'process_scheduled_payments';
  static const String processEmiPaymentsRpc = 'process_emi_payments';

  // ==================== Storage Buckets ====================
  static const String profilePicturesBucket = 'profile_pictures';
  static const String backupsBucket = 'backups';

  // ==================== Query Limits ====================
  static const int defaultLimit = 20;
  static const int maxLimit = 100;

  // ==================== Error Codes ====================
  static const String unauthorizedError = 'UNAUTHORIZED';
  static const String forbiddenError = 'FORBIDDEN';
  static const String notFoundError = 'NOT_FOUND';
  static const String validationError = 'VALIDATION_ERROR';
  static const String duplicateError = 'DUPLICATE_ERROR';
  static const String serverError = 'SERVER_ERROR';
  static const String networkError = 'NETWORK_ERROR';

  // ==================== HTTP Status Codes ====================
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusConflict = 409;
  static const int statusInternalServerError = 500;
}
