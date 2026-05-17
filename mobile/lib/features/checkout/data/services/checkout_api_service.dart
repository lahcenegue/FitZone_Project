import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../models/checkout_models.dart';

class CheckoutApiService {
  final Dio _dio;
  static final Logger _logger = Logger('CheckoutApiService');

  CheckoutApiService(this._dio);

  Future<CheckoutPreviewResponse> getCheckoutPreview(
    CheckoutProcessRequest request,
  ) async {
    try {
      _logger.info(
        'Requesting checkout preview for ${request.itemType} ID: ${request.itemId}',
      );
      final response = await _dio.post(
        ApiConstants.checkoutPreview,
        data: request.toJson(),
      );
      return CheckoutPreviewResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _logger.severe('Failed to fetch checkout preview', e, e.stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error during checkout preview', e, stackTrace);
      rethrow;
    }
  }

  Future<CheckoutProcessResponse> processCheckout(
    CheckoutProcessRequest request,
  ) async {
    try {
      _logger.info(
        'Processing checkout for ${request.itemType} ID: ${request.itemId}',
      );
      final response = await _dio.post(
        ApiConstants.checkoutProcess,
        data: request.toJson(),
      );
      return CheckoutProcessResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _logger.severe('Failed to process checkout payment', e, e.stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.severe(
        'Unexpected error during payment processing',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
