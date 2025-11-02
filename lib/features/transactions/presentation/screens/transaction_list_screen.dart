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
import '../widgets/transaction_card.dart';
import 'transaction_form_screen.dart';
import 'transaction_detail_screen.dart';

/// Date range filter options for transactions
enum TransactionDateFilter {
  allTime,
  today,
  thisMonth,
  thisYear,
  lastYear,
}

extension TransactionDateFilterExtension on TransactionDateFilter {
  String get label {
    switch (this) {
      case TransactionDateFilter.allTime:
        return 'All Time';
      case TransactionDateFilter.today:
        return 'Today';
      case TransactionDateFilter.thisMonth:
        return 'This Month';
      case TransactionDateFilter.thisYear:
        return 'This Year';
      case TransactionDateFilter.lastYear:
        return 'Last Year';
    }
  }
}

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String? _filterAccountId;
  String? _filterCategoryId;
  TransactionType? _filterType;
  TransactionDateFilter _filterDateRange = TransactionDateFilter.allTime;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool _isSelectionMode = false;

  // Cache for grouped transactions to avoid recalculating on every rebuild
  List<TransactionModel>? _cachedTransactions;
  Map<String, List<TransactionModel>>? _cachedGroupedTransactions;
  List<String>? _cachedSortedDates;

  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Delay loading to avoid modifying provider during build
    Future.microtask(() => _loadData());

    // Add scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll events for infinite scroll
  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Load more when 200px from bottom

    if (maxScroll - currentScroll <= delta) {
      _loadMoreData();
    }
  }

  bool get _isLoadingMore {
    return ref.read(transactionProvider).isLoadingMore;
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
      // Use paginated loading for better performance
      await ref.read(transactionProvider.notifier).loadTransactionsPaginated(
        activeProfile.id,
        limit: 100,
      );
    }
  }

  Future<void> _loadMoreData() async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile != null) {
      await ref.read(transactionProvider.notifier).loadMoreTransactions(
        activeProfile.id,
        limit: 100,
      );
    }
  }

  /// Calculate date range based on selected filter
  void _applyDateRangeFilter(TransactionDateFilter filter) {
    final now = DateTime.now();

    switch (filter) {
      case TransactionDateFilter.allTime:
        _filterStartDate = null;
        _filterEndDate = null;
        break;

      case TransactionDateFilter.today:
        _filterStartDate = DateTime(now.year, now.month, now.day);
        _filterEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;

      case TransactionDateFilter.thisMonth:
        _filterStartDate = DateTime(now.year, now.month, 1);
        _filterEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;

      case TransactionDateFilter.thisYear:
        _filterStartDate = DateTime(now.year, 1, 1);
        _filterEndDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;

      case TransactionDateFilter.lastYear:
        _filterStartDate = DateTime(now.year - 1, 1, 1);
        _filterEndDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
    }

    _filterDateRange = filter;
  }

  Future<void> _showFilterDialog() async {
    // Store current filter values
    String? tempAccountId = _filterAccountId;
    String? tempCategoryId = _filterCategoryId;
    TransactionType? tempType = _filterType;
    TransactionDateFilter tempDateRange = _filterDateRange;

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
                              const SizedBox(height: 24),

                              // Date Range Filter
                              const Text(
                                'Date Range',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: TransactionDateFilter.values.map((filter) {
                                  final isSelected = tempDateRange == filter;
                                  return FilterChip(
                                    label: Text(filter.label),
                                    selected: isSelected,
                                    selectedColor: AppColors.primary.withOpacity(0.2),
                                    checkmarkColor: AppColors.primary,
                                    onSelected: (selected) {
                                      setBottomSheetState(() {
                                        tempDateRange = filter;
                                      });
                                    },
                                  );
                                }).toList(),
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
                                    _filterDateRange = TransactionDateFilter.allTime;
                                    _filterStartDate = null;
                                    _filterEndDate = null;
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
                                    _applyDateRangeFilter(tempDateRange);
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
        _filterDateRange != TransactionDateFilter.allTime;
  }

  Future<void> _showBulkActions() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                  _filterDateRange = TransactionDateFilter.allTime;
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
    // Use cached grouped transactions if the transaction list hasn't changed
    if (_cachedTransactions != transactions) {
      _cachedTransactions = transactions;

      // Group transactions by date
      final groupedTransactions = <String, List<TransactionModel>>{};
      for (final transaction in transactions) {
        final dateKey = DateFormat('yyyy-MM-dd').format(transaction.transactionDate);
        groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
      }

      _cachedGroupedTransactions = groupedTransactions;
      _cachedSortedDates = groupedTransactions.keys.toList()
        ..sort((a, b) => b.compareTo(a)); // Descending order
    }

    final transactionState = ref.watch(transactionProvider);
    final isLoadingMore = transactionState.isLoadingMore;
    final hasMore = transactionState.hasMore;

    // Check if we should show opening balance (only when filtering by specific account)
    final shouldShowOpeningBalance = _filterAccountId != null && transactions.isNotEmpty;

    // Calculate extra items: dates + loading/more indicator + opening balance (if applicable)
    final baseItemCount = _cachedSortedDates!.length;
    final loadingItemCount = (isLoadingMore || hasMore ? 1 : 0);
    final openingBalanceItemCount = (shouldShowOpeningBalance ? 1 : 0);
    final totalItemCount = baseItemCount + loadingItemCount + openingBalanceItemCount;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // Space for FAB
      ),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        // Transaction date groups
        if (index < baseItemCount) {
          final dateKey = _cachedSortedDates![index];
          final dateTransactions = _cachedGroupedTransactions![dateKey]!;
          final date = DateTime.parse(dateKey);
          return _buildDateGroup(date, dateTransactions);
        }

        // Opening balance (after all transactions, before loading indicator)
        if (shouldShowOpeningBalance && index == baseItemCount) {
          return _buildOpeningBalanceCard();
        }

        // Loading indicator at the very end
        if (isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (hasMore) {
          return const SizedBox(height: 50); // Spacer to trigger load
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOpeningBalanceCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accounts = ref.watch(accountsListProvider);

    // Get the filtered account
    final account = accounts.firstWhere(
      (a) => a.id == _filterAccountId,
      orElse: () => accounts.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header for opening balance
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(account.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Opening balance card (disabled style)
          Opacity(
            opacity: 0.6,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey[700]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_outlined,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Opening Balance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Text(
                    '₹${account.openingBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: account.openingBalance >= 0
                          ? (isDarkMode ? Colors.grey[400] : Colors.grey[700])
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(DateTime date, List<TransactionModel> transactions) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
    final transactionState = ref.watch(transactionProvider);
    final isSelected = transactionState.selectedTransactionIds.contains(transaction.id);

    return TransactionCard(
      transaction: transaction,
      isSelectionMode: _isSelectionMode,
      isSelected: isSelected,
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
      onDelete: () => _deleteTransaction(transaction),
      onToggleSelection: () => _toggleSelection(transaction.id),
    );
  }
}
