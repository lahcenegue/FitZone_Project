import 'package:fitzone/features/explore/data/models/gym_model.dart';
import 'package:fitzone/features/explore/data/services/explore_api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/network/api_provider.dart';

import 'explore_filter_state.dart';

final Logger _logger = Logger('ExploreProvider');

final exploreApiServiceProvider = Provider<ExploreApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ExploreApiService(dio: dio);
});

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
    state = ExploreFilterState(bounds: state.bounds);
  }
}

final exploreFilterProvider =
    NotifierProvider<ExploreFilterNotifier, ExploreFilterState>(
      () => ExploreFilterNotifier(),
    );

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

final nearbyPlacesProvider = FutureProvider<List<GymModel>>((ref) async {
  final filters = ref.watch(exploreFilterProvider);
  final apiService = ref.watch(exploreApiServiceProvider);

  // Extract the actual LatLng from the LocationState
  final locationState = ref.watch(userLocationProvider);
  final userLocation = locationState.location;

  if (filters.bounds == null &&
      (filters.query == null || filters.query!.isEmpty)) {
    return [];
  }

  _logger.info('Fetching nearby places with unified filters...');

  return await apiService.discoverPlaces(
    filters: filters,
    userLocation: userLocation,
  );
});
