import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/category_type.dart';
import '../providers/category_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../budgets/domain/models/budget_period.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final CategoryModel? category; // null for add, non-null for edit

  const CategoryFormScreen({
    super.key,
    this.category,
  });

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetAmountController = TextEditingController();
  final _budgetThresholdController = TextEditingController(text: '80');

  CategoryType _selectedType = CategoryType.expense;
  String _selectedIcon = CategoryIcons.others;
  String _selectedColor = CategoryColors.indigo;
  bool _isLoading = false;
  bool _enableBudget = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedType = widget.category!.type;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.colorHex;

      // Load existing budget if it exists
      if (_selectedType == CategoryType.expense) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final budget = ref.read(budgetProvider.notifier).getBudgetForCategory(widget.category!.id);
          if (budget != null) {
            setState(() {
              _enableBudget = true;
              _budgetAmountController.text = budget.amount.toStringAsFixed(0);
              _budgetThresholdController.text = budget.alertThreshold.toString();
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetAmountController.dispose();
    _budgetThresholdController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.category != null;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      context.showErrorSnackBar('No active profile selected');
      return;
    }

    setState(() => _isLoading = true);

    final result = isEditing
        ? await ref.read(categoryProvider.notifier).updateCategory(
              categoryId: widget.category!.id,
              name: _nameController.text.trim(),
              icon: _selectedIcon,
              colorHex: _selectedColor,
            )
        : await ref.read(categoryProvider.notifier).createCategory(
              name: _nameController.text.trim(),
              type: _selectedType,
              icon: _selectedIcon,
              colorHex: _selectedColor,
            );

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.fold(
      onSuccess: (category) async {
        try {
          // Save budget if this is an expense category and budget is enabled
          if (_selectedType == CategoryType.expense && _enableBudget) {
            final budgetAmount = double.tryParse(_budgetAmountController.text);
            final alertThreshold = int.tryParse(_budgetThresholdController.text) ?? 80;

            if (budgetAmount != null && budgetAmount > 0) {
              final existingBudget = ref.read(budgetProvider.notifier).getBudgetForCategory(category.id);

              if (existingBudget != null) {
                // Update existing budget
                await ref.read(budgetProvider.notifier).updateBudget(
                      budgetId: existingBudget.id,
                      amount: budgetAmount,
                      alertThreshold: alertThreshold,
                    );
              } else {
                // Create new budget
                await ref.read(budgetProvider.notifier).createBudget(
                      categoryId: category.id,
                      amount: budgetAmount,
                      period: BudgetPeriod.monthly,
                      alertThreshold: alertThreshold,
                    );
              }
            }
          } else if (_selectedType == CategoryType.expense && !_enableBudget && isEditing) {
            // Delete budget if it exists but budget is now disabled (only when editing)
            final existingBudget = ref.read(budgetProvider.notifier).getBudgetForCategory(category.id);
            if (existingBudget != null) {
              await ref.read(budgetProvider.notifier).deleteBudget(existingBudget.id);
            }
          }
        } catch (e) {
          // If budget operation fails, log but continue with success
          debugPrint('Budget operation failed: $e');
        }

        if (!mounted) return;
        context.showSuccessSnackBar(
          isEditing ? 'Category updated successfully' : 'Category created successfully',
        );
        Navigator.pop(context, true);
      },
      onFailure: (exception) {
        context.showErrorSnackBar(exception.message);
      },
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Icon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: CategoryIcons.allIcons.length,
                itemBuilder: (context, index) {
                  final icon = CategoryIcons.allIcons[index];
                  final isSelected = _selectedIcon == icon;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIcon = icon);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.lightPrimary.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.lightPrimary
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Color',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: CategoryColors.allColors.map((color) {
                final isSelected = _selectedColor == color;
                final colorValue = _hexToColor(color);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.textPrimary : Colors.grey[300]!,
                        width: isSelected ? 3 : 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
      },
    );
  }

  Color _hexToColor(String hex) {
    try {
      final hexColor = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = _hexToColor(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Category' : 'Add Category',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon & Color Preview
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: selectedColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _selectedIcon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Category Name
              Text(
                'Category Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'e.g., Food, Transport, Salary',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category Type (only for new categories)
              Text(
                'Category Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (isEditing)
                // Show type as read-only for editing
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedType == CategoryType.income
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: _selectedType == CategoryType.income
                            ? AppColors.success
                            : AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedType.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Type cannot be changed',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                // Show type selector for new categories
                Row(
                  children: CategoryType.values.map((type) {
                    final isSelected = _selectedType == type;
                    final color = type == CategoryType.income
                        ? AppColors.success
                        : AppColors.error;

                    return Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() => _selectedType = type);
                              },
                        child: Container(
                          margin: EdgeInsets.only(
                            right: type == CategoryType.income ? 8 : 0,
                            left: type == CategoryType.expense ? 8 : 0,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                type == CategoryType.income
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isSelected ? color : Colors.grey[600],
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? color : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Icon Selector
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isLoading ? null : _showIconPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: selectedColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _selectedIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Tap to select icon',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Color Selector
              Text(
                'Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isLoading ? null : _showColorPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Tap to select color',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Budget Section (only for expense categories)
              if (_selectedType == CategoryType.expense) ...[
                const Divider(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.lightPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Budget Limit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _enableBudget,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() => _enableBudget = value);
                            },
                      activeColor: AppColors.lightPrimary,
                    ),
                  ],
                ),
                if (_enableBudget) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _budgetAmountController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Budget Amount',
                      hintText: '5000',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.lightPrimary, width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: _enableBudget
                        ? (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter budget amount';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _budgetThresholdController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Alert Threshold (%)',
                      hintText: '80',
                      suffixText: '%',
                      helperText: 'Get warned when you reach this percentage',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.lightPrimary, width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: _enableBudget
                        ? (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter threshold';
                            }
                            final threshold = int.tryParse(value);
                            if (threshold == null ||
                                threshold < 0 ||
                                threshold > 100) {
                              return 'Threshold must be between 0-100';
                            }
                            return null;
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 24),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Category' : 'Create Category',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
