import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../models/subscription_model.dart';

class SubscriptionApiService {
  final Dio _dio;
  static final Logger _logger = Logger('SubscriptionApiService');

  SubscriptionApiService(this._dio);

  Future<List<SubscriptionModel>> fetchMySubscriptions() async {
    try {
      _logger.info('Fetching user subscriptions.');
      final response = await _dio.get(ApiConstants.mySubscriptions);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) => SubscriptionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      _logger.severe('Failed to fetch subscriptions', e, e.stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.severe(
        'Unexpected error while fetching subscriptions',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
