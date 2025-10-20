import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/account_model.dart';
import '../providers/account_provider.dart';
import 'account_form_screen.dart';
import 'account_detail_screen.dart';

class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends ConsumerState<AccountManagementScreen> {

  Future<void> _handleAddAccount() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountFormScreen(),
      ),
    );

    if (result == true && mounted) {
      // Account was created successfully, list will auto-update via provider
    }
  }

  Future<void> _handleViewAccount(AccountModel account) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AccountDetailScreen(account: account),
      ),
    );

    if (result == true && mounted) {
      // Account was updated successfully, list will auto-update via provider
    }
  }

  Future<void> _handleDeleteAccount(AccountModel account) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${account.name}"?\n\n'
          'This will permanently delete all transactions associated with this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await ref.read(accountProvider.notifier).deleteAccount(account.id);

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            context.showSuccessSnackBar('Account deleted successfully');
          },
          onFailure: (exception) {
            context.showErrorSnackBar(exception.message);
          },
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accountState = ref.watch(accountProvider);
    final accounts = accountState.accounts;
    final activeProfile = ref.watch(activeProfileProvider);

    // Calculate total balance
    final totalBalance = accounts.fold<double>(
      0.0,
      (sum, account) => sum + account.currentBalance,
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Accounts',
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (activeProfile != null)
              Text(
                activeProfile.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: accountState.isLoading
          ? Center(child: CircularProgressIndicator())
          : accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Accounts Yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first account to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                          final account = accounts[index];
                          final isPositive = account.currentBalance >= 0;

                          return Dismissible(
                            key: Key(account.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              await _handleDeleteAccount(account);
                              return false; // We handle deletion manually
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () => _handleViewAccount(account),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Account Icon
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: account.type.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          account.type.icon,
                                          color: account.type.color,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Account Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: account.type.color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              account.type.displayName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: account.type.color,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Balance
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatCurrency(account.currentBalance),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isPositive ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Icon(
                                          isPositive
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_downward_rounded,
                                          size: 14,
                                          color: isPositive ? AppColors.success : AppColors.error,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddAccount,
        backgroundColor: AppColors.lightPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
