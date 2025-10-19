import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/models/recurring_transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../providers/recurring_transaction_provider.dart';
import 'recurring_transaction_form_screen.dart';

class RecurringTransactionDetailScreen extends ConsumerWidget {
  final RecurringTransactionModel recurringTransaction;

  const RecurringTransactionDetailScreen({
    Key? key,
    required this.recurringTransaction,
  }) : super(key: key);

  Future<void> _handleEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecurringTransactionFormScreen(
          recurringTransaction: recurringTransaction,
        ),
      ),
    );

    if (result == true && context.mounted) {
      // Recurring transaction was updated, pop back to list
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: const Text(
          'Are you sure you want to delete this recurring transaction?\n\n'
          'This will not delete existing transactions that have already been created.',
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

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(recurringTransactionProvider.notifier)
          .deleteRecurringTransaction(recurringTransaction.id);

      if (context.mounted) {
        result.fold(
          onSuccess: (_) {
            context.showSuccessSnackBar('Recurring transaction deleted successfully');
            Navigator.pop(context, true);
          },
          onFailure: (exception) {
            context.showErrorSnackBar(exception.message);
          },
        );
      }
    }
  }

  Future<void> _handleToggleActive(BuildContext context, WidgetRef ref) async {
    final newStatus = !recurringTransaction.isActive;
    final result = await ref
        .read(recurringTransactionProvider.notifier)
        .updateRecurringTransaction(
          recurringTransactionId: recurringTransaction.id,
          accountId: recurringTransaction.accountId,
          categoryId: recurringTransaction.categoryId,
          type: recurringTransaction.type,
          amount: recurringTransaction.amount,
          description: recurringTransaction.description,
          frequency: recurringTransaction.frequency,
          startDate: recurringTransaction.startDate,
          endDate: recurringTransaction.endDate,
          isActive: newStatus,
        );

    if (context.mounted) {
      result.fold(
        onSuccess: (_) {
          context.showSuccessSnackBar(
            newStatus ? 'Recurring transaction activated' : 'Recurring transaction deactivated',
          );
        },
        onFailure: (exception) {
          context.showErrorSnackBar(exception.message);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = recurringTransaction.type == TransactionType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final hasEnded = recurringTransaction.hasEnded();
    final isDueToday = recurringTransaction.isDueToday();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recurring Transaction',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.lightPrimary),
            onPressed: () => _handleEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _handleDelete(context, ref),
          ),
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
                    Icons.autorenew,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recurring ${isIncome ? 'Income' : 'Expense'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${recurringTransaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      recurringTransaction.frequency.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status Cards
            if (hasEnded) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recurring Period Ended',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This recurring transaction has completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (isDueToday) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Today',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This recurring transaction is scheduled for today',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!recurringTransaction.isActive) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pause_circle_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inactive',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This recurring transaction is currently paused',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Category
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: recurringTransaction.categoryName ?? 'Unknown',
              emoji: recurringTransaction.categoryIcon,
            ),

            const SizedBox(height: 12),

            // Account
            _DetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Account',
              value: recurringTransaction.accountName ?? 'Unknown',
            ),

            const SizedBox(height: 12),

            // Frequency
            _DetailRow(
              icon: Icons.repeat,
              label: 'Frequency',
              value: recurringTransaction.frequency.label,
            ),

            const SizedBox(height: 12),

            // Start Date
            _DetailRow(
              icon: Icons.play_arrow,
              label: 'Start Date',
              value: DateFormat('dd MMM yyyy').format(recurringTransaction.startDate),
            ),

            const SizedBox(height: 12),

            // End Date
            _DetailRow(
              icon: Icons.stop,
              label: 'End Date',
              value: recurringTransaction.endDate != null
                  ? DateFormat('dd MMM yyyy').format(recurringTransaction.endDate!)
                  : 'No end date',
            ),

            const SizedBox(height: 12),

            // Next Due Date
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Next Due Date',
              value: DateFormat('dd MMM yyyy').format(recurringTransaction.nextDueDate),
            ),

            const SizedBox(height: 12),

            // Description
            if (recurringTransaction.description != null &&
                recurringTransaction.description!.isNotEmpty) ...[
              _DetailRow(
                icon: Icons.description_outlined,
                label: 'Description',
                value: recurringTransaction.description!,
              ),
              const SizedBox(height: 12),
            ],

            // Status
            _DetailRow(
              icon: Icons.toggle_on_outlined,
              label: 'Status',
              value: '',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: recurringTransaction.isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      recurringTransaction.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: recurringTransaction.isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _handleToggleActive(context, ref),
                    icon: Icon(
                      recurringTransaction.isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      color: recurringTransaction.isActive ? Colors.orange : Colors.green,
                    ),
                    tooltip: recurringTransaction.isActive ? 'Deactivate' : 'Activate',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Metadata
            const Text(
              'Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _DetailRow(
              icon: Icons.info_outline,
              label: 'Created',
              value: DateFormat('dd MMM yyyy, hh:mm a').format(recurringTransaction.createdAt),
            ),

            const SizedBox(height: 12),

            if (recurringTransaction.updatedAt != recurringTransaction.createdAt)
              _DetailRow(
                icon: Icons.update_outlined,
                label: 'Last Updated',
                value: DateFormat('dd MMM yyyy, hh:mm a').format(recurringTransaction.updatedAt),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
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
                'Edit Recurring Transaction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? emoji;
  final Widget? trailing;

  const _DetailRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.emoji,
    this.trailing,
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
                if (value.isNotEmpty) ...[
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
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
