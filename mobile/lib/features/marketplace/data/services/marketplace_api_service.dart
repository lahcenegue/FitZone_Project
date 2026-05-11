import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../../../../core/config/api_constants.dart';
import '../models/resale_models.dart';

class MarketplaceApiService {
  final Dio _dio;
  final Logger _logger = Logger('MarketplaceApiService');

  MarketplaceApiService({required Dio dio}) : _dio = dio;

  Future<PaginatedResaleItems> discoverResaleItems({
    int page = 1,
    String? q,
    String? city,
    String? gender,
    double? minPrice,
    double? maxPrice,
    int? minDays,
    int? minDiscount,
    double? userLat,
    double? userLng,
    double? radiusKm,
    String? sortBy,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page};

      if (q != null && q.trim().isNotEmpty) queryParams['q'] = q.trim();
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (gender != null && gender.isNotEmpty) queryParams['gender'] = gender;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (minDays != null) queryParams['min_days'] = minDays;
      if (minDiscount != null) queryParams['min_discount'] = minDiscount;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;

      if (userLat != null && userLng != null) {
        queryParams['user_lat'] = userLat;
        queryParams['user_lng'] = userLng;
        if (radiusKm != null) queryParams['radius_km'] = radiusKm;
      }

      _logger.info('Fetching resale items with params: $queryParams');

      final response = await _dio.get(
        ApiConstants.resaleDiscover,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return PaginatedResaleItems.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          'Failed to load marketplace items: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.severe('DioException in discoverResaleItems: ${e.message}', e);
      throw Exception('Network error while fetching marketplace data.');
    } catch (e, stackTrace) {
      _logger.severe(
        'Data parsing error in discoverResaleItems',
        e,
        stackTrace,
      );
      throw Exception('Failed to parse marketplace data.');
    }
  }
}
