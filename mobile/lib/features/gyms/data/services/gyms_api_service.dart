import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../../../../core/config/api_constants.dart';
import '../models/gym_details_model.dart';

class GymsApiService {
  final Dio _dio;
  final Logger _logger = Logger('GymsApiService');

  GymsApiService({Dio? dio})
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

  /// Fetches the full details of a specific gym branch by its ID.
  Future<GymDetailsModel> fetchGymBranchDetails(int branchId) async {
    try {
      _logger.info('Fetching gym details for branch ID: $branchId');

      final response = await _dio.get(
        '${ApiConstants.gymBranchDetails}$branchId/',
      );

      if (response.statusCode == 200) {
        return GymDetailsModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe(
        'Dio Error fetching gym details: [${e.response?.statusCode}] ${e.response?.data}',
      );
      if (e.response?.statusCode == 404) {
        throw Exception('Gym branch not found.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e, stackTrace) {
      _logger.severe('Parsing error in gym details.', e, stackTrace);
      throw Exception('Data parsing error: $e');
    }
  }
}
