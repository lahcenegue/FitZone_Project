import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/network/api_provider.dart';

/// Provider for the PlacesApiService, injecting the globally configured Dio client.
final placesApiServiceProvider = Provider<PlacesApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PlacesApiService(dio);
});

/// Service responsible for communicating with Google Places API.
/// Handles autocomplete suggestions and fetching specific place details (Geometry/Coordinates).
class PlacesApiService {
  final Dio _dio;
  final Logger _logger = Logger('PlacesApiService');

  PlacesApiService(this._dio);

  /// Fetches autocomplete suggestions based on the user's search query.
  ///
  /// Uses a [sessionToken] to group queries into a single billable session,
  /// drastically reducing Google Maps API costs. Restricts results to Saudi Arabia (country:sa).
  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
    String query,
    String sessionToken,
  ) async {
    if (query.trim().isEmpty) return [];

    const String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'input': query,
          'key': AppConstants.googleMapsApiKey,
          'sessiontoken': sessionToken,
          'components': 'country:sa', // Restrict search results to Saudi Arabia
          'language': 'en', // Force English language for consistent results
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final predictions = response.data['predictions'] as List;
        return predictions.map((p) => p as Map<String, dynamic>).toList();
      }

      _logger.warning(
        'Autocomplete API returned status: ${response.data['status']}',
      );
      return [];
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch autocomplete suggestions', e, stackTrace);
      return [];
    }
  }

  /// Fetches detailed information (specifically coordinates and formatted address) for a selected place.
  ///
  /// The [placeId] is obtained from the autocomplete suggestions.
  /// The same [sessionToken] must be passed to finalize the billing session.
  Future<Map<String, dynamic>?> getPlaceDetails(
    String placeId,
    String sessionToken,
  ) async {
    const String url =
        'https://maps.googleapis.com/maps/api/place/details/json';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'place_id': placeId,
          'key': AppConstants.googleMapsApiKey,
          'sessiontoken': sessionToken,
          // Requesting ONLY the necessary fields limits data payload and reduces cost
          'fields': 'geometry,formatted_address,name',
          'language': 'en',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        return response.data['result'] as Map<String, dynamic>;
      }

      _logger.warning(
        'Place Details API returned status: ${response.data['status']}',
      );
      return null;
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch place details', e, stackTrace);
      return null;
    }
  }
}
