import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../domain/models/analytics_summary.dart';
import '../../../../core/utils/result.dart';

/// Provider for AnalyticsRepository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return AnalyticsRepository(transactionRepository);
});

/// Provider for analytics summary with date range
final analyticsSummaryProvider = FutureProvider.family<AnalyticsSummary, AnalyticsParams>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);

    final result = await repository.getAnalyticsSummary(
      profileId: params.profileId,
      startDate: params.startDate,
      endDate: params.endDate,
    );

    if (result.isSuccess) {
      return result.data!;
    } else {
      throw result.exception!;
    }
  },
);

/// Provider for top spending categories (no limit - returns all)
final topCategoriesProvider = FutureProvider.family<List<CategorySpending>, AnalyticsParams>(
  (ref, params) async {
    final repository = ref.watch(analyticsRepositoryProvider);

    final result = await repository.getTopCategories(
      profileId: params.profileId,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: 999, // Get all categories
    );

    if (result.isSuccess) {
      return result.data!;
    } else {
      throw result.exception!;
    }
  },
);

/// Parameters for analytics queries
class AnalyticsParams {
  final String profileId;
  final DateTime startDate;
  final DateTime endDate;

  const AnalyticsParams({
    required this.profileId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsParams &&
          runtimeType == other.runtimeType &&
          profileId == other.profileId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => profileId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}
