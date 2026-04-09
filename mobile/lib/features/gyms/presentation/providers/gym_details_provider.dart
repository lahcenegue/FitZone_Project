import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fitzone/features/gyms/data/models/gym_details_model.dart';
import 'package:fitzone/features/gyms/data/services/gyms_api_service.dart';

part 'gym_details_provider.g.dart';

/// Provides the instance of the Gyms API service using modern Riverpod approach.
@riverpod
GymsApiService gymsApiService(Ref ref) {
  return GymsApiService();
}

/// Fetches and caches the gym details based on the provided branch ID.
@riverpod
Future<GymDetailsModel> gymDetails(Ref ref, int branchId) async {
  final apiService = ref.watch(gymsApiServiceProvider);
  return await apiService.fetchGymBranchDetails(branchId);
}
