import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/result.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../accounts/domain/models/account_model.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/domain/models/category_model.dart';
import '../../domain/models/transaction_type.dart';
import '../../domain/models/recurring_frequency.dart';
import '../../domain/models/recurring_transaction_model.dart';
import '../providers/recurring_transaction_provider.dart';

class RecurringTransactionFormScreen extends ConsumerStatefulWidget {
  final RecurringTransactionModel? recurringTransaction;
  final TransactionType? initialType;

  const RecurringTransactionFormScreen({
    super.key,
    this.recurringTransaction,
    this.initialType,
  });

  @override
  ConsumerState<RecurringTransactionFormScreen> createState() =>
      _RecurringTransactionFormScreenState();
}

class _RecurringTransactionFormScreenState
    extends ConsumerState<RecurringTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  AccountModel? _selectedAccount;
  CategoryModel? _selectedCategory;
  RecurringFrequency _selectedFrequency = RecurringFrequency.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DateTime _nextDueDate = DateTime.now();
  bool _hasEndDate = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Set initial type if provided
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }

    // Populate form if editing
    if (widget.recurringTransaction != null) {
      _populateFields(widget.recurringTransaction!);
    } else {
      _nextDueDate = _startDate;
    }

    // Load accounts and categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile != null) {
        ref.read(accountProvider.notifier).loadAccounts(activeProfile.id);
        ref.read(categoryProvider.notifier).loadCategories(activeProfile.id);
      }
    });
  }

  void _populateFields(RecurringTransactionModel recurringTransaction) {
    _selectedType = recurringTransaction.type;
    _amountController.text = recurringTransaction.amount.toStringAsFixed(2);
    _descriptionController.text = recurringTransaction.description ?? '';
    _selectedFrequency = recurringTransaction.frequency;
    _startDate = recurringTransaction.startDate;
    _endDate = recurringTransaction.endDate;
    _nextDueDate = recurringTransaction.nextDueDate;
    _hasEndDate = _endDate != null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
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

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Update next due date if it's before start date
        if (_nextDueDate.isBefore(_startDate)) {
          _nextDueDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
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

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _pickNextDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: _startDate,
      lastDate: _endDate ?? DateTime(2100),
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

    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }

  void _calculateNextDueDate() {
    setState(() {
      _nextDueDate = _selectedFrequency.calculateNextDueDate(_startDate);
    });
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

  /// Show frequency bottom sheet
  Future<RecurringFrequency?> _showFrequencyBottomSheet() async {
    return await showModalBottomSheet<RecurringFrequency>(
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
                      'Select Frequency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Frequency list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: RecurringFrequency.values.map<Widget>((frequency) {
                        final isSelected = frequency == _selectedFrequency;
                        return ListTile(
                          title: Text(frequency.label),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context, frequency);
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccount == null) {
      context.showErrorSnackBar('Please select an account');
      return;
    }

    if (_selectedCategory == null) {
      context.showErrorSnackBar('Please select a category');
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    setState(() => _isLoading = true);

    Result result;

    if (widget.recurringTransaction != null) {
      // Update existing recurring transaction
      result = await ref.read(recurringTransactionProvider.notifier).updateRecurringTransaction(
            recurringTransactionId: widget.recurringTransaction!.id,
            accountId: _selectedAccount!.id,
            categoryId: _selectedCategory!.id,
            type: _selectedType,
            amount: amount,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            frequency: _selectedFrequency,
            startDate: _startDate,
            endDate: _hasEndDate ? _endDate : null,
            nextDueDate: _nextDueDate,
          );
    } else {
      // Create new recurring transaction
      result = await ref.read(recurringTransactionProvider.notifier).createRecurringTransaction(
            accountId: _selectedAccount!.id,
            categoryId: _selectedCategory!.id,
            type: _selectedType,
            amount: amount,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            frequency: _selectedFrequency,
            startDate: _startDate,
            endDate: _hasEndDate ? _endDate : null,
            nextDueDate: _nextDueDate,
          );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        context.showSuccessSnackBar(
          widget.recurringTransaction != null
              ? 'Recurring transaction updated successfully'
              : 'Recurring transaction created successfully',
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
    final categoryState = ref.watch(categoryProvider);

    final accounts = accountState.accounts;
    final categories = _selectedType == TransactionType.income
        ? categoryState.incomeCategories
        : categoryState.expenseCategories;

    // Set default account and category if not set
    if (_selectedAccount == null && accounts.isNotEmpty && widget.recurringTransaction == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedAccount = accounts.first);
      });
    }

    if (_selectedCategory == null && categories.isNotEmpty && widget.recurringTransaction == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedCategory = categories.first);
      });
    }

    // Find matching account and category when editing
    if (widget.recurringTransaction != null && _selectedAccount == null && accounts.isNotEmpty) {
      _selectedAccount = accounts.firstWhere(
        (a) => a.id == widget.recurringTransaction!.accountId,
        orElse: () => accounts.first,
      );
    }

    if (widget.recurringTransaction != null && _selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.firstWhere(
        (c) => c.id == widget.recurringTransaction!.categoryId,
        orElse: () => categories.first,
      );
    }

    return Scaffold(

      appBar: AppBar(
  
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.recurringTransaction != null
              ? 'Edit Recurring Transaction'
              : 'New Recurring Transaction',
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
              // Type Selector
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
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == TransactionType.income
                                ? AppColors.success
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Income',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedType == TransactionType.income
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
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
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == TransactionType.expense
                                ? AppColors.error
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Expense',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedType == TransactionType.expense
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
                          'Select account',
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
                        final selected = await _showCategoryBottomSheet(categories);
                        if (selected != null) {
                          setState(() => _selectedCategory = selected);
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
                          'Select category',
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

              // Frequency Selection
              const Text(
                'Frequency',
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
                        final selected = await _showFrequencyBottomSheet();
                        if (selected != null) {
                          setState(() {
                            _selectedFrequency = selected;
                            _calculateNextDueDate();
                          });
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
                      Text(
                        _selectedFrequency.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Start Date
              const Text(
                'Start Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isLoading ? null : _pickStartDate,
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
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_startDate),
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

              // End Date (Optional)
              Row(
                children: [
                  const Text(
                    'End Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _hasEndDate,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _hasEndDate = value;
                              if (!value) {
                                _endDate = null;
                              }
                            });
                          },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              if (_hasEndDate) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _pickEndDate,
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
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _endDate != null
                              ? DateFormat('MMM dd, yyyy').format(_endDate!)
                              : 'Select end date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _endDate != null
                                ? AppColors.textPrimary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Next Due Date
              const Text(
                'Next Due Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isLoading ? null : _pickNextDueDate,
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
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_nextDueDate),
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
                  hintText: 'e.g., Netflix subscription',
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                          widget.recurringTransaction != null
                              ? 'Update Recurring Transaction'
                              : 'Create Recurring Transaction',
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
