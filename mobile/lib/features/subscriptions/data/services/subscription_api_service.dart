import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../models/subscription_model.dart';

class SubscriptionApiService {
  final Dio _dio;
  static final Logger _logger = Logger('SubscriptionApiService');

  SubscriptionApiService(this._dio);

  /// Processes the payment and activates the subscription.
  Future<SubscriptionModel> checkout(int planId, String gateway) async {
    try {
      _logger.info('Initiating checkout for plan: $planId via $gateway');
      final response = await _dio.post(
        ApiConstants.checkout,
        data: {'plan_id': planId, 'gateway': gateway},
      );
      _logger.info('Checkout successful.');
      return SubscriptionModel.fromJson(
        response.data['subscription'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _logger.severe('Checkout failed', e, e.stackTrace);
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during checkout.');
    }
  }

  /// Fetches all active and past subscriptions for the authenticated user.
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
      throw _handleError(e);
    } catch (e) {
      throw Exception(
        'An unexpected error occurred while fetching subscriptions.',
      );
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final data = e.response?.data as Map<String, dynamic>;
      final message =
          data['message'] ?? data['detail'] ?? 'Transaction failed.';
      return Exception(message.toString());
    }
    return Exception('Network error. Please try again.');
  }
}
