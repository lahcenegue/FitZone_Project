import 'package:fitzone/features/explore/data/models/gym_model.dart';
import 'package:fitzone/features/explore/data/services/explore_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

import 'explore_filter_state.dart';
import '../../../../core/providers/location_provider.dart';

final Logger _logger = Logger('ExploreProvider');

/// 1. API Service Provider
final exploreApiServiceProvider = Provider<ExploreApiService>((ref) {
  return ExploreApiService();
});

/// 2. Filter State Notifier (The Brain of Search & Filters)
/// Manages all filter parameters including bounds, query, and category.
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
/// Tracks which gym/place is currently selected on the map or list.
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
/// This provider reactively fetches data whenever filters, bounds, or search query change.
final nearbyPlacesProvider = FutureProvider<List<GymModel>>((ref) async {
  final filters = ref.watch(exploreFilterProvider);
  final apiService = ref.watch(exploreApiServiceProvider);
  final userLocation = ref.watch(userLocationProvider);

  // Optimization: Don't fetch if map bounds are not yet initialized
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
