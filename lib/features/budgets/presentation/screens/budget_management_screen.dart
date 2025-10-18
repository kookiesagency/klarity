import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/models/budget_period.dart';
import '../providers/budget_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../../categories/domain/models/category_type.dart';

class BudgetManagementScreen extends ConsumerWidget {
  const BudgetManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final categories = ref.watch(categoriesListProvider);
    final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenseCategories.isEmpty
              ? const Center(child: Text('No expense categories found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenseCategories.length,
                  itemBuilder: (context, index) {
                    final category = expenseCategories[index];
                    final budgetStatus = budgetState.budgetStatuses[category.id];

                    return _BudgetCategoryCard(
                      category: category,
                      budgetStatus: budgetStatus,
                      onSetBudget: () => _showBudgetDialog(context, ref, category, budgetStatus),
                    );
                  },
                ),
    );
  }

  void _showBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
    BudgetStatus? currentStatus,
  ) {
    final amountController = TextEditingController(
      text: currentStatus?.budget.amount.toStringAsFixed(0) ?? '',
    );
    final thresholdController = TextEditingController(
      text: currentStatus?.budget.alertThreshold.toString() ?? '80',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget Amount',
                prefixText: '₹ ',
                hintText: '5000',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Alert Threshold (%)',
                suffixText: '%',
                hintText: '80',
                helperText: 'Warn when spending reaches this %',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (currentStatus != null)
            TextButton(
              onPressed: () async {
                await ref.read(budgetProvider.notifier).deleteBudget(currentStatus.budget.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              final threshold = int.tryParse(thresholdController.text);

              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              if (threshold == null || threshold < 0 || threshold > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Threshold must be between 0-100%')),
                );
                return;
              }

              if (currentStatus != null) {
                // Update existing budget
                await ref.read(budgetProvider.notifier).updateBudget(
                      budgetId: currentStatus.budget.id,
                      amount: amount,
                      alertThreshold: threshold,
                    );
              } else {
                // Create new budget
                await ref.read(budgetProvider.notifier).createBudget(
                      categoryId: category.id,
                      amount: amount,
                      period: BudgetPeriod.monthly,
                      alertThreshold: threshold,
                    );
              }

              Navigator.pop(context);
            },
            child: Text(currentStatus != null ? 'Update' : 'Set Budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final BudgetStatus? budgetStatus;
  final VoidCallback onSetBudget;

  const _BudgetCategoryCard({
    Key? key,
    required this.category,
    required this.budgetStatus,
    required this.onSetBudget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (budgetStatus == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Text(
            category.icon,
            style: const TextStyle(fontSize: 32),
          ),
          title: Text(category.name),
          subtitle: const Text('No budget set'),
          trailing: OutlinedButton(
            onPressed: onSetBudget,
            child: const Text('Set Budget'),
          ),
        ),
      );
    }

    // Use local variable for null safety promotion
    final status = budgetStatus!;
    final color = _getStatusColor(status.alertLevel);
    final percentage = status.percentage.clamp(0.0, 100.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSetBudget,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${status.spent.toStringAsFixed(0)} / ₹${status.budget.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (status.isOverBudget)
                        Text(
                          'Over by ₹${status.overBudgetAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          '₹${status.remaining.toStringAsFixed(0)} left',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  color: color,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStatusText(status.alertLevel, status.isOverBudget),
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Monthly Budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.safe:
        return Colors.green;
      case BudgetAlertLevel.warning:
        return Colors.yellow[700]!;
      case BudgetAlertLevel.critical:
        return Colors.orange;
      case BudgetAlertLevel.overBudget:
        return Colors.red;
    }
  }

  String _getStatusText(BudgetAlertLevel level, bool isOverBudget) {
    if (isOverBudget) return '⚠️ Over Budget';
    switch (level) {
      case BudgetAlertLevel.safe:
        return '✅ On Track';
      case BudgetAlertLevel.warning:
        return '⚡ Monitor Spending';
      case BudgetAlertLevel.critical:
        return '⚠️ Approaching Limit';
      case BudgetAlertLevel.overBudget:
        return '❌ Over Budget';
    }
  }
}
