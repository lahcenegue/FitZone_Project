import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

import 'package:fitzone/core/location/location_provider.dart';
import 'package:fitzone/core/network/api_provider.dart';
import 'package:fitzone/features/explore/data/models/gym_model.dart';
import 'package:fitzone/features/explore/data/services/explore_api_service.dart';
import 'package:fitzone/features/explore/presentation/providers/explore_filter_state.dart';

part 'explore_provider.g.dart';

final Logger _logger = Logger('ExploreProvider');

/// Provider for ExploreApiService using standard Ref for modern Riverpod Generator compatibility
@riverpod
ExploreApiService exploreApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return ExploreApiService(dio: dio);
}

/// StateNotifier replacing the legacy ExploreFilterNotifier
@riverpod
class ExploreFilter extends _$ExploreFilter {
  @override
  ExploreFilterState build() => const ExploreFilterState();

  void updateFilters(ExploreFilterState newState) {
    // Prevent server errors by validating price constraints before state update
    if (newState.minPrice != null &&
        newState.maxPrice != null &&
        newState.minPrice! > newState.maxPrice!) {
      _logger.warning(
        'Validation failed: minPrice cannot be greater than maxPrice. Adjusting minPrice.',
      );
      state = newState.copyWith(minPrice: newState.maxPrice);
      return;
    }

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

/// Provider for managing the currently selected map place
@riverpod
class SelectedPlace extends _$SelectedPlace {
  @override
  GymModel? build() => null;

  void selectPlace(GymModel? place) {
    state = place;
  }
}

/// FutureProvider for fetching nearby places using standard Ref
@riverpod
Future<List<GymModel>> nearbyPlaces(Ref ref) async {
  final filters = ref.watch(exploreFilterProvider);
  final apiService = ref.watch(exploreApiServiceProvider);

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
}
