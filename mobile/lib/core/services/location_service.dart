import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

/// Core service handling GPS location permissions and real-time positioning.
class LocationService {
  LocationService._();
  static final Logger _logger = Logger('LocationService');

  /// Requests permissions and retrieves the user's current location.
  static Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.warning('Location services are disabled by the device.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.warning('Location permissions are denied by the user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.warning('Location permissions are permanently denied.');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e, stackTrace) {
      _logger.severe('Failed to get current location', e, stackTrace);
      return null;
    }
  }

  /// Calculates the straight-line distance (in meters) between two coordinates.
  static double calculateDistanceInMeters(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Formats the distance into a readable string (e.g., "450 m" or "2.5 km").
  static String formatDistance(double meters, String kmLabel, String mLabel) {
    if (meters < 1000) {
      return '${meters.toInt()} $mLabel';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} $kmLabel';
    }
  }
}
