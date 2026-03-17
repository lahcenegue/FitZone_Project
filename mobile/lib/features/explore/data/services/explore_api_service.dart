import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/gym_model.dart';

class ExploreApiService {
  final Dio _dio;
  final Logger _logger = Logger('ExploreApiService');

  ExploreApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              responseType: ResponseType.json,
            ),
          );

  /// Fetches gyms and places within the specified map coordinates.
  Future<List<GymModel>> fetchPlacesInBounds(LatLngBounds bounds) async {
    try {
      final Map<String, dynamic> queryParams = {
        'min_lat': bounds.southwest.latitude.toStringAsFixed(6),
        'min_lng': bounds.southwest.longitude.toStringAsFixed(6),
        'max_lat': bounds.northeast.latitude.toStringAsFixed(6),
        'max_lng': bounds.northeast.longitude.toStringAsFixed(6),
      };

      _logger.info(
        'API Call: ${ApiConstants.mapDiscover} with params: $queryParams',
      );

      final response = await _dio.get(
        ApiConstants.mapDiscover,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Safe parsing: Cast response.data and handle missing 'results' key safely
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;
        final List<dynamic> data =
            responseData['results'] as List<dynamic>? ?? [];

        return data
            .map((json) => GymModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe(
        'Dio Error: [${e.response?.statusCode}] ${e.response?.data}',
      );
      throw Exception('Network error: ${e.message}');
    } catch (e, stackTrace) {
      _logger.severe('Parsing error.', e, stackTrace);
      throw Exception('Data parsing error: $e');
    }
  }
}
