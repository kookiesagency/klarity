import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_type.dart';

/// Optimized transaction card widget with const constructor
class TransactionCard extends ConsumerWidget {
  final TransactionModel transaction;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleSelection;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final timeFormat = DateFormat('h:mm a');

    final cardContent = Container(
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
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Selection checkbox
                    if (isSelectionMode)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onToggleSelection?.call(),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
    );

    // Wrap with Dismissible only if not in selection mode and not locked
    if (!isSelectionMode && !transaction.isLocked && onDelete != null) {
      return Dismissible(
        key: Key(transaction.id),
        direction: DismissDirection.endToStart,
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
          onDelete!();
          return false; // We handle deletion manually
        },
        child: cardContent,
      );
    }

    return cardContent;
  }
}
