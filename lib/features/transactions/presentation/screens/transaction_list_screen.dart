import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';
import '../providers/transaction_provider.dart';
import 'transaction_form_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String? _filterAccountId;
  String? _filterCategoryId;
  TransactionType? _filterType;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Delay loading to avoid modifying provider during build
    Future.microtask(() => _loadData());
  }

  void _enterSelectionMode() {
    setState(() => _isSelectionMode = true);
  }

  void _exitSelectionMode() {
    ref.read(transactionProvider.notifier).clearSelection();
    setState(() => _isSelectionMode = false);
  }

  void _toggleSelection(String transactionId) {
    ref.read(transactionProvider.notifier).toggleTransactionSelection(transactionId);
  }

  void _selectAll(List<TransactionModel> transactions) {
    ref.read(transactionProvider.notifier).selectAllTransactions();
  }

  Future<void> _loadData() async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile != null) {
      await ref.read(transactionProvider.notifier).loadTransactions(activeProfile.id);
    }
  }

  Future<void> _showFilterDialog() async {
    // Store current filter values
    String? tempAccountId = _filterAccountId;
    String? tempCategoryId = _filterCategoryId;
    TransactionType? tempType = _filterType;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setBottomSheetState) {
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
                          'Filter Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Transaction Type Filter
                              const Text(
                                'Transaction Type',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilterChip(
                                    label: const Text('All'),
                                    selected: tempType == null,
                                    onSelected: (selected) {
                                      setBottomSheetState(() {
                                        tempType = null;
                                      });
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Income'),
                                    selected: tempType == TransactionType.income,
                                    selectedColor: AppColors.success.withOpacity(0.3),
                                    onSelected: (selected) {
                                      setBottomSheetState(() {
                                        tempType = selected ? TransactionType.income : null;
                                      });
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Expense'),
                                    selected: tempType == TransactionType.expense,
                                    selectedColor: AppColors.error.withOpacity(0.3),
                                    onSelected: (selected) {
                                      setBottomSheetState(() {
                                        tempType = selected ? TransactionType.expense : null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Account Filter
                              const Text(
                                'Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Consumer(
                                builder: (context, ref, child) {
                                  final accounts = ref.watch(accountsListProvider);
                                  final selectedAccount = tempAccountId != null
                                      ? accounts.firstWhere(
                                          (a) => a.id == tempAccountId,
                                          orElse: () => accounts.first,
                                        )
                                      : null;

                                  return InkWell(
                                    onTap: () async {
                                      final selected = await _showAccountBottomSheet(context, accounts, tempAccountId);
                                      if (selected != null) {
                                        setBottomSheetState(() {
                                          tempAccountId = selected;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          if (selectedAccount != null) ...[
                                            Icon(selectedAccount.type.icon, size: 20),
                                            const SizedBox(width: 12),
                                            Text(
                                              selectedAccount.name,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ] else
                                            const Text(
                                              'All Accounts',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Category Filter
                              const Text(
                                'Category',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Consumer(
                                builder: (context, ref, child) {
                                  final categories = ref.watch(categoriesListProvider);
                                  final selectedCategory = tempCategoryId != null
                                      ? categories.firstWhere(
                                          (c) => c.id == tempCategoryId,
                                          orElse: () => categories.first,
                                        )
                                      : null;

                                  return InkWell(
                                    onTap: () async {
                                      final selected = await _showCategoryBottomSheet(context, categories, tempCategoryId);
                                      if (selected != null) {
                                        setBottomSheetState(() {
                                          tempCategoryId = selected;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          if (selectedCategory != null) ...[
                                            Text(
                                              selectedCategory.icon,
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              selectedCategory.name,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ] else
                                            const Text(
                                              'All Categories',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      // Action buttons
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Cancel button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Clear All button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _filterAccountId = null;
                                    _filterCategoryId = null;
                                    _filterType = null;
                                  });
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Clear All'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Apply button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _filterAccountId = tempAccountId;
                                    _filterCategoryId = tempCategoryId;
                                    _filterType = tempType;
                                  });
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Show account bottom sheet
  Future<String?> _showAccountBottomSheet(
    BuildContext context,
    List<dynamic> accounts,
    String? currentAccountId,
  ) async {
    return await showModalBottomSheet<String?>(
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
                      children: [
                        // All Accounts option
                        ListTile(
                          leading: const Icon(Icons.all_inclusive),
                          title: const Text('All Accounts'),
                          trailing: currentAccountId == null
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context, '__clear__'); // Special value to clear selection
                          },
                        ),
                        const Divider(),
                        // Individual accounts
                        ...accounts.map<Widget>((account) {
                          final isSelected = account.id == currentAccountId;
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
                              Navigator.pop(context, account.id);
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((value) {
      // Convert special value to null
      if (value == '__clear__') return null;
      return value;
    });
  }

  /// Show category bottom sheet
  Future<String?> _showCategoryBottomSheet(
    BuildContext context,
    List<dynamic> categories,
    String? currentCategoryId,
  ) async {
    return await showModalBottomSheet<String?>(
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
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // All Categories option
                        ListTile(
                          leading: const Icon(Icons.all_inclusive),
                          title: const Text('All Categories'),
                          trailing: currentCategoryId == null
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context, '__clear__'); // Special value to clear selection
                          },
                        ),
                        const Divider(),
                        // Individual categories
                        ...categories.map<Widget>((category) {
                          final isSelected = category.id == currentCategoryId;
                          return ListTile(
                            leading: Text(
                              category.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(category.name),
                            subtitle: Text(category.type.displayName),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: AppColors.primary)
                                : null,
                            onTap: () {
                              Navigator.pop(context, category.id);
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((value) {
      // Convert special value to null
      if (value == '__clear__') return null;
      return value;
    });
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    return transactions.where((transaction) {
      // Filter by type
      if (_filterType != null && transaction.type != _filterType) {
        return false;
      }

      // Filter by account
      if (_filterAccountId != null && transaction.accountId != _filterAccountId) {
        return false;
      }

      // Filter by category
      if (_filterCategoryId != null && transaction.categoryId != _filterCategoryId) {
        return false;
      }

      // Filter by date range
      if (_filterStartDate != null && transaction.transactionDate.isBefore(_filterStartDate!)) {
        return false;
      }
      if (_filterEndDate != null && transaction.transactionDate.isAfter(_filterEndDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters {
    return _filterType != null ||
        _filterAccountId != null ||
        _filterCategoryId != null ||
        _filterStartDate != null ||
        _filterEndDate != null;
  }

  Future<void> _showBulkActions() async {
    final selectedCount = ref.read(transactionProvider).selectedTransactionIds.length;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$selectedCount ${selectedCount == 1 ? 'transaction' : 'transactions'} selected',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _bulkDelete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: AppColors.primary),
              title: const Text('Change Category'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateCategory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
              title: const Text('Change Account'),
              onTap: () {
                Navigator.pop(context);
                _bulkUpdateAccount();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkDelete() async {
    final selectedCount = ref.read(transactionProvider).selectedTransactionIds.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transactions'),
          content: Text(
            'Are you sure you want to delete $selectedCount ${selectedCount == 1 ? 'transaction' : 'transactions'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final result = await ref.read(transactionProvider.notifier).bulkDeleteTransactions();

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$selectedCount ${selectedCount == 1 ? 'transaction' : 'transactions'} deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            _exitSelectionMode();
          },
          onFailure: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.message),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _bulkUpdateCategory() async {
    final categories = ref.read(categoriesListProvider);

    final selectedCategory = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: categories.map((category) {
                return ListTile(
                  leading: Text(category.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(category.name),
                  subtitle: Text(category.type.name),
                  onTap: () => Navigator.pop(context, category.id),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedCategory != null) {
      final result = await ref.read(transactionProvider.notifier).bulkUpdateCategory(selectedCategory);

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Category updated successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            _exitSelectionMode();
          },
          onFailure: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.message),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _bulkUpdateAccount() async {
    final accounts = ref.read(accountsListProvider);

    final selectedAccount = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: accounts.map((account) {
                return ListTile(
                  leading: Icon(account.type.icon, color: account.type.color),
                  title: Text(account.name),
                  subtitle: Text('₹${account.currentBalance.toStringAsFixed(2)}'),
                  onTap: () => Navigator.pop(context, account.id),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedAccount != null) {
      final result = await ref.read(transactionProvider.notifier).bulkUpdateAccount(selectedAccount);

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account updated successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            _exitSelectionMode();
          },
          onFailure: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.message),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    // Check if transaction is locked
    if (transaction.isLocked) {
      final shouldUnlock = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock, color: Colors.orange),
                SizedBox(width: 8),
                Text('Transaction Locked'),
              ],
            ),
            content: const Text(
              'This transaction is locked because it\'s older than 2 months. '
              'Do you want to unlock it to delete?',
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
                child: const Text('Unlock & Delete'),
              ),
            ],
          );
        },
      );

      if (shouldUnlock != true) return;

      // Unlock the transaction first
      final unlockResult = await ref
          .read(transactionProvider.notifier)
          .unlockTransaction(transaction.id);

      if (!mounted) return;

      unlockResult.fold(
        onSuccess: (_) {
          // Transaction unlocked, proceed to delete
          _performDelete(transaction);
        },
        onFailure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unlock: ${error.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    } else {
      // Not locked, proceed normally
      _performDelete(transaction);
    }
  }

  Future<void> _performDelete(TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete this ${transaction.type.displayName.toLowerCase()}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final result = await ref
          .read(transactionProvider.notifier)
          .deleteTransaction(transaction.id);

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          onFailure: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.message),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final allTransactions = transactionState.transactions;
    final filteredTransactions = _getFilteredTransactions(allTransactions);
    final isLoading = transactionState.isLoading;
    final selectedIds = transactionState.selectedTransactionIds;
    final selectedCount = selectedIds.length;

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(_isSelectionMode ? '$selectedCount selected' : 'Transactions'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () => _selectAll(filteredTransactions),
                  tooltip: 'Select All',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: selectedCount > 0 ? _showBulkActions : null,
                  tooltip: 'Actions',
                ),
              ]
            : [
                // Filter button with indicator
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredTransactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionList(filteredTransactions),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasActiveFilters ? Icons.filter_list_off : Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters
                ? 'No transactions found'
                : 'No transactions yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Start adding your income and expenses',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _filterAccountId = null;
                  _filterCategoryId = null;
                  _filterType = null;
                  _filterStartDate = null;
                  _filterEndDate = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions) {
    // Group transactions by date
    final groupedTransactions = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.transactionDate);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // Space for FAB
      ),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dateTransactions = groupedTransactions[dateKey]!;
        final date = DateTime.parse(dateKey);

        return _buildDateGroup(date, dateTransactions);
      },
    );
  }

  Widget _buildDateGroup(DateTime date, List<TransactionModel> transactions) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isYesterday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = dateFormat.format(date);
    }

    // Calculate total for the day
    double dayIncome = 0;
    double dayExpense = 0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        dayIncome += transaction.amount;
      } else {
        dayExpense += transaction.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (dayIncome > 0)
                Text(
                  '+₹${dayIncome.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              if (dayIncome > 0 && dayExpense > 0)
                const SizedBox(width: 8),
              if (dayExpense > 0)
                Text(
                  '-₹${dayExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        ),
        // Transactions for this date
        ...transactions.map((transaction) => _buildTransactionCard(transaction)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final timeFormat = DateFormat('h:mm a');
    final transactionState = ref.watch(transactionProvider);
    final isSelected = transactionState.selectedTransactionIds.contains(transaction.id);

    return Dismissible(
      key: Key(transaction.id),
      direction: (_isSelectionMode || transaction.isLocked)
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        await _deleteTransaction(transaction);
        return false; // We handle deletion manually
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isSelectionMode
                ? () => _toggleSelection(transaction.id)
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(
                          transaction: transaction,
                        ),
                      ),
                    );
                  },
            onLongPress: transaction.isLocked
                ? null
                : () {
                    if (!_isSelectionMode) {
                      _enterSelectionMode();
                      _toggleSelection(transaction.id);
                    }
                  },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                  // Selection checkbox
                  if (_isSelectionMode)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(transaction.id),
                        shape: const CircleBorder(),
                      ),
                    ),
                  // Category icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        transaction.categoryIcon ?? '📝',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.categoryName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                transaction.accountName ?? 'Unknown Account',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (transaction.description != null) ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              Flexible(
                                child: Text(
                                  transaction.description!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeFormat.format(transaction.transactionDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Amount
                  Text(
                    '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                    ],
                  ),
                ),
                // Lock icon in top right corner
                if (transaction.isLocked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
