import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/category_type.dart';
import '../providers/category_provider.dart';
import 'category_form_screen.dart';
import 'category_detail_screen.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../budgets/domain/models/budget_model.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAddCategory() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryFormScreen(),
      ),
    );

    if (result == true && mounted) {
      // Category was created successfully, list will auto-update via provider
    }
  }

  Future<void> _handleViewCategory(CategoryModel category) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(category: category),
      ),
    );

    if (result == true && mounted) {
      // Category was updated successfully, list will auto-update via provider
    }
  }

  Future<void> _handleDeleteCategory(CategoryModel category) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\n'
          'This will not delete existing transactions using this category.',
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
      final result = await ref.read(categoryProvider.notifier).deleteCategory(category.id);

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            context.showSuccessSnackBar('Category deleted successfully');
          },
          onFailure: (exception) {
            context.showErrorSnackBar(exception.message);
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final expenseCategories = categoryState.expenseCategories;
    final incomeCategories = categoryState.incomeCategories;
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (activeProfile != null)
              Text(
                activeProfile.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.lightPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.lightPrimary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_downward, size: 18),
                  const SizedBox(width: 8),
                  Text('Expense (${expenseCategories.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_upward, size: 18),
                  const SizedBox(width: 8),
                  Text('Income (${incomeCategories.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: categoryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Expense Categories Tab
                _buildCategoryList(
                  categories: expenseCategories,
                  emptyMessage: 'No expense categories yet',
                  type: CategoryType.expense,
                ),
                // Income Categories Tab
                _buildCategoryList(
                  categories: incomeCategories,
                  emptyMessage: 'No income categories yet',
                  type: CategoryType.income,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddCategory,
        backgroundColor: AppColors.lightPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Category',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList({
    required List<CategoryModel> categories,
    required String emptyMessage,
    required CategoryType type,
  }) {
    if (categories.isEmpty) {
      return Center(
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
                Icons.category_outlined,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first ${type.displayName.toLowerCase()} category',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        return Dismissible(
          key: Key(category.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            await _handleDeleteCategory(category);
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
          child: Consumer(
            builder: (context, ref, _) {
              // Get budget status for expense categories
              final budgetState = ref.watch(budgetProvider);
              final budgetStatus = type == CategoryType.expense
                  ? budgetState.budgetStatuses[category.id]
                  : null;

              return GestureDetector(
                onTap: () => _handleViewCategory(category),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Category Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                category.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Category Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (budgetStatus != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${budgetStatus.spent.toStringAsFixed(0)} / ₹${budgetStatus.budget.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Budget percentage or arrow
                          if (budgetStatus != null)
                            Text(
                              '${budgetStatus.percentage.clamp(0.0, 100.0).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getBudgetColor(budgetStatus.alertLevel),
                              ),
                            )
                          else
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                        ],
                      ),

                      // Budget Progress Bar
                      if (budgetStatus != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (budgetStatus.percentage / 100).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[200],
                            color: _getBudgetColor(budgetStatus.alertLevel),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getBudgetStatusText(budgetStatus.alertLevel, budgetStatus.isOverBudget),
                              style: TextStyle(
                                fontSize: 11,
                                color: _getBudgetColor(budgetStatus.alertLevel),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (budgetStatus.isOverBudget)
                              Text(
                                'Over by ₹${budgetStatus.overBudgetAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              Text(
                                '₹${budgetStatus.remaining.toStringAsFixed(0)} left',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getBudgetColor(BudgetAlertLevel level) {
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

  String _getBudgetStatusText(BudgetAlertLevel level, bool isOverBudget) {
    if (isOverBudget) return '⚠️ Over Budget';
    switch (level) {
      case BudgetAlertLevel.safe:
        return '✅ On Track';
      case BudgetAlertLevel.warning:
        return '⚡ Monitor';
      case BudgetAlertLevel.critical:
        return '⚠️ Near Limit';
      case BudgetAlertLevel.overBudget:
        return '❌ Over Budget';
    }
  }
}
