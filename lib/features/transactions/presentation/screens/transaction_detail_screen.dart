import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../providers/transaction_provider.dart';
import 'transaction_form_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  Future<void> _handleEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );

    if (result == true && context.mounted) {
      // Transaction was updated, pop back to list
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
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

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(transactionProvider.notifier)
          .deleteTransaction(transaction.id);

      if (context.mounted) {
        result.fold(
          onSuccess: (_) {
            context.showSuccessSnackBar('Transaction deleted successfully');
            Navigator.pop(context, true);
          },
          onFailure: (exception) {
            context.showErrorSnackBar(exception.message);
          },
        );
      }
    }
  }

  Future<void> _handleUnlock(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: Colors.orange),
            SizedBox(width: 8),
            Text('Unlock Transaction'),
          ],
        ),
        content: const Text(
          'This transaction is locked because it\'s older than 2 months. '
          'Do you want to unlock it for editing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(transactionProvider.notifier)
          .unlockTransaction(transaction.id);

      if (context.mounted) {
        result.fold(
          onSuccess: (_) {
            context.showSuccessSnackBar('Transaction unlocked successfully');
            Navigator.pop(context, true); // Go back to refresh
          },
          onFailure: (exception) {
            context.showErrorSnackBar(exception.message);
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (transaction.isLocked)
            IconButton(
              icon: const Icon(Icons.lock_open, color: Colors.orange),
              tooltip: 'Unlock Transaction',
              onPressed: () => _handleUnlock(context, ref),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.lightPrimary),
              onPressed: () => _handleEdit(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _handleDelete(context, ref),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncome
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isIncome ? 'Income' : 'Expense',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Category
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: transaction.categoryName ?? 'Unknown',
              emoji: transaction.categoryIcon,
            ),

            const SizedBox(height: 16),

            // Account
            _DetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Account',
              value: transaction.accountName ?? 'Unknown',
            ),

            const SizedBox(height: 16),

            // Date
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: DateFormat('dd MMM yyyy, hh:mm a').format(transaction.transactionDate),
            ),

            const SizedBox(height: 16),

            // Description
            if (transaction.description != null && transaction.description!.isNotEmpty) ...[
              _DetailRow(
                icon: Icons.description_outlined,
                label: 'Description',
                value: transaction.description!,
              ),
              const SizedBox(height: 16),
            ],

            // Created At
            _DetailRow(
              icon: Icons.info_outline,
              label: 'Created',
              value: DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt),
            ),

            const SizedBox(height: 16),

            // Updated At
            if (transaction.updatedAt != transaction.createdAt)
              _DetailRow(
                icon: Icons.update_outlined,
                label: 'Last Updated',
                value: DateFormat('dd MMM yyyy, hh:mm a').format(transaction.updatedAt),
              ),

            // Locked Status
            if (transaction.isLocked) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Locked',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This transaction cannot be edited or deleted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                            ),
                          ),
                          if (transaction.lockedAt != null)
                            Text(
                              'Locked on ${DateFormat('dd MMM yyyy').format(transaction.lockedAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: !transaction.isLocked
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () => _handleEdit(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lightPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? emoji;

  const _DetailRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.emoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lightPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.lightPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (emoji != null) ...[
                      Text(
                        emoji!,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
