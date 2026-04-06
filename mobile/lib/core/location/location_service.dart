import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:location/location.dart' as loc;

/// Core service for handling device location and permissions.
class LocationService {
  static final Logger _logger = Logger('LocationService');

  /// A stream that emits real-time updates when the hardware GPS is toggled on/off.
  Stream<ServiceStatus> get serviceStatusStream =>
      Geolocator.getServiceStatusStream();

  /// Opens the device's location settings so the user can enable GPS.
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Requests to enable GPS via Google Play Services in-app Popup Dialog.
  Future<bool> requestLocationServicePopup() async {
    try {
      loc.Location location = loc.Location();
      bool isTurnedOn = await location.requestService();
      _logger.info('Location popup result: $isTurnedOn');
      return isTurnedOn;
    } catch (e) {
      _logger.severe('Failed to show location popup', e);
      return false;
    }
  }

  /// Requests location permissions and retrieves the user's current GPS position.
  Future<LatLng?> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.warning('Location services are disabled by the user.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.warning('Location permissions denied by the user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.warning('Location permissions are permanently denied.');
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _logger.info(
        'Location fetched successfully: ${position.latitude}, ${position.longitude}',
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e, stackTrace) {
      _logger.severe('Failed to get current location', e, stackTrace);
      return null;
    }
  }

  /// Calculates the straight-line distance in meters between two geographical points.
  double calculateDistanceInMeters(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Formats the distance into a human-readable string (meters or kilometers).
  String formatDistance(
    double meters, {
    required String kmLabel,
    required String mLabel,
  }) {
    const double oneKilometer = 1000.0;

    if (meters < oneKilometer) {
      return '${meters.toInt()} $mLabel';
    } else {
      return '${(meters / oneKilometer).toStringAsFixed(1)} $kmLabel';
    }
  }
}
