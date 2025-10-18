import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/emi_auto_payment_service.dart';

/// Screen for managing EMI auto-payment settings
class EmiAutoPaymentSettingsScreen extends ConsumerStatefulWidget {
  const EmiAutoPaymentSettingsScreen({super.key});

  @override
  ConsumerState<EmiAutoPaymentSettingsScreen> createState() =>
      _EmiAutoPaymentSettingsScreenState();
}

class _EmiAutoPaymentSettingsScreenState
    extends ConsumerState<EmiAutoPaymentSettingsScreen> {
  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  Duration _selectedInterval = const Duration(hours: 1);

  final List<Duration> _intervalOptions = [
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 3),
    const Duration(hours: 6),
    const Duration(hours: 12),
    const Duration(days: 1),
  ];

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  Future<void> _handleManualProcess() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Due Payments?'),
        content: const Text(
          'This will process all EMI payments that are due today. '
          'Transactions will be created and deducted from your accounts. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Process'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Process payments
    await ref.read(autoPaymentProvider.notifier).processNow();

    if (!mounted) return;

    final state = ref.read(autoPaymentProvider);

    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${state.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payments processed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _handleToggle(bool value) {
    if (value) {
      ref
          .read(autoPaymentProvider.notifier)
          .enable(interval: _selectedInterval);
    } else {
      ref.read(autoPaymentProvider.notifier).disable();
    }
  }

  void _handleIntervalChange(Duration? interval) {
    if (interval == null) return;

    setState(() {
      _selectedInterval = interval;
    });

    final state = ref.read(autoPaymentProvider);
    if (state.isEnabled) {
      ref.read(autoPaymentProvider.notifier).enable(interval: interval);
    }
  }

  /// Show interval bottom sheet
  Future<Duration?> _showIntervalBottomSheet() async {
    return await showModalBottomSheet<Duration>(
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
                      'Select Check Interval',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Interval list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: _intervalOptions.map<Widget>((interval) {
                        final isSelected = interval == _selectedInterval;
                        return ListTile(
                          leading: const Icon(
                            Icons.schedule,
                            color: AppColors.primary,
                          ),
                          title: Text(_formatDuration(interval)),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context, interval);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(autoPaymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Payment Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildStatusCard(state),
          const SizedBox(height: 16),
          _buildSettingsCard(state),
          const SizedBox(height: 16),
          _buildManualProcessCard(state),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 1,
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'About Auto-Payment',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Auto-payment automatically processes your EMI payments when they are due. '
              'The service checks for due payments at your configured interval and creates '
              'transactions automatically.',
              style: const TextStyle(fontSize: 16).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure you have sufficient balance in your accounts before enabling auto-payment.',
                      style: const TextStyle(fontSize: 12).copyWith(
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AutoPaymentState state) {
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
                  Icons.settings_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Service Status',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Payment',
                      style: const TextStyle(fontSize: 16).copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isEnabled ? 'Enabled' : 'Disabled',
                      style: const TextStyle(fontSize: 12).copyWith(
                        color: state.isEnabled
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: state.isEnabled,
                  onChanged: _handleToggle,
                  activeColor: AppColors.success,
                ),
              ],
            ),
            if (state.lastProcessedAt != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Processed',
                          style: const TextStyle(fontSize: 12).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateTimeFormat.format(state.lastProcessedAt!),
                          style: const TextStyle(fontSize: 16).copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (state.error != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(fontSize: 12).copyWith(
                          color: AppColors.error,
                        ),
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

  Widget _buildSettingsCard(AutoPaymentState state) {
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
                  Icons.tune_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Check Interval',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'How often should the system check for due payments?',
              style: const TextStyle(fontSize: 12).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: !state.isEnabled
                  ? null
                  : () async {
                      final selected = await _showIntervalBottomSheet();
                      if (selected != null) {
                        _handleIntervalChange(selected);
                      }
                    },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.isEnabled ? Colors.grey[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: state.isEnabled ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDuration(_selectedInterval),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: state.isEnabled ? AppColors.textPrimary : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: state.isEnabled ? Colors.grey : Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
            if (!state.isEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Enable auto-payment to change the interval',
                  style: const TextStyle(fontSize: 12).copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualProcessCard(AutoPaymentState state) {
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
                  Icons.play_circle_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Manual Processing',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Process all due EMI payments immediately',
              style: const TextStyle(fontSize: 12).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isProcessing ? null : _handleManualProcess,
                icon: state.isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  state.isProcessing ? 'Processing...' : 'Process Now',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
