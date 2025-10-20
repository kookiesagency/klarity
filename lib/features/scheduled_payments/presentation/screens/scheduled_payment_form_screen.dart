import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/domain/models/transaction_type.dart';
import '../../domain/models/scheduled_payment_model.dart';
import '../providers/scheduled_payment_provider.dart';

class ScheduledPaymentFormScreen extends ConsumerStatefulWidget {
  final ScheduledPaymentModel? payment;

  const ScheduledPaymentFormScreen({super.key, this.payment});

  @override
  ConsumerState<ScheduledPaymentFormScreen> createState() =>
      _ScheduledPaymentFormScreenState();
}

class _ScheduledPaymentFormScreenState
    extends ConsumerState<ScheduledPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _amountController;
  late TextEditingController _payeeController;
  late TextEditingController _descriptionController;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _reminderDate;
  bool _allowPartialPayment = false;
  bool _autoCreateTransaction = true;

  @override
  void initState() {
    super.initState();
    _type = widget.payment?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: widget.payment?.amount.toString() ?? '',
    );
    _payeeController = TextEditingController(
      text: widget.payment?.payeeName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.payment?.description ?? '',
    );
    _selectedAccountId = widget.payment?.accountId;
    _selectedCategoryId = widget.payment?.categoryId;
    if (widget.payment != null) {
      _dueDate = widget.payment!.dueDate;
      _reminderDate = widget.payment!.reminderDate;
      _allowPartialPayment = widget.payment!.allowPartialPayment;
      _autoCreateTransaction = widget.payment!.autoCreateTransaction;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      context.showErrorSnackBar('Please select an account');
      return;
    }

    if (_selectedCategoryId == null) {
      context.showErrorSnackBar('Please select a category');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      context.showErrorSnackBar('Please enter a valid amount');
      return;
    }

    final result = widget.payment == null
        ? await ref.read(scheduledPaymentProvider.notifier).createScheduledPayment(
              accountId: _selectedAccountId!,
              categoryId: _selectedCategoryId!,
              type: _type,
              amount: amount,
              payeeName: _payeeController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              dueDate: _dueDate,
              reminderDate: _reminderDate,
              allowPartialPayment: _allowPartialPayment,
              autoCreateTransaction: _autoCreateTransaction,
            )
        : await ref.read(scheduledPaymentProvider.notifier).updateScheduledPayment(
              paymentId: widget.payment!.id,
              accountId: _selectedAccountId,
              categoryId: _selectedCategoryId,
              type: _type,
              amount: amount,
              payeeName: _payeeController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              dueDate: _dueDate,
              reminderDate: _reminderDate,
              allowPartialPayment: _allowPartialPayment,
              autoCreateTransaction: _autoCreateTransaction,
            );

    if (mounted) {
      result.fold(
        onSuccess: (_) {
          context.showSuccessSnackBar(
            widget.payment == null
                ? 'Scheduled payment created'
                : 'Scheduled payment updated',
          );
          Navigator.pop(context, true);
        },
        onFailure: (exception) {
          context.showErrorSnackBar(exception.message);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accounts = ref.watch(accountsListProvider);
    final categories = _type == TransactionType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    return Scaffold(

      appBar: AppBar(
  
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.payment == null ? 'New Scheduled Payment' : 'Edit Payment',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // Amount
            Text(
              'Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixText: '₹ ',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payee name
            Text(
              'Payee / Receiver Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _payeeController,
              decoration: InputDecoration(
                hintText: 'Enter payee or receiver name',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error, width: 2),
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Account
            Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildAccountSelector(accounts),
            const SizedBox(height: 16),

            // Category
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildCategorySelector(categories),
            const SizedBox(height: 16),

            // Due date
            Text(
              'Due Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildDateSelector(),
            const SizedBox(height: 16),

            // Reminder date
            Text(
              'Reminder Date (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildReminderSelector(),
            const SizedBox(height: 16),

            // Description
            Text(
              'Description (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add notes or description',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Switches
            SwitchListTile(
              title: const Text('Allow Partial Payments'),
              subtitle: const Text('Enable paying in installments'),
              value: _allowPartialPayment,
              onChanged: (value) =>
                  setState(() => _allowPartialPayment = value),
            ),
            SwitchListTile(
              title: const Text('Auto-create Transaction'),
              subtitle: const Text('Automatically create on due date'),
              value: _autoCreateTransaction,
              onChanged: (value) =>
                  setState(() => _autoCreateTransaction = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _type = TransactionType.income),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == TransactionType.income
                      ? AppColors.success
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'Income',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _type == TransactionType.income
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _type = TransactionType.expense),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _type == TransactionType.expense
                      ? AppColors.error
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'Expense',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _type == TransactionType.expense
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSelector(List accounts) {
    return InkWell(
      onTap: () => _showAccountSelector(accounts),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedAccountId != null
                  ? accounts
                          .firstWhere((a) => a.id == _selectedAccountId)
                          .name
                  : 'Select account',
              style: TextStyle(
                fontSize: 16,
                color: _selectedAccountId != null
                    ? AppColors.textPrimary
                    : Colors.grey[600],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List categories) {
    return InkWell(
      onTap: () => _showCategorySelector(categories),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategoryId != null
                  ? categories
                          .firstWhere((c) => c.id == _selectedCategoryId)
                          .name
                  : 'Select category',
              style: TextStyle(
                fontSize: 16,
                color: _selectedCategoryId != null
                    ? AppColors.textPrimary
                    : Colors.grey[600],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dueDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (date != null) setState(() => _dueDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(_dueDate),
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSelector() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _reminderDate ?? _dueDate.subtract(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: _dueDate,
        );
        if (date != null) setState(() => _reminderDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _reminderDate != null
                  ? DateFormat('MMM dd, yyyy').format(_reminderDate!)
                  : 'No reminder',
              style: TextStyle(
                fontSize: 16,
                color: _reminderDate != null
                    ? AppColors.textPrimary
                    : Colors.grey[600],
              ),
            ),
            _reminderDate != null
                ? InkWell(
                    onTap: () => setState(() => _reminderDate = null),
                    child: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                  )
                : Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showAccountSelector(List accounts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
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
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final isSelected = account.id == _selectedAccountId;
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
                            setState(() => _selectedAccountId = account.id);
                            Navigator.pop(context);
                          },
                        );
                      },
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

  void _showCategorySelector(List categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
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
                      'Select Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = category.id == _selectedCategoryId;
                        return ListTile(
                          leading: Text(
                            category.icon ?? '📁',
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(category.name),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            setState(() => _selectedCategoryId = category.id);
                            Navigator.pop(context);
                          },
                        );
                      },
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
}
