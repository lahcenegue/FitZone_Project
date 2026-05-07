import 'dart:async';
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

    _statusStream = ref
        .read(locationServiceProvider)
        .serviceStatusStream
        .listen((status) {
          final isEnabled = status == ServiceStatus.enabled;
          state = state.copyWith(isServiceEnabled: isEnabled);
          if (isEnabled) {
            fetchLocation();
          }
        });

    ref.onDispose(() {
      _statusStream?.cancel();
    });

    return LocationState(location: lastLoc);
  }

  Future<void> openSettings() async {
    await ref.read(locationServiceProvider).openLocationSettings();
  }

  Future<void> promptEnableLocation() async {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      await ref.read(locationServiceProvider).requestLocationServicePopup();
    } else {
      await openSettings();
    }
  }

  Future<void> fetchLocation() async {
    _logger.info('Initiating smart location fetch sequence...');

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
      // ARCHITECTURE FIX: Stale-while-Revalidate strategy
      if (state.location != null) {
        _logger.info(
          'Cached location exists. Bypassing wait to unblock UI. Triggering background update.',
        );
        unawaited(_updateRealLocationInBackground());
        return;
      } else {
        _logger.info(
          'First time launch: No cached location found. Awaiting real GPS lock.',
        );
        await _updateRealLocationInBackground();
      }
    }
  }

  Future<void> _updateRealLocationInBackground() async {
    try {
      final LocationService service = ref.read(locationServiceProvider);
      final LatLng? realLocation = await service.getCurrentLocation();

      if (realLocation != null) {
        await ref.read(storageServiceProvider).setLastLocation(realLocation);
        state = state.copyWith(location: realLocation);
        _logger.info('Background location update successful.');
      } else {
        _logger.warning(
          'Failed to fetch real location in background. Retaining cache if available.',
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('Error updating location in background', e, stackTrace);
    }
  }
}
