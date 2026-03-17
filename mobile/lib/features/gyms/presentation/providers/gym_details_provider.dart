import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gym_details_model.dart';
import '../../data/services/gyms_api_service.dart';

/// Provides the singleton instance of the Gyms API service.
final gymsApiServiceProvider = Provider<GymsApiService>((ref) {
  return GymsApiService();
});

/// Fetches and caches the gym details based on the provided branch ID.
final gymDetailsProvider = FutureProvider.family<GymDetailsModel, int>((
  ref,
  branchId,
) async {
  final apiService = ref.watch(gymsApiServiceProvider);
  return await apiService.fetchGymBranchDetails(branchId);
});
