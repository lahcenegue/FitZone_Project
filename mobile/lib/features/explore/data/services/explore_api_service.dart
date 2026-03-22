import 'package:dio/dio.dart';
import 'package:fitzone/features/explore/presentation/providers/explore_filter_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
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

  /// Unified discovery method that handles bounds, search queries, and filters.
  /// This replaces the old fetchPlacesInBounds method.
  Future<List<GymModel>> discoverPlaces({
    required ExploreFilterState filters,
    LatLng? userLocation,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      // 1. Basic Type Filter
      if (filters.type.isNotEmpty) {
        queryParams['type'] = filters.type;
      }

      // 2. Text Search Query
      if (filters.query != null && filters.query!.isNotEmpty) {
        queryParams['q'] = filters.query;
      }

      // 3. Status and Gender Filters
      if (filters.gender != null && filters.gender!.isNotEmpty) {
        queryParams['gender'] = filters.gender;
      }
      if (filters.isOpen) {
        queryParams['is_open'] = true;
      }
      if (filters.maxPrice != null) {
        queryParams['max_price'] = filters.maxPrice;
      }

      // 4. Sorting Logic
      if (filters.sortBy != null && filters.sortBy!.isNotEmpty) {
        queryParams['sort_by'] = filters.sortBy;
      }

      // 5. Geographic Map Bounds
      if (filters.bounds != null) {
        queryParams['min_lat'] = filters.bounds!.southwest.latitude
            .toStringAsFixed(6);
        queryParams['min_lng'] = filters.bounds!.southwest.longitude
            .toStringAsFixed(6);
        queryParams['max_lat'] = filters.bounds!.northeast.latitude
            .toStringAsFixed(6);
        queryParams['max_lng'] = filters.bounds!.northeast.longitude
            .toStringAsFixed(6);
      }

      // 6. User Geo-coordinates (Required for distance-based sorting)
      if (userLocation != null && filters.sortBy == 'distance') {
        queryParams['lat'] = userLocation.latitude.toStringAsFixed(6);
        queryParams['lng'] = userLocation.longitude.toStringAsFixed(6);
      }

      _logger.info(
        'Calling Unified Discovery API: ${ApiConstants.mapDiscover} with params: $queryParams',
      );

      final response = await _dio.get(
        ApiConstants
            .mapDiscover, // Ensure this points to '/providers/discover/'
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;
        final List<dynamic> results =
            responseData['results'] as List<dynamic>? ?? [];

        return results
            .map((json) => GymModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe(
        'Network Error: [${e.response?.statusCode}] ${e.response?.data}',
      );
      throw Exception('Network error: ${e.message}');
    } catch (e, stackTrace) {
      _logger.severe('Data processing error in discoverPlaces.', e, stackTrace);
      throw Exception('Data parsing error');
    }
  }
}
