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
    double? userLat,
    double? userLng,
  }) async {
    try {
      _logger.info(
        'Fetching resale items from API: ${ApiConstants.resaleDiscover}',
      );

      final Map<String, dynamic> queryParams = {'page': page};
      if (userLat != null && userLng != null) {
        queryParams['lat'] = userLat;
        queryParams['lng'] = userLng;
      }

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
