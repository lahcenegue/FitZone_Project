import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';
import '../storage/storage_provider.dart';

part 'location_provider.g.dart';

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) {
  return LocationService();
}

class LocationState {
  final LatLng? location;
  final bool isServiceEnabled;
  final bool isPermissionGranted;

  const LocationState({
    this.location,
    this.isServiceEnabled = true,
    this.isPermissionGranted = true,
  });

  LocationState copyWith({
    LatLng? location,
    bool? isServiceEnabled,
    bool? isPermissionGranted,
  }) {
    return LocationState(
      location: location ?? this.location,
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
    );
  }
}

@Riverpod(keepAlive: true)
class UserLocation extends _$UserLocation {
  static final Logger _logger = Logger('UserLocation');
  StreamSubscription<ServiceStatus>? _statusStream;

  @override
  LocationState build() {
    final lastLoc = ref.read(storageServiceProvider).getLastLocation();

    // Listen to hardware GPS changes in real-time!
    _statusStream = ref
        .read(locationServiceProvider)
        .serviceStatusStream
        .listen((status) {
          final isEnabled = status == ServiceStatus.enabled;
          state = state.copyWith(isServiceEnabled: isEnabled);
          if (isEnabled) {
            // Auto-fetch the new location the moment GPS is turned back on
            fetchLocation();
          }
        });

    ref.onDispose(() {
      _statusStream?.cancel();
    });

    return LocationState(location: lastLoc);
  }

  /// Opens the device settings to force user to enable GPS
  Future<void> openSettings() async {
    await ref.read(locationServiceProvider).openLocationSettings();
  }

  Future<void> fetchLocation() async {
    _logger.info('Attempting to fetch real user location...');

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    bool permissionGranted =
        (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse);

    if (!permissionGranted && permission != LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      permissionGranted =
          (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse);
    }

    state = state.copyWith(
      isServiceEnabled: serviceEnabled,
      isPermissionGranted: permissionGranted,
    );

    if (serviceEnabled && permissionGranted) {
      final LocationService service = ref.read(locationServiceProvider);
      final LatLng? realLocation = await service.getCurrentLocation();

      if (realLocation != null) {
        await ref.read(storageServiceProvider).setLastLocation(realLocation);
        state = state.copyWith(location: realLocation);
      }
    }
  }
}
