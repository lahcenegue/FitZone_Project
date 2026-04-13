import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_provider.dart';
import '../../data/models/subscription_model.dart';
import '../../data/services/subscription_api_service.dart';

part 'subscription_provider.g.dart';

@riverpod
SubscriptionApiService subscriptionApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return SubscriptionApiService(dio);
}

/// Fetches and caches the user's subscriptions.
@riverpod
Future<List<SubscriptionModel>> mySubscriptions(Ref ref) async {
  final apiService = ref.watch(subscriptionApiServiceProvider);
  return await apiService.fetchMySubscriptions();
}
