import 'package:dio/dio.dart';
import 'package:fitzone/features/explore/presentation/providers/explore_filter_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../models/gym_model.dart';

class ExploreApiService {
  final Dio _dio;
  final Logger _logger = Logger('ExploreApiService');

  ExploreApiService({required Dio dio}) : _dio = dio;

  Future<List<GymModel>> discoverPlaces({
    required ExploreFilterState filters,
    LatLng? userLocation,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      queryParams['type'] = filters.category;

      if (filters.query != null && filters.query!.isNotEmpty) {
        queryParams['q'] = filters.query;
      }

      if (filters.cityId != null && filters.cityId!.isNotEmpty) {
        queryParams['city'] = filters.cityId;
      }

      if (filters.gender != null && filters.gender!.isNotEmpty) {
        queryParams['gender'] = filters.gender;
      }

      if (filters.isOpen) {
        queryParams['is_open'] = true;
      }

      if (filters.minPrice != null) {
        queryParams['min_price'] = filters.minPrice;
      }
      if (filters.maxPrice != null) {
        queryParams['max_price'] = filters.maxPrice;
      }

      if (filters.selectedSports.isNotEmpty) {
        queryParams['sports'] = filters.selectedSports.join(',');
      }
      if (filters.selectedAmenities.isNotEmpty) {
        queryParams['amenities'] = filters.selectedAmenities.join(',');
      }
      if (filters.selectedDietary.isNotEmpty) {
        queryParams['dietary_options'] = filters.selectedDietary.join(',');
      }
      if (filters.selectedEquipmentCategories.isNotEmpty) {
        queryParams['equipment_categories'] = filters
            .selectedEquipmentCategories
            .join(',');
      }

      if (filters.sortBy != null && filters.sortBy!.isNotEmpty) {
        queryParams['sort_by'] = filters.sortBy;
      }

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

      // ARCHITECTURE FIX: Clean single assignment of user location
      if (userLocation != null) {
        queryParams['lat'] = userLocation.latitude.toStringAsFixed(6);
        queryParams['lng'] = userLocation.longitude.toStringAsFixed(6);
        queryParams['radius_km'] = filters.radiusKm;
      }

      _logger.info('Calling Unified Discovery API with params: $queryParams');

      final Response response = await _dio.get(
        ApiConstants.mapDiscover,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;
        final List<dynamic> results =
            responseData['results'] as List<dynamic>? ?? [];

        final List<GymModel> validPlaces = [];

        for (var json in results) {
          try {
            // This will skip any branch that throws a FormatException (e.g., null coordinates)
            validPlaces.add(GymModel.fromJson(json as Map<String, dynamic>));
          } catch (_) {
            // Skip silently. The model already logged the warning.
            continue;
          }
        }

        return validPlaces;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe(
        'Network Error: [${e.response?.statusCode}] ${e.response?.data}',
      );
      throw Exception('Network error: ${e.message}');
    }
  }
}
