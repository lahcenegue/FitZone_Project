import 'package:fitzone/features/explore/data/models/gym_model.dart';
import 'package:fitzone/features/explore/data/services/explore_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/network/api_provider.dart';

import 'explore_filter_state.dart';

final Logger _logger = Logger('ExploreProvider');

/// 1. API Service Provider
/// Now injects the globally configured Dio client from api_provider.dart
final exploreApiServiceProvider = Provider<ExploreApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ExploreApiService(dio: dio);
});

/// 2. Filter State Notifier (The Brain of Search & Filters)
class ExploreFilterNotifier extends Notifier<ExploreFilterState> {
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
    // Keeps current bounds but resets everything else to default
    state = ExploreFilterState(bounds: state.bounds);
  }
}

final exploreFilterProvider =
    NotifierProvider<ExploreFilterNotifier, ExploreFilterState>(
      () => ExploreFilterNotifier(),
    );

/// 3. Selected Place Notifier
class SelectedPlaceNotifier extends Notifier<GymModel?> {
  @override
  GymModel? build() => null;

  void selectPlace(GymModel? place) {
    state = place;
  }
}

final selectedPlaceProvider =
    NotifierProvider<SelectedPlaceNotifier, GymModel?>(
      () => SelectedPlaceNotifier(),
    );

/// 4. Unified Nearby Places Provider
final nearbyPlacesProvider = FutureProvider<List<GymModel>>((ref) async {
  final filters = ref.watch(exploreFilterProvider);
  final apiService = ref.watch(exploreApiServiceProvider);
  final userLocation = ref.watch(userLocationProvider);

  // Optimization: Don't fetch if map bounds are not yet initialized
  // unless there is a specific text query.
  if (filters.bounds == null &&
      (filters.query == null || filters.query!.isEmpty)) {
    return [];
  }

  _logger.info('Fetching nearby places with unified filters...');

  return await apiService.discoverPlaces(
    filters: filters,
    userLocation: userLocation != null
        ? LatLng(userLocation.latitude, userLocation.longitude)
        : null,
  );
});
