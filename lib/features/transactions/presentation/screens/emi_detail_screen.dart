import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/emi_model.dart';
import '../../domain/models/emi_payment_model.dart';
import '../providers/emi_provider.dart';
import 'emi_form_screen.dart';

/// EMI detail screen with payment history
class EmiDetailScreen extends ConsumerStatefulWidget {
  final String emiId;

  const EmiDetailScreen({
    super.key,
    required this.emiId,
  });

  @override
  ConsumerState<EmiDetailScreen> createState() => _EmiDetailScreenState();
}

class _EmiDetailScreenState extends ConsumerState<EmiDetailScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');

  EmiModel? _emi;
  List<EmiPaymentModel> _payments = [];
  bool _isLoadingPayments = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load EMI details
    final emisState = ref.read(emiProvider);
    _emi = emisState.emis.firstWhere(
      (e) => e.id == widget.emiId,
      orElse: () => emisState.emis.first,
    );

    // Load payment history
    await _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoadingPayments = true;
      _error = null;
    });

    final repository = ref.read(emiRepositoryProvider);
    final result = await repository.getEmiPayments(widget.emiId);

    result.fold(
      onSuccess: (payments) {
        setState(() {
          _payments = payments;
          _isLoadingPayments = false;
        });
      },
      onFailure: (exception) {
        setState(() {
          _error = exception.message;
          _isLoadingPayments = false;
        });
      },
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(emiProvider.notifier).refresh();
    await _loadData();
  }

  Future<void> _handleEdit() async {
    if (_emi == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EmiFormScreen(emi: _emi),
      ),
    );

    if (result == true && mounted) {
      await _handleRefresh();
    }
  }

  Future<void> _handleToggleActive() async {
    if (_emi == null) return;

    final newStatus = !_emi!.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Activate EMI?' : 'Deactivate EMI?'),
        content: Text(
          newStatus
              ? 'This will resume automatic payment processing for this EMI.'
              : 'This will stop automatic payment processing. You can reactivate it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref.read(emiProvider.notifier).toggleActiveStatus(
          emiId: _emi!.id,
          isActive: newStatus,
        );

    result.fold(
      onSuccess: (updatedEmi) {
        setState(() {
          _emi = updatedEmi;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus
                    ? 'EMI activated successfully'
                    : 'EMI deactivated successfully',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      onFailure: (exception) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(exception.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  Future<void> _handleDelete() async {
    if (_emi == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete EMI?'),
        content: const Text(
          'This will permanently delete this EMI and all its payment history. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref.read(emiProvider.notifier).deleteEmi(_emi!.id);

    result.fold(
      onSuccess: (_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('EMI deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      onFailure: (exception) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(exception.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    if (_emi == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('EMI Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMI Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _handleEdit,
            tooltip: 'Edit EMI',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'toggle_active':
                  _handleToggleActive();
                  break;
                case 'delete':
                  _handleDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_active',
                child: Row(
                  children: [
                    Icon(
                      _emi!.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(_emi!.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOverviewCard(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
              const SizedBox(height: 16),
              if (_emi!.notes != null && _emi!.notes!.isNotEmpty) ...[
                _buildNotesCard(),
                const SizedBox(height: 16),
              ],
              _buildPaymentHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final progressColor = _emi!.progressPercentage >= 75
        ? AppColors.success
        : _emi!.progressPercentage >= 50
            ? Colors.orange
            : AppColors.error;

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              const Color(0xFF7C3AED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _emi!.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _emi!.isActive
                        ? Colors.green.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _emi!.isActive ? Colors.greenAccent : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _emi!.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(fontSize: 12).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Total Amount',
                    _currencyFormat.format(_emi!.totalAmount),
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Monthly Payment',
                    _currencyFormat.format(_emi!.monthlyPayment),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Progress',
                    '${_emi!.paidInstallments}/${_emi!.totalInstallments}',
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Remaining',
                    _currencyFormat.format(_emi!.remainingAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_emi!.progressPercentage.toStringAsFixed(1)}% Complete',
                      style: const TextStyle(fontSize: 12).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_emi!.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'COMPLETED',
                          style: const TextStyle(fontSize: 12).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _emi!.progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
            if (!_emi!.isCompleted) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _emi!.isOverdue
                          ? Icons.error_outline
                          : Icons.schedule_outlined,
                      color: _emi!.isOverdue
                          ? Colors.redAccent
                          : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _emi!.isOverdue
                                ? 'Payment Overdue'
                                : 'Next Payment',
                            style: const TextStyle(fontSize: 12).copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateFormat.format(_emi!.nextPaymentDate),
                            style: const TextStyle(fontSize: 16).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12).copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMI Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Account',
              _emi!.accountName ?? 'Unknown',
              Icons.account_balance_wallet_outlined,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Category',
              _emi!.categoryName ?? 'Unknown',
              Icons.category_outlined,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Start Date',
              _dateFormat.format(_emi!.startDate),
              Icons.event_outlined,
            ),
            if (_emi!.description != null && _emi!.description!.isNotEmpty) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Description',
                _emi!.description!,
                Icons.description_outlined,
              ),
            ],
            const Divider(height: 24),
            _buildDetailRow(
              'Payment Day',
              'Day ${_emi!.paymentDayOfMonth} of every month',
              Icons.calendar_today_outlined,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Total Installments',
              _emi!.totalInstallments.toString(),
              Icons.format_list_numbered_outlined,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Remaining Installments',
              _emi!.remainingInstallments.toString(),
              Icons.pending_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16).copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _emi!.notes!,
              style: const TextStyle(fontSize: 16).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment History',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingPayments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16).copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _loadPayments,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_payments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No payments yet',
                        style: const TextStyle(fontSize: 16).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payments will appear here once processed',
                        style: const TextStyle(fontSize: 12).copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildPaymentList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    // Group payments by paid/unpaid
    final paidPayments = _payments.where((p) => p.isPaid).toList();
    final unpaidPayments = _payments.where((p) => !p.isPaid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (paidPayments.isNotEmpty) ...[
          Text(
            'Completed Payments (${paidPayments.length})',
            style: const TextStyle(fontSize: 16).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 12),
          ...paidPayments.map((payment) => _buildPaymentItem(payment, true)),
        ],
        if (paidPayments.isNotEmpty && unpaidPayments.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
        if (unpaidPayments.isNotEmpty) ...[
          Text(
            'Upcoming Payments (${unpaidPayments.length})',
            style: const TextStyle(fontSize: 16).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...unpaidPayments.map((payment) => _buildPaymentItem(payment, false)),
        ],
      ],
    );
  }

  Widget _buildPaymentItem(EmiPaymentModel payment, bool isPaid) {
    final isOverdue = payment.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.success.withOpacity(0.05)
            : isOverdue
                ? AppColors.error.withOpacity(0.05)
                : Colors.grey[50]!,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPaid
              ? AppColors.success.withOpacity(0.3)
              : isOverdue
                  ? AppColors.error.withOpacity(0.3)
                  : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withOpacity(0.2)
                  : isOverdue
                      ? AppColors.error.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isPaid
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    )
                  : Text(
                      '#${payment.installmentNumber}',
                      style: const TextStyle(fontSize: 12).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? AppColors.error : AppColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Installment ${payment.installmentNumber}',
                  style: const TextStyle(fontSize: 16).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? 'Paid on ${_dateFormat.format(payment.paymentDate)}'
                      : isOverdue
                          ? 'Overdue by ${payment.daysOverdue} days'
                          : 'Due on ${_dateFormat.format(payment.dueDate)}',
                  style: const TextStyle(fontSize: 12).copyWith(
                    color: isOverdue ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Payment type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: payment.notes!.contains('Manual')
                              ? Colors.blue.withOpacity(0.1)
                              : payment.notes!.contains('Auto-generated')
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: payment.notes!.contains('Manual')
                                ? Colors.blue.withOpacity(0.3)
                                : payment.notes!.contains('Auto-generated')
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              payment.notes!.contains('Manual')
                                  ? Icons.touch_app
                                  : payment.notes!.contains('Auto-generated')
                                      ? Icons.autorenew
                                      : Icons.history,
                              size: 10,
                              color: payment.notes!.contains('Manual')
                                  ? Colors.blue
                                  : payment.notes!.contains('Auto-generated')
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              payment.notes!.contains('Manual')
                                  ? 'Manual'
                                  : payment.notes!.contains('Auto-generated')
                                      ? 'Auto'
                                      : 'Historical',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: payment.notes!.contains('Manual')
                                    ? Colors.blue
                                    : payment.notes!.contains('Auto-generated')
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _currencyFormat.format(payment.amount),
            style: const TextStyle(fontSize: 16).copyWith(
              fontWeight: FontWeight.bold,
              color: isPaid ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
