import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

/// Manages the user's current GPS location state globally.
class UserLocationNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  /// Fetches and updates the user's current location.
  Future<void> fetchLocation() async {
    final location = await LocationService.getCurrentLocation();
    if (location != null) {
      state = location;
    }
  }
}

final userLocationProvider = NotifierProvider<UserLocationNotifier, LatLng?>(
  () {
    return UserLocationNotifier();
  },
);
