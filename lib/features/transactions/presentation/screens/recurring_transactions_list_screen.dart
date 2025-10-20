import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/models/recurring_transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../providers/recurring_transaction_provider.dart';
import 'recurring_transaction_form_screen.dart';
import 'recurring_transaction_detail_screen.dart';

class RecurringTransactionsListScreen extends ConsumerStatefulWidget {
  const RecurringTransactionsListScreen({super.key});

  @override
  ConsumerState<RecurringTransactionsListScreen> createState() =>
      _RecurringTransactionsListScreenState();
}

class _RecurringTransactionsListScreenState
    extends ConsumerState<RecurringTransactionsListScreen> {
  TransactionType? _selectedType;
  bool _showActiveOnly = true;

  Future<void> _refresh() async {
    await ref.read(recurringTransactionProvider.notifier).refresh();
  }

  Future<void> _deleteRecurringTransaction(
    RecurringTransactionModel recurringTransaction,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: Text(
          'Are you sure you want to delete "${recurringTransaction.description ?? "this recurring transaction"}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(recurringTransactionProvider.notifier)
        .deleteRecurringTransaction(recurringTransaction.id);

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        context.showSuccessSnackBar('Recurring transaction deleted');
      },
      onFailure: (exception) {
        context.showErrorSnackBar(exception.message);
      },
    );
  }

  Future<void> _toggleActiveStatus(
    RecurringTransactionModel recurringTransaction,
  ) async {
    final result = await ref
        .read(recurringTransactionProvider.notifier)
        .toggleActiveStatus(
          recurringTransactionId: recurringTransaction.id,
          isActive: !recurringTransaction.isActive,
        );

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        context.showSuccessSnackBar(
          recurringTransaction.isActive
              ? 'Recurring transaction paused'
              : 'Recurring transaction resumed',
        );
      },
      onFailure: (exception) {
        context.showErrorSnackBar(exception.message);
      },
    );
  }

  void _showFilterSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Recurring Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Type Filter
            Text(
              'Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() => _selectedType = null);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Income'),
                  selected: _selectedType == TransactionType.income,
                  onSelected: (selected) {
                    setState(() => _selectedType = TransactionType.income);
                    Navigator.pop(context);
                  },
                  selectedColor: AppColors.success.withOpacity(0.2),
                ),
                FilterChip(
                  label: const Text('Expense'),
                  selected: _selectedType == TransactionType.expense,
                  onSelected: (selected) {
                    setState(() => _selectedType = TransactionType.expense);
                    Navigator.pop(context);
                  },
                  selectedColor: AppColors.error.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Filter
            Text(
              'Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Show Active Only'),
              value: _showActiveOnly,
              onChanged: (value) {
                setState(() => _showActiveOnly = value);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(recurringTransactionProvider);
    var recurringTransactions = state.recurringTransactions;

    // Apply filters
    if (_selectedType != null) {
      recurringTransactions = recurringTransactions
          .where((rt) => rt.type == _selectedType)
          .toList();
    }

    if (_showActiveOnly) {
      recurringTransactions =
          recurringTransactions.where((rt) => rt.isActive).toList();
    }

    return Scaffold(

      appBar: AppBar(
  
        elevation: 0,
        title: Text(
          'Recurring Transactions',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : recurringTransactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recurringTransactions.length,
                    itemBuilder: (context, index) {
                      final recurringTransaction = recurringTransactions[index];
                      return _buildRecurringTransactionCard(
                        recurringTransaction,
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecurringTransactionFormScreen(),
            ),
          );
          if (result == true) {
            _refresh();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No recurring transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first recurring transaction',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringTransactionCard(
    RecurringTransactionModel recurringTransaction,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isIncome = recurringTransaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;

    return Dismissible(
      key: Key(recurringTransaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Recurring Transaction'),
            content: Text(
              'Are you sure you want to delete "${recurringTransaction.description ?? "this recurring transaction"}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref
            .read(recurringTransactionProvider.notifier)
            .deleteRecurringTransaction(recurringTransaction.id);
        context.showSuccessSnackBar('Recurring transaction deleted');
      },
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecurringTransactionDetailScreen(
                recurringTransaction: recurringTransaction,
              ),
            ),
          );
          if (result == true) {
            _refresh();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: recurringTransaction.isActive
                  ? Colors.grey[200]!
                  : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Amount and Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${recurringTransaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: recurringTransaction.isActive
                                ? AppColors.textPrimary
                                : Colors.grey[500],
                          ),
                        ),
                        if (recurringTransaction.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            recurringTransaction.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: recurringTransaction.isActive
                                  ? AppColors.textSecondary
                                  : Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Active/Inactive Toggle
                  Switch(
                    value: recurringTransaction.isActive,
                    onChanged: (value) {
                      _toggleActiveStatus(recurringTransaction);
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category and Account
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recurringTransaction.categoryIcon ?? '📁',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recurringTransaction.categoryName ?? 'Category',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recurringTransaction.accountName ?? 'Account',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Frequency and Next Due Date
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recurringTransaction.frequency.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Next: ${DateFormat('MMM dd, yyyy').format(recurringTransaction.nextDueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // End Date if present
              if (recurringTransaction.endDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ends: ${DateFormat('MMM dd, yyyy').format(recurringTransaction.endDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Inactive Badge
              if (!recurringTransaction.isActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Paused',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
