import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/scheduled_payment_model.dart';
import '../providers/scheduled_payment_provider.dart';
import 'scheduled_payment_form_screen.dart';
import 'scheduled_payment_detail_screen.dart';

class ScheduledPaymentsListScreen extends ConsumerStatefulWidget {
  const ScheduledPaymentsListScreen({super.key});

  @override
  ConsumerState<ScheduledPaymentsListScreen> createState() =>
      _ScheduledPaymentsListScreenState();
}

class _ScheduledPaymentsListScreenState
    extends ConsumerState<ScheduledPaymentsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(scheduledPaymentProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Scheduled Payments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Partial'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: paymentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsList(paymentState.pendingPayments),
                _buildPaymentsList(paymentState.partialPayments),
                _buildPaymentsList(paymentState.completedPayments),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentsList(List<ScheduledPaymentModel> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No scheduled payments',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(ScheduledPaymentModel payment) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: payment.type.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        payment.categoryIcon ?? '📁',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Left side - Payment details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payee name
                        Text(
                          payment.payeeName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 3),

                        // Category name
                        Text(
                          payment.categoryName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right side - IN/OUT and Amount (stacked)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // IN/OUT badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: payment.type.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              payment.type.name == 'income'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              payment.type.name == 'income' ? 'IN' : 'OUT',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Amount
                      Text(
                        '₹${payment.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: payment.type.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Due date and status at bottom
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date on the left
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: payment.isOverdue ? AppColors.error : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(payment.dueDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: payment.isOverdue ? AppColors.error : Colors.grey[600],
                          fontWeight: payment.isOverdue ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Status badge on the right
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                        payment.status.colorCode.replaceFirst('#', '0xFF'),
                      )),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payment.status.displayName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              // Progress bar for partial payments - full width at bottom
              if (payment.allowPartialPayment) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: payment.progressPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(payment.type.color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${payment.paidAmount.toStringAsFixed(0)} / ₹${payment.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToForm([ScheduledPaymentModel? payment]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduledPaymentFormScreen(payment: payment),
      ),
    );

    if (result == true && mounted) {
      ref.read(scheduledPaymentProvider.notifier).refresh();
    }
  }

  void _navigateToDetail(ScheduledPaymentModel payment) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduledPaymentDetailScreen(payment: payment),
      ),
    );

    if (result == true && mounted) {
      ref.read(scheduledPaymentProvider.notifier).refresh();
    }
  }
}
