import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/models/scheduled_payment_model.dart';
import '../../domain/models/scheduled_payment_status.dart';
import '../providers/scheduled_payment_provider.dart';
import 'scheduled_payment_form_screen.dart';

class ScheduledPaymentDetailScreen extends ConsumerStatefulWidget {
  final ScheduledPaymentModel payment;

  const ScheduledPaymentDetailScreen({super.key, required this.payment});

  @override
  ConsumerState<ScheduledPaymentDetailScreen> createState() =>
      _ScheduledPaymentDetailScreenState();
}

class _ScheduledPaymentDetailScreenState
    extends ConsumerState<ScheduledPaymentDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load payment history
    Future.microtask(() {
      ref
          .read(scheduledPaymentProvider.notifier)
          .loadPaymentHistory(widget.payment.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(scheduledPaymentProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Payment Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.payment.status != ScheduledPaymentStatus.completed)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editPayment(),
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deletePayment(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Payment Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    widget.payment.payeeName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: widget.payment.type.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                        widget.payment.status.colorCode.replaceFirst('#', '0xFF'),
                      )),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.payment.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Card(
            child: Column(
              children: [
                _buildDetailRow('Category', widget.payment.categoryName ?? 'Unknown'),
                _buildDetailRow('Account', widget.payment.accountName ?? 'Unknown'),
                _buildDetailRow('Due Date', dateFormat.format(widget.payment.dueDate)),
                if (widget.payment.reminderDate != null)
                  _buildDetailRow('Reminder',
                      dateFormat.format(widget.payment.reminderDate!)),
                if (widget.payment.description?.isNotEmpty ?? false)
                  _buildDetailRow('Description', widget.payment.description!),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Partial Payment Info
          if (widget.payment.allowPartialPayment) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: widget.payment.progressPercentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(widget.payment.type.color),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paid: ₹${widget.payment.paidAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Remaining: ₹${widget.payment.remainingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Payment History
          if (paymentState.paymentHistory.isNotEmpty) ...[
            const Text(
              'Payment History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...paymentState.paymentHistory.map((history) {
              return Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: widget.payment.type.color),
                  title: Text('₹${history.amount.toStringAsFixed(2)}'),
                  subtitle: Text(
                    '${dateFormat.format(history.paymentDate)} • ${history.paymentTypeDisplay}',
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
      bottomNavigationBar: widget.payment.status == ScheduledPaymentStatus.completed
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.payment.allowPartialPayment
                    ? ElevatedButton(
                        onPressed: () => _recordPartialPayment(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          'Record Payment',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _markAsComplete(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          'Mark as Paid',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _editPayment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduledPaymentFormScreen(payment: widget.payment),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _deletePayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this scheduled payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await ref
          .read(scheduledPaymentProvider.notifier)
          .deleteScheduledPayment(widget.payment.id);

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            context.showSuccessSnackBar('Payment deleted');
            Navigator.pop(context, true);
          },
          onFailure: (exception) {
            context.showErrorSnackBar(exception.message);
          },
        );
      }
    }
  }

  void _recordPartialPayment() async {
    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '₹',
            helperText: 'Remaining: ₹${widget.payment.remainingAmount.toStringAsFixed(2)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0 && mounted) {
      if (amount > widget.payment.remainingAmount) {
        context.showErrorSnackBar('Amount exceeds remaining balance');
        return;
      }

      final result = await ref.read(scheduledPaymentProvider.notifier).recordPayment(
            scheduledPaymentId: widget.payment.id,
            amount: amount,
          );

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            context.showSuccessSnackBar('Payment recorded');
            Navigator.pop(context, true);
          },
          onFailure: (exception) {
            context.showErrorSnackBar(exception.message);
          },
        );
      }
    }
  }

  void _markAsComplete() async {
    final result = await ref.read(scheduledPaymentProvider.notifier).recordPayment(
          scheduledPaymentId: widget.payment.id,
          amount: widget.payment.amount,
          notes: 'Marked as paid',
        );

    if (mounted) {
      result.fold(
        onSuccess: (_) {
          context.showSuccessSnackBar('Payment marked as complete');
          Navigator.pop(context, true);
        },
        onFailure: (exception) {
          context.showErrorSnackBar(exception.message);
        },
      );
    }
  }
}
