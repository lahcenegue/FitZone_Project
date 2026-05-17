import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/network/api_provider.dart';
import '../../data/models/gym_model.dart';
import '../../data/services/explore_api_service.dart';
import '../providers/explore_filter_state.dart';

part 'explore_provider.g.dart';

final Logger _logger = Logger('ExploreProvider');

@riverpod
ExploreApiService exploreApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return ExploreApiService(dio: dio);
}

@riverpod
class ExploreFilter extends _$ExploreFilter {
  @override
  ExploreFilterState build() => const ExploreFilterState();

  void updateFilters(ExploreFilterState newState) {
    state = newState;
  }

  void updateBounds(LatLngBounds bounds) {
    state = state.copyWith(bounds: bounds);
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void resetFilters() {
    state = ExploreFilterState(bounds: state.bounds);
  }
}

@riverpod
class SelectedPlace extends _$SelectedPlace {
  @override
  GymModel? build() => null;

  void selectPlace(GymModel? place) {
    state = place;
  }
}

@riverpod
Future<List<GymModel>> nearbyPlaces(Ref ref) async {
  final filters = ref.watch(exploreFilterProvider);
  final apiService = ref.watch(exploreApiServiceProvider);

  final locationState = ref.watch(userLocationProvider);
  final userLocation = locationState.location;

  if (filters.bounds == null &&
      (filters.query == null || filters.query!.isEmpty) &&
      filters.cityId == null) {
    return [];
  }

  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  // ARCHITECTURE FIX: Using centralized debounce constant
  await Future<void>.delayed(
    const Duration(milliseconds: AppConstants.debounceMilliseconds),
  );
  if (cancelToken.isCancelled) {
    _logger.info(
      'Skipping cancelled request (Map is still moving or filters changed).',
    );
    return [];
  }

  _logger.info('Fetching nearby places with unified filters after debounce...');

  return await apiService.discoverPlaces(
    filters: filters,
    userLocation: userLocation,
    cancelToken: cancelToken,
  );
}
