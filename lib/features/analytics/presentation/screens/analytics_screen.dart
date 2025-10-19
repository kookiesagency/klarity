import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/analytics_provider.dart';
import '../../domain/models/analytics_summary.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../budgets/domain/models/budget_model.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/screens/category_detail_screen.dart';

enum DateRangeType {
  today,
  week,
  month,
  year,
  custom;

  String get label {
    return switch (this) {
      DateRangeType.today => 'Today',
      DateRangeType.week => 'This Week',
      DateRangeType.month => 'This Month',
      DateRangeType.year => 'This Year',
      DateRangeType.custom => 'Custom',
    };
  }
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRangeType _selectedRange = DateRangeType.month;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

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

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();

    return switch (_selectedRange) {
      DateRangeType.today => (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        ),
      DateRangeType.week => (
          DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)),
          DateTime(now.year, now.month, now.day).add(Duration(days: 7 - now.weekday, hours: 23, minutes: 59, seconds: 59)),
        ),
      DateRangeType.month => (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        ),
      DateRangeType.year => (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        ),
      DateRangeType.custom => _customStartDate != null && _customEndDate != null
          ? (_customStartDate!, _customEndDate!)
          : (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0, 23, 59, 59)),
    };
  }

  (DateTime, DateTime) _getPreviousPeriodDateRange() {
    final (currentStart, currentEnd) = _getDateRange();
    final periodDuration = currentEnd.difference(currentStart);

    return switch (_selectedRange) {
      DateRangeType.today => (
          currentStart.subtract(const Duration(days: 1)),
          currentEnd.subtract(const Duration(days: 1)),
        ),
      DateRangeType.week => (
          currentStart.subtract(const Duration(days: 7)),
          currentEnd.subtract(const Duration(days: 7)),
        ),
      DateRangeType.month => (
          DateTime(currentStart.year, currentStart.month - 1, 1),
          DateTime(currentStart.year, currentStart.month, 0, 23, 59, 59),
        ),
      DateRangeType.year => (
          DateTime(currentStart.year - 1, 1, 1),
          DateTime(currentStart.year - 1, 12, 31, 23, 59, 59),
        ),
      DateRangeType.custom => (
          currentStart.subtract(periodDuration + const Duration(days: 1)),
          currentStart.subtract(const Duration(days: 1)),
        ),
    };
  }

  String _getDateRangeLabel() {
    final (start, end) = _getDateRange();
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (_selectedRange == DateRangeType.custom) {
      return '${dateFormat.format(start)} - ${dateFormat.format(end)}';
    }

    return _selectedRange.label;
  }

  Future<void> _showDateRangePicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Select Date Range',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Date range options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: DateRangeType.values.map((range) {
                    final isSelected = _selectedRange == range;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppColors.primary : Colors.grey,
                      ),
                      title: Text(
                        range.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      onTap: () async {
                        if (range == DateRangeType.custom) {
                          Navigator.pop(context);
                          // Show date range picker dialog
                          final dateRange = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );

                          if (dateRange != null) {
                            setState(() {
                              _selectedRange = DateRangeType.custom;
                              _customStartDate = dateRange.start;
                              _customEndDate = dateRange.end;
                            });
                          }
                        } else {
                          setState(() {
                            _selectedRange = range;
                          });
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            // Title
            const Text(
              'Analytics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // Filter label
            Text(
              _getDateRangeLabel(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Filter icon button
          IconButton(
            onPressed: _showDateRangePicker,
            icon: const Icon(
              Icons.filter_list_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            tooltip: 'Filter date range',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Budgets'),
          ],
        ),
      ),
      body: activeProfile == null
          ? const Center(
              child: Text('No active profile selected'),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoriesTab(),
                _buildBudgetsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const Center(child: Text('No active profile selected'));
    }

    final (startDate, endDate) = _getDateRange();
    final params = AnalyticsParams(
      profileId: activeProfile.id,
      startDate: startDate,
      endDate: endDate,
    );

    final analyticsAsync = ref.watch(analyticsSummaryProvider(params));

    return analyticsAsync.when(
      data: (summary) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Income and Expenses Cards - Financial Summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Income',
                    amount: NumberFormat.currency(symbol: '₹').format(summary.totalIncome),
                    icon: Icons.arrow_downward,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Expenses',
                    amount: NumberFormat.currency(symbol: '₹').format(summary.totalExpense),
                    icon: Icons.arrow_upward,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Net Savings Card
            _buildNetSavingsCard(summary),
            const SizedBox(height: 12),

            // Savings Rate
            _buildSavingsRate(summary),
            const SizedBox(height: 12),

            // Financial Health Score
            _buildFinancialHealthScore(summary),
            const SizedBox(height: 20),

            // Spending Analysis Section
            _buildSectionHeader('Spending Analysis'),
            const SizedBox(height: 12),

            // Daily Average
            _buildAverageDailySpending(summary),
            const SizedBox(height: 12),

            // Largest Expense
            _buildLargestExpense(summary),
            const SizedBox(height: 20),

            // Period Comparison - Trend Analysis
            _buildSectionHeader('Trend Analysis'),
            const SizedBox(height: 12),

            // Period Comparison
            _buildPeriodComparison(),
            const SizedBox(height: 20),

            // Activity Section
            _buildSectionHeader('Activity'),
            const SizedBox(height: 12),

            // Transaction Count
            _buildTransactionCount(summary),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading analytics',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Breakdown Chart
          _buildSectionHeader('Category Breakdown'),
          const SizedBox(height: 16),
          _buildCategoryPieChart(),
          const SizedBox(height: 24),

          // Top Categories List
          _buildSectionHeader('Top Categories'),
          const SizedBox(height: 16),
          _buildTopCategoriesList(),
        ],
      ),
    );
  }

  Widget _buildBudgetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Budget Overview'),
          const SizedBox(height: 16),
          _buildBudgetOverview(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSummaryCards() {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }

    final (startDate, endDate) = _getDateRange();
    final params = AnalyticsParams(
      profileId: activeProfile.id,
      startDate: startDate,
      endDate: endDate,
    );

    final analyticsAsync = ref.watch(analyticsSummaryProvider(params));

    return analyticsAsync.when(
      data: (summary) => Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Income',
              amount: NumberFormat.currency(symbol: '₹').format(summary.totalIncome),
              icon: Icons.arrow_downward,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Expenses',
              amount: NumberFormat.currency(symbol: '₹').format(summary.totalExpense),
              icon: Icons.arrow_upward,
              color: AppColors.error,
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(child: _buildLoadingCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildLoadingCard()),
        ],
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading data',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTrendChart() {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }

    final (startDate, endDate) = _getDateRange();
    final params = AnalyticsParams(
      profileId: activeProfile.id,
      startDate: startDate,
      endDate: endDate,
    );

    final analyticsAsync = ref.watch(analyticsSummaryProvider(params));

    return analyticsAsync.when(
      data: (summary) {
        if (summary.dailyBalances.isEmpty) {
          return Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'No data available for this period',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        // Convert daily balances to chart data
        final sortedEntries = summary.dailyBalances.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        final spots = <FlSpot>[];
        for (var i = 0; i < sortedEntries.length; i++) {
          spots.add(FlSpot(i.toDouble(), sortedEntries[i].value));
        }

        final minY = sortedEntries.map((e) => e.value).reduce((a, b) => a < b ? a : b);
        final maxY = sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
        final range = maxY - minY;
        final padding = range * 0.1;

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: range > 0 ? range / 4 : 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (sortedEntries.length / 5).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sortedEntries.length) {
                        return const Text('');
                      }
                      final date = DateTime.parse(sortedEntries[index].key);
                      return Text(
                        DateFormat('MMM d').format(date),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: range > 0 ? range / 4 : 1,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: minY - padding,
              maxY: maxY + padding,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: spots.length < 15,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Error loading chart data',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingOverview() {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }

    final (startDate, endDate) = _getDateRange();
    final params = AnalyticsParams(
      profileId: activeProfile.id,
      startDate: startDate,
      endDate: endDate,
    );

    final topCategoriesAsync = ref.watch(topCategoriesProvider(params));

    return topCategoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'No expense data available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final topCategories = categories.take(5).toList();
        final maxAmount = topCategories.map((c) => c.amount).reduce((a, b) => a > b ? a : b);

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= topCategories.length) {
                        return const Text('');
                      }
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            topCategories[index].categoryIcon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topCategories[index].categoryName.length > 8
                                ? '${topCategories[index].categoryName.substring(0, 8)}...'
                                : topCategories[index].categoryName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxAmount / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: topCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: category.amount,
                      color: AppColors.primary,
                      width: 30,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Error loading chart',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }

    final (startDate, endDate) = _getDateRange();
    final params = AnalyticsParams(
      profileId: activeProfile.id,
      startDate: startDate,
      endDate: endDate,
    );

    final topCategoriesAsync = ref.watch(topCategoriesProvider(params));

    return topCategoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'No expense data available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final totalExpense = categories.fold(0.0, (sum, cat) => sum + cat.amount);

        // Generate colors for categories
        final colors = [
          AppColors.primary,
          AppColors.success,
          AppColors.error,
          Colors.orange,
          Colors.purple,
          Colors.grey, // For "Others"
        ];

        // Top 5 categories + Others
        final top5 = categories.take(5).toList();
        final othersAmount = categories.skip(5).fold(0.0, (sum, cat) => sum + cat.amount);

        final sections = <PieChartSectionData>[];

        // Add top 5 categories
        for (var i = 0; i < top5.length; i++) {
          final category = top5[i];
          final percentage = category.getPercentage(totalExpense);

          sections.add(
            PieChartSectionData(
              color: colors[i],
              value: category.amount,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        }

        // Add "Others" slice if there are more than 5 categories
        if (othersAmount > 0) {
          final othersPercentage = (othersAmount / totalExpense) * 100;
          sections.add(
            PieChartSectionData(
              color: colors[5], // Grey color
              value: othersAmount,
              title: '${othersPercentage.toStringAsFixed(1)}%',
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        }

        return Container(
          height: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    startDegreeOffset: -90,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  // Top 5 category legends
                  ...top5.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.categoryName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),

                  // "Others" legend if applicable
                  if (othersAmount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[5], // Grey
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Others (${categories.length - 5})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Error loading pie chart',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCategoriesList() {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }

    final (startDate, endDate) = _getDateRange();
    final params = AnalyticsParams(
      profileId: activeProfile.id,
      startDate: startDate,
      endDate: endDate,
    );

    final topCategoriesAsync = ref.watch(topCategoriesProvider(params));

    return topCategoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'No expenses in this period',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final totalExpense = categories.fold(0.0, (sum, cat) => sum + cat.amount);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: categories.map((category) {
              final percentage = category.getPercentage(totalExpense);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          category.categoryIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.categoryName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${category.transactionCount} transaction${category.transactionCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              NumberFormat.currency(symbol: '₹').format(category.amount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Error loading categories',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
  Widget _buildBudgetOverview() {
    final budgetState = ref.watch(budgetProvider);
    final categoryState = ref.watch(categoryProvider);

    // Show loading state
    if (budgetState.isLoading || categoryState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (budgetState.error != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Error: ${budgetState.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    // Show empty state if no budgets
    if (budgetState.budgets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'No Budgets Set',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Set budgets for your expense categories\nto track your spending',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build budget cards
    return Column(
      children: budgetState.budgetStatuses.entries.map((entry) {
        final categoryId = entry.key;
        final status = entry.value;

        // Find category details
        final category = categoryState.categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => categoryState.categories.first,
        );

        return _buildBudgetCard(
          category: category,
          status: status,
        );
      }).toList(),
    );
  }

  Widget _buildBudgetCard({
    required category,
    required BudgetStatus status,
  }) {
    // Determine progress bar color based on alert level
    Color progressColor;
    switch (status.alertLevel) {
      case BudgetAlertLevel.safe:
        progressColor = AppColors.success;
        break;
      case BudgetAlertLevel.warning:
        progressColor = Colors.orange;
        break;
      case BudgetAlertLevel.critical:
        progressColor = Colors.deepOrange;
        break;
      case BudgetAlertLevel.overBudget:
        progressColor = AppColors.error;
        break;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to category detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header with icon and name
            Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Category name and period
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status.budget.period.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Budget status percentage
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${status.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (status.percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 12),

            // Spent and Budget amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '₹').format(status.spent),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '₹').format(status.budget.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Remaining amount
            Row(
              children: [
                Icon(
                  status.remaining >= 0
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: status.remaining >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  status.remaining >= 0
                      ? '${NumberFormat.currency(symbol: '₹').format(status.remaining)} remaining'
                      : '${NumberFormat.currency(symbol: '₹').format(status.remaining.abs())} over budget',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: status.remaining >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetSavingsCard(AnalyticsSummary summary) {
    final netSavings = summary.netBalance;
    final isPositive = netSavings >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? AppColors.success : AppColors.error,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? 'Net Savings' : 'Net Loss',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: '₹').format(netSavings.abs()),
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseComparison(AnalyticsSummary summary) {
    final maxValue = summary.totalIncome > summary.totalExpense
        ? summary.totalIncome
        : summary.totalExpense;

    final incomePercentage = maxValue > 0 ? (summary.totalIncome / maxValue) : 0.0;
    final expensePercentage = maxValue > 0 ? (summary.totalExpense / maxValue) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Income Bar
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Income',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: incomePercentage,
                      minHeight: 24,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '₹').format(summary.totalIncome),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Expense Bar
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Expenses',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: expensePercentage,
                      minHeight: 24,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '₹').format(summary.totalExpense),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRate(AnalyticsSummary summary) {
    final savingsRate = summary.savingsRate;
    final isPositive = savingsRate >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Savings Rate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Percentage value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${savingsRate.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  isPositive ? 'saved' : 'deficit',
                  style: TextStyle(
                    fontSize: 14,
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          LinearProgressIndicator(
            value: (savingsRate.abs() / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isPositive ? AppColors.success : AppColors.error,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCount(AnalyticsSummary summary) {
    final rangeLabel = _selectedRange.label.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Transactions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.transactionCount}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'transaction${summary.transactionCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _selectedRange == DateRangeType.custom
                ? 'in selected period'
                : 'in $rangeLabel',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageDailySpending(AnalyticsSummary summary) {
    final (startDate, endDate) = _getDateRange();
    final days = endDate.difference(startDate).inDays + 1;
    final netSpending = summary.totalExpense - summary.totalIncome;
    final dailyAverage = days > 0 ? netSpending / days : 0;
    final isNegative = dailyAverage < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Average',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(symbol: '₹').format(dailyAverage.abs()),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isNegative ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'per day across $days day${days == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodComparison() {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }

    final (currentStart, currentEnd) = _getDateRange();
    final (previousStart, previousEnd) = _getPreviousPeriodDateRange();

    final currentParams = AnalyticsParams(
      profileId: activeProfile.id,
      startDate: currentStart,
      endDate: currentEnd,
    );

    final previousParams = AnalyticsParams(
      profileId: activeProfile.id,
      startDate: previousStart,
      endDate: previousEnd,
    );

    final currentAnalytics = ref.watch(analyticsSummaryProvider(currentParams));
    final previousAnalytics = ref.watch(analyticsSummaryProvider(previousParams));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: currentAnalytics.when(
        data: (current) => previousAnalytics.when(
          data: (previous) {
            final incomeChange = previous.totalIncome > 0
                ? ((current.totalIncome - previous.totalIncome) / previous.totalIncome) * 100
                : (current.totalIncome > 0 ? 100.0 : 0.0);

            final expenseChange = previous.totalExpense > 0
                ? ((current.totalExpense - previous.totalExpense) / previous.totalExpense) * 100
                : (current.totalExpense > 0 ? 100.0 : 0.0);

            final incomeIncreased = incomeChange >= 0;
            final expenseIncreased = expenseChange >= 0;

            final periodLabel = switch (_selectedRange) {
              DateRangeType.today => 'Yesterday',
              DateRangeType.week => 'Last Week',
              DateRangeType.month => 'Last Month',
              DateRangeType.year => 'Last Year',
              DateRangeType.custom => 'Previous Period',
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compared to $periodLabel',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Income comparison
                _buildComparisonRow(
                  label: 'Income',
                  previousAmount: previous.totalIncome,
                  currentAmount: current.totalIncome,
                  changePercentage: incomeChange,
                  isIncrease: incomeIncreased,
                  isGoodChange: incomeIncreased,
                ),
                const SizedBox(height: 16),
                // Expense comparison
                _buildComparisonRow(
                  label: 'Expenses',
                  previousAmount: previous.totalExpense,
                  currentAmount: current.totalExpense,
                  changePercentage: expenseChange,
                  isIncrease: expenseIncreased,
                  isGoodChange: !expenseIncreased,
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => const Text(
            'Error loading comparison data',
            style: TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => const Text(
          'Error loading data',
          style: TextStyle(color: AppColors.error, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required String label,
    required double previousAmount,
    required double currentAmount,
    required double changePercentage,
    required bool isIncrease,
    required bool isGoodChange,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(symbol: '₹').format(currentAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isGoodChange
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isGoodChange ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '${changePercentage.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isGoodChange ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHealthScore(AnalyticsSummary summary) {
    final score = summary.healthScore;
    final status = summary.healthStatus;
    final color = summary.healthColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Financial Health',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _getHealthScoreMessage(score),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthScoreMessage(int score) {
    if (score >= 80) {
      return 'Excellent! You\'re saving well and maintaining healthy finances.';
    } else if (score >= 60) {
      return 'Good job! You\'re on the right track with your savings.';
    } else if (score >= 40) {
      return 'Fair. Try to increase your savings rate for better financial health.';
    } else {
      return 'Your spending exceeds income. Consider reducing expenses.';
    }
  }

  Widget _buildLargestExpense(AnalyticsSummary summary) {
    final largestExpense = summary.largestExpense;

    if (largestExpense == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'No expenses in this period',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biggest Expense',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Amount and Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  largestExpense.categoryIcon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NumberFormat.currency(symbol: '₹').format(largestExpense.amount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      largestExpense.categoryName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date
          Text(
            DateFormat('MMM dd, yyyy').format(largestExpense.date),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
