import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_provider.dart';
import '../../data/models/loyalty_models.dart';
import '../../data/services/loyalty_api_service.dart';

part 'loyalty_dashboard_providers.g.dart';

@riverpod
LoyaltyApiService loyaltyApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return LoyaltyApiService(dio: dio);
}

@riverpod
Future<WalletSummary> loyaltyWallet(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getWalletSummary();
}

@riverpod
Future<List<LoyaltyPackage>> loyaltyPackages(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getPackages();
}

@riverpod
Future<List<UserMilestone>> allUserMilestones(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  // 'all' passes null to backend to get unlocked, claimed, and consumed
  final paginatedData = await apiService.getMyMilestones();
  return paginatedData.results;
}

@riverpod
Future<List<UserMilestone>> consumedRewards(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  final paginatedData = await apiService.getMyMilestones(status: 'consumed');
  return paginatedData.results;
}

@riverpod
Future<PaginatedTransactions> dashboardTransactions(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getTransactions(limit: 5);
}

@riverpod
Future<TransactionSummary> transactionSummary(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getTransactionSummary();
}

@riverpod
Future<PaginatedTransactions> filteredTransactions(
  Ref ref, {
  int? limit,
  int? page,
  String? type,
}) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getTransactions(limit: limit, page: page, type: type);
}

@riverpod
Future<PaginatedUserMilestones> dashboardRewards(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getMyMilestones(limit: 5, status: 'claimed');
}

@riverpod
Future<PaginatedPointsTransactions> dashboardPoints(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getPointsHistory(limit: 5);
}

// ARCHITECTURE FIX: Fetch the user-specific roadmap
@riverpod
Future<List<LoyaltyMilestone>> loyaltyRoadmap(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getUserRoadmap();
}

@riverpod
Future<PointsSummary> pointsSummary(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getPointsSummary();
}

@riverpod
Future<RewardsSummary> rewardsSummary(Ref ref) async {
  final apiService = ref.watch(loyaltyApiServiceProvider);
  return await apiService.getRewardsSummary();
}
