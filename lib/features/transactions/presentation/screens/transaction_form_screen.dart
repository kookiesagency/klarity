import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../providers/transaction_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../budgets/domain/models/budget_model.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction; // null for add, non-null for edit
  final String? transactionId; // Alternative: Load transaction by ID
  final TransactionType? initialType; // Set initial type when adding

  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.transactionId,
    this.initialType,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  AccountModel? _selectedAccount;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  TransactionModel? _loadedTransaction;
  BudgetWarning? _budgetWarning;

  @override
  void initState() {
    super.initState();

    // Set initial type if provided
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }

    // Add listener to amount field for budget check
    _amountController.addListener(() {
      _checkBudgetWarning();
    });

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile != null) {
        ref.read(accountProvider.notifier).loadAccounts(activeProfile.id);
        ref.read(categoryProvider.notifier).loadCategories(activeProfile.id);
      }

      // Load transaction by ID if provided
      if (widget.transactionId != null) {
        setState(() => _isLoading = true);
        // Find transaction from provider
        final transactions = ref.read(transactionsListProvider);
        _loadedTransaction = transactions.firstWhere(
          (t) => t.id == widget.transactionId,
          orElse: () => transactions.first,
        );
        _populateFields(_loadedTransaction);
        setState(() => _isLoading = false);
      }
      // If editing with transaction object, populate fields
      else if (widget.transaction != null) {
        _populateFields(widget.transaction!);
      }
    });
  }

  void _populateFields(TransactionModel? transaction) {
    if (transaction == null) return;
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description ?? '';
    _selectedType = transaction.type;
    _selectedDate = transaction.transactionDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.transaction != null || _loadedTransaction != null;

  TransactionModel? get currentTransaction => _loadedTransaction ?? widget.transaction;

  List<CategoryModel> get filteredCategories {
    final categoryState = ref.watch(categoryProvider);
    return _selectedType == TransactionType.income
        ? categoryState.incomeCategories
        : categoryState.expenseCategories;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.lightPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Check budget warning when amount/category changes
  Future<void> _checkBudgetWarning() async {
    // Only check for expenses, not income
    if (_selectedType != TransactionType.expense) {
      setState(() => _budgetWarning = null);
      return;
    }

    // Only check if category is selected and amount is entered
    if (_selectedCategory == null || _amountController.text.isEmpty) {
      setState(() => _budgetWarning = null);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _budgetWarning = null);
      return;
    }

    // Check budget warning
    final warning = await ref.read(budgetProvider.notifier).checkBudgetWarning(
          categoryId: _selectedCategory!.id,
          amount: amount,
        );

    setState(() => _budgetWarning = warning);
  }

  /// Show account bottom sheet
  Future<AccountModel?> _showAccountBottomSheet(List<AccountModel> accounts) async {
    return await showModalBottomSheet<AccountModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Select Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Account list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: accounts.map<Widget>((account) {
                        final isSelected = account.id == _selectedAccount?.id;
                        return ListTile(
                          leading: Icon(
                            account.type.icon,
                            color: account.type.color,
                          ),
                          title: Text(account.name),
                          subtitle: Text('₹${account.currentBalance.toStringAsFixed(2)}'),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context, account);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Show category bottom sheet
  Future<CategoryModel?> _showCategoryBottomSheet(List<CategoryModel> categories) async {
    return await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Select ${_selectedType.displayName} Category',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: categories.map<Widget>((category) {
                        final isSelected = category.id == _selectedCategory?.id;
                        return ListTile(
                          leading: Text(
                            category.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(category.name),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context, category);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccount == null) {
      context.showErrorSnackBar('Please select an account');
      return;
    }

    if (_selectedCategory == null) {
      context.showErrorSnackBar('Please select a category');
      return;
    }

    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    final result = isEditing
        ? await ref.read(transactionProvider.notifier).updateTransaction(
              transactionId: currentTransaction!.id,
              accountId: _selectedAccount!.id,
              categoryId: _selectedCategory!.id,
              type: _selectedType,
              amount: amount,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              transactionDate: _selectedDate,
            )
        : await ref.read(transactionProvider.notifier).createTransaction(
              accountId: _selectedAccount!.id,
              categoryId: _selectedCategory!.id,
              type: _selectedType,
              amount: amount,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              transactionDate: _selectedDate,
            );

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        context.showSuccessSnackBar(
          isEditing ? 'Transaction updated successfully' : 'Transaction added successfully',
        );
        Navigator.pop(context, true);
      },
      onFailure: (exception) {
        context.showErrorSnackBar(exception.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final accounts = accountState.accounts;

    // Set default account if not editing
    if (!isEditing && _selectedAccount == null && accounts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedAccount = accounts.first);
      });
    }

    // Set default category if available
    if (_selectedCategory == null && filteredCategories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedCategory = filteredCategories.first);
      });
    }

    return Scaffold(

      appBar: AppBar(
  
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: const TextStyle(
            color: AppColors.textPrimary,
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
              // Transaction Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedType = TransactionType.income;
                                  _selectedCategory = null; // Reset category
                                });
                                _checkBudgetWarning();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedType == TransactionType.income
                                ? AppColors.success
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: _selectedType == TransactionType.income
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Income',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedType == TransactionType.income
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedType = TransactionType.expense;
                                  _selectedCategory = null; // Reset category
                                });
                                _checkBudgetWarning();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedType == TransactionType.expense
                                ? AppColors.error
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: _selectedType == TransactionType.expense
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Expense',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedType == TransactionType.expense
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Amount Input
              const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
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
                  contentPadding: const EdgeInsets.all(20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Account Selection
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _isLoading
                    ? null
                    : () async {
                        final selected = await _showAccountBottomSheet(accounts);
                        if (selected != null) {
                          setState(() => _selectedAccount = selected);
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      if (_selectedAccount != null) ...[
                        Icon(
                          _selectedAccount!.type.icon,
                          color: _selectedAccount!.type.color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedAccount!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else
                        const Text(
                          'Select Account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Selection
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _isLoading
                    ? null
                    : () async {
                        final selected = await _showCategoryBottomSheet(filteredCategories);
                        if (selected != null) {
                          setState(() => _selectedCategory = selected);
                          _checkBudgetWarning();
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      if (_selectedCategory != null) ...[
                        Text(
                          _selectedCategory!.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedCategory!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else
                        const Text(
                          'Select Category',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Date Selection
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isLoading ? null : _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.lightPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description (Optional)
              const Text(
                'Description (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'e.g., Lunch at restaurant',
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
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // Budget Warning Card
              if (_budgetWarning != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _budgetWarning!.wouldExceedBudget
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _budgetWarning!.wouldExceedBudget
                          ? Colors.red
                          : Colors.orange,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _budgetWarning!.wouldExceedBudget
                                ? Icons.warning_rounded
                                : Icons.info_outline_rounded,
                            color: _budgetWarning!.wouldExceedBudget
                                ? Colors.red
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _budgetWarning!.wouldExceedBudget
                                  ? 'Budget Exceeded!'
                                  : 'Budget Warning',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _budgetWarning!.wouldExceedBudget
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _budgetWarning!.wouldExceedBudget
                            ? 'This transaction will exceed your budget by ₹${_budgetWarning!.exceedAmount.toStringAsFixed(0)}'
                            : 'You will reach ${_budgetWarning!.newPercentage.toStringAsFixed(0)}% of your budget',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Budget: ₹${_budgetWarning!.budget.amount.toStringAsFixed(0)} • Spent: ₹${_budgetWarning!.currentSpent.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType.color,
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
                          isEditing ? 'Update Transaction' : 'Add Transaction',
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
