import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';
import '../../../transactions/presentation/screens/transaction_detail_screen.dart';
import '../../../transactions/presentation/screens/transaction_list_screen.dart';
import '../../../transactions/presentation/screens/transfer_form_screen.dart';
import '../../../transactions/presentation/screens/recurring_transactions_list_screen.dart';
import '../../../transactions/presentation/screens/recurring_transaction_detail_screen.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../../transactions/presentation/providers/recurring_transaction_provider.dart';
import '../../../transactions/presentation/providers/emi_provider.dart';
import '../../../transactions/presentation/screens/emi_list_screen.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../budgets/domain/models/budget_model.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/category_detail_screen.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../scheduled_payments/presentation/providers/scheduled_payment_provider.dart';
import '../../../scheduled_payments/presentation/screens/scheduled_payments_list_screen.dart';
import '../../../scheduled_payments/presentation/screens/scheduled_payment_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedAccountId; // null = Total Balance

  @override
  void initState() {
    super.initState();
    // Data will be loaded automatically by providers listening to profile changes
  }

  /// Reload data when account filter changes
  Future<void> _reloadDataForAccount(String? accountId) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    if (accountId == null) {
      // Load all data (no filter)
      await ref.read(transactionProvider.notifier).loadTransactions(activeProfile.id);
    } else {
      // Load transactions filtered by account
      await ref.read(transactionProvider.notifier).loadTransactionsByAccount(
        profileId: activeProfile.id,
        accountId: accountId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with balance
            _buildHeader(context, activeProfile),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Income & Outcome Summary
                    Consumer(
                      builder: (context, ref, child) {
                        final transactionState = ref.watch(transactionProvider);
                        final totalIncome = transactionState.totalIncome;
                        final totalExpense = transactionState.totalExpense;

                        return Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                title: 'Income',
                                amount: '₹${totalIncome.toStringAsFixed(2)}',
                                icon: Icons.arrow_downward_rounded,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                title: 'Expenses',
                                amount: '₹${totalExpense.toStringAsFixed(2)}',
                                icon: Icons.arrow_upward_rounded,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // Budget Overview
                    _buildBudgetOverview(),

                    // Upcoming Recurring Transactions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upcoming Recurring',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RecurringTransactionsListScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recurring Transactions List
                    Consumer(
                      builder: (context, ref, child) {
                        final upcomingRecurring = ref.watch(upcomingRecurringTransactionsProvider);
                        // Filter by selected account if one is selected
                        final filteredRecurring = _selectedAccountId == null
                            ? upcomingRecurring
                            : upcomingRecurring.where((r) => r.accountId == _selectedAccountId).toList();
                        final displayRecurring = filteredRecurring.take(3).toList();

                        if (displayRecurring.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No upcoming recurring transactions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: displayRecurring.map((recurring) {
                            final isIncome = recurring.type == TransactionType.income;
                            final dateFormat = DateFormat('MMM dd');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildTransactionItem(
                                icon: recurring.categoryIcon ?? '🔄',
                                title: recurring.description ?? recurring.categoryName ?? 'Recurring',
                                subtitle: '${recurring.frequency.label} • ${recurring.accountName ?? 'Unknown'}',
                                amount: '${isIncome ? '+' : '-'}₹${recurring.amount.toStringAsFixed(2)}',
                                date: 'Next: ${dateFormat.format(recurring.nextDueDate)}',
                                isExpense: !isIncome,
                                onTap: () {
                                  // Navigate to recurring transaction detail screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RecurringTransactionDetailScreen(
                                        recurringTransaction: recurring,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Recent Transactions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TransactionListScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Transaction List
                    Consumer(
                      builder: (context, ref, child) {
                        final transactions = ref.watch(transactionsListProvider);
                        final recentTransactions = transactions.take(5).toList();

                        if (recentTransactions.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No transactions yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Start adding your income and expenses',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: recentTransactions.map((transaction) {
                            final isIncome = transaction.type == TransactionType.income;
                            final dateFormat = DateFormat('MMM dd');
                            final now = DateTime.now();
                            final transactionDate = transaction.transactionDate;

                            String dateLabel;
                            if (DateFormat('yyyy-MM-dd').format(transactionDate) ==
                                DateFormat('yyyy-MM-dd').format(now)) {
                              dateLabel = 'Today';
                            } else if (DateFormat('yyyy-MM-dd').format(transactionDate) ==
                                DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)))) {
                              dateLabel = 'Yesterday';
                            } else {
                              dateLabel = dateFormat.format(transactionDate);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildTransactionItem(
                                icon: transaction.categoryIcon ?? '📝',
                                title: transaction.categoryName ?? 'Unknown',
                                subtitle: transaction.accountName ?? 'Unknown Account',
                                amount: '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                                date: dateLabel,
                                isExpense: !isIncome,
                                onTap: () {
                                  // Navigate to transaction detail screen (view mode)
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TransactionDetailScreen(
                                        transaction: transaction,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Scheduled Payments Section
                    _buildUpcomingScheduledPayments(),

                    const SizedBox(height: 24),

                    // EMI Overview (moved to bottom)
                    _buildEmiOverview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, activeProfile) {
    final profiles = ref.watch(profilesListProvider);
    final accounts = ref.watch(accountsListProvider);

    // Calculate total or selected account balance
    double displayBalance = 0;
    String displayName = 'Total Balance';

    if (_selectedAccountId == null) {
      // Total balance - sum all accounts
      displayBalance = accounts.fold(0.0, (sum, account) => sum + account.currentBalance);
    } else {
      // Selected account balance
      final selectedAccount = accounts.firstWhere(
        (acc) => acc.id == _selectedAccountId,
        orElse: () => accounts.first,
      );
      displayBalance = selectedAccount.currentBalance;
      displayName = selectedAccount.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with menu, profile, and notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.menu_rounded, color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary),
                onPressed: () {},
              ),
              // Profile Selector
              GestureDetector(
                onTap: () => _showProfileSelector(profiles, activeProfile),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activeProfile?.name ?? 'Personal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance amount
          Text(
            '₹${displayBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Account selector dropdown
          GestureDetector(
            onTap: _showAccountSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSelector(profiles, activeProfile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: profiles.map<Widget>((profile) {
                    final isActive = activeProfile?.id == profile.id;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            if (!isActive) {
                              ref.read(profileProvider.notifier).switchProfile(profile.id);
                            }
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.account_circle_outlined,
                                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (profile != profiles.last) const Divider(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountSelector() {
    final accounts = ref.read(accountsListProvider);
    final totalBalance = accounts.fold(0.0, (sum, account) => sum + account.currentBalance);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Total Balance option
                    _buildAccountOption(
                      id: null,
                      name: 'Total Balance',
                      balance: totalBalance,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    if (accounts.isNotEmpty) const Divider(),
                    // Individual accounts
                    ...accounts.map((account) {
                      return Column(
                        children: [
                          _buildAccountOption(
                            id: account.id,
                            name: account.name,
                            balance: account.currentBalance,
                            icon: account.type.icon,
                          ),
                          if (account != accounts.last) const Divider(),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOption({
    required String? id,
    required String name,
    required double balance,
    required IconData icon,
  }) {
    final isSelected = _selectedAccountId == id;

    return InkWell(
      onTap: () async {
        setState(() {
          _selectedAccountId = id;
        });
        Navigator.pop(context);

        // Reload data filtered by selected account
        await _reloadDataForAccount(id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '₹${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required dynamic icon, // Can be IconData or String (emoji)
    required String title,
    required String subtitle,
    required String amount,
    required String date,
    required bool isExpense,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isExpense ? AppColors.error : AppColors.success).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: icon is String
                  ? Text(icon, style: const TextStyle(fontSize: 24))
                  : Icon(
                      icon,
                      color: isExpense ? AppColors.error : AppColors.success,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  // Quick Actions Buttons
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            label: 'Income',
            icon: Icons.add_circle_outline,
            color: AppColors.success,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionFormScreen(
                    initialType: TransactionType.income,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            label: 'Expense',
            icon: Icons.remove_circle_outline,
            color: AppColors.error,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionFormScreen(
                    initialType: TransactionType.expense,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            label: 'Transfer',
            icon: Icons.swap_horiz,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransferFormScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverview() {
    return Consumer(
      builder: (context, ref, child) {
        final budgetState = ref.watch(budgetProvider);
        final categoryState = ref.watch(categoryProvider);
        final categories = categoryState.categories;

        // Get all budget statuses and filter for warnings (at or above alert threshold)
        final budgetWarnings = budgetState.budgetStatuses.values
            .where((status) =>
                status.alertLevel == BudgetAlertLevel.warning ||
                status.alertLevel == BudgetAlertLevel.critical ||
                status.alertLevel == BudgetAlertLevel.overBudget)
            .toList();

        // Don't show section if no budget warnings
        if (budgetWarnings.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by percentage (highest first)
        budgetWarnings.sort((a, b) => b.percentage.compareTo(a.percentage));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Budget Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to category management screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryManagementScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Budget warning cards
            ...budgetWarnings.take(3).map((status) {
              // Find the matching category
              final category = categories.firstWhere(
                (cat) => cat.id == status.budget.categoryId,
                orElse: () => categories.first, // Fallback if not found
              );

              final color = _getBudgetAlertColor(status.alertLevel);
              final isOverBudget = status.isOverBudget;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailScreen(
                          category: category,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Category icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  category.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Category name and status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOverBudget
                                        ? 'Over by ₹${status.overBudgetAmount.toStringAsFixed(0)}'
                                        : '${status.percentage.toStringAsFixed(0)}% used',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Warning icon
                            Icon(
                              isOverBudget
                                  ? Icons.warning_rounded
                                  : Icons.info_outline_rounded,
                              color: color,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (status.percentage / 100).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            color: color,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Budget info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${status.spent.toStringAsFixed(0)} / ₹${status.budget.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            if (!isOverBudget)
                              Text(
                                '₹${status.remaining.toStringAsFixed(0)} left',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Color _getBudgetAlertColor(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.safe:
        return AppColors.success;
      case BudgetAlertLevel.warning:
        return Colors.orange;
      case BudgetAlertLevel.critical:
        return Colors.deepOrange;
      case BudgetAlertLevel.overBudget:
        return AppColors.error;
    }
  }

  Widget _buildEmiOverview() {
    return Consumer(
      builder: (context, ref, child) {
        final emiState = ref.watch(emiProvider);

        // Filter by selected account if one is selected
        final filteredActiveEmis = _selectedAccountId == null
            ? emiState.activeEmis
            : emiState.activeEmis.where((e) => e.accountId == _selectedAccountId).toList();

        final filteredUpcomingEmis = _selectedAccountId == null
            ? emiState.upcomingEmis
            : emiState.upcomingEmis.where((e) => e.accountId == _selectedAccountId).toList();

        final filteredTotalMonthly = filteredActiveEmis.fold<double>(
          0.0,
          (sum, emi) => sum + emi.monthlyPayment,
        );

        final filteredTotalRemaining = filteredActiveEmis.fold<double>(
          0.0,
          (sum, emi) => sum + emi.remainingAmount,
        );

        // Don't show section if no active EMIs (after filtering)
        if (filteredActiveEmis.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EMI Tracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmiListScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // EMI Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monthly EMI',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${filteredTotalMonthly.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payments,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active EMIs',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filteredActiveEmis.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upcoming',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filteredUpcomingEmis.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remaining',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${(filteredTotalRemaining / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Upcoming EMIs Preview
                  if (filteredUpcomingEmis.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    ...filteredUpcomingEmis.take(2).map((emi) {
                      final dateFormat = DateFormat('MMM dd');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.schedule,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emi.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Due: ${dateFormat.format(emi.nextPaymentDate)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${emi.monthlyPayment.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingScheduledPayments() {
    return Consumer(
      builder: (context, ref, child) {
        final upcomingPayments = ref.watch(upcomingPaymentsProvider);

        // Don't show if no upcoming payments
        if (upcomingPayments.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scheduled Payments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduledPaymentsListScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scheduled Payments List (show up to 3)
            ...upcomingPayments.take(3).map((payment) {
              final dateFormat = DateFormat('MMM dd');
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: payment.isOverdue ? Colors.red : Colors.grey[200]!,
                    width: payment.isOverdue ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduledPaymentDetailScreen(
                          payment: payment,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // Category icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: payment.type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            payment.categoryIcon ?? '📁',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Payment info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.payeeName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: payment.isOverdue
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  payment.isOverdue
                                      ? 'Overdue'
                                      : 'Due ${dateFormat.format(payment.dueDate)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: payment.isOverdue
                                        ? Colors.red
                                        : Colors.grey[600],
                                    fontWeight: payment.isOverdue
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Amount
                      Text(
                        '₹${payment.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: payment.type.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

}
