import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/gym_model.dart';
import '../../data/services/explore_api_service.dart';

// 1. API Service Provider
final exploreApiServiceProvider = Provider<ExploreApiService>((ref) {
  return ExploreApiService();
});

// 2. Modern Notifier for Map Bounds (Replaces Legacy StateProvider)
class MapBoundsNotifier extends Notifier<LatLngBounds?> {
  @override
  LatLngBounds? build() => null;

  void updateBounds(LatLngBounds newBounds) {
    state = newBounds;
  }
}

final mapBoundsProvider = NotifierProvider<MapBoundsNotifier, LatLngBounds?>(
  () {
    return MapBoundsNotifier();
  },
);

// 3. Modern Notifier for Selected Place (Replaces Legacy StateProvider)
class SelectedPlaceNotifier extends Notifier<GymModel?> {
  @override
  GymModel? build() => null;

  void selectPlace(GymModel? place) {
    state = place;
  }
}

final selectedPlaceProvider =
    NotifierProvider<SelectedPlaceNotifier, GymModel?>(() {
      return SelectedPlaceNotifier();
    });

// 4. Future Provider to fetch data
final nearbyPlacesProvider = FutureProvider<List<GymModel>>((ref) async {
  final LatLngBounds? bounds = ref.watch(mapBoundsProvider);

  if (bounds == null) return [];

  final apiService = ref.watch(exploreApiServiceProvider);
  return await apiService.fetchPlacesInBounds(bounds);
});
