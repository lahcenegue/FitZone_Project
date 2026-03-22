import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'location_service.dart';

part 'location_provider.g.dart';

/// Provides a globally accessible instance of LocationService.
@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) {
  return LocationService();
}

/// Manages the user's current GPS location state globally.
@Riverpod(keepAlive: true)
class UserLocation extends _$UserLocation {
  static final Logger _logger = Logger('UserLocation');

  @override
  LatLng? build() {
    return null; // Initial state is unknown/null
  }

  /// Fetches and updates the user's current location state.
  Future<void> fetchLocation() async {
    _logger.info('Attempting to fetch user location...');
    final LocationService service = ref.read(locationServiceProvider);
    final LatLng? location = await service.getCurrentLocation();

    if (location != null) {
      state = location;
    } else {
      _logger.warning('Could not update state: Location is null.');
    }
  }
}
