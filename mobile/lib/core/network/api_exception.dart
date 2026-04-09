import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:fitzone/l10n/app_localizations.dart';

/// Standardized exception class for handling all API and network errors,
/// localized for the user interface.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  /// Factory constructor to parse DioException into user-friendly localized ApiException.
  factory ApiException.fromDioException(
    DioException dioException,
    AppLocalizations l10n,
  ) {
    final Logger logger = Logger('ApiException');
    logger.severe('API Request Failed: ${dioException.message}', dioException);

    switch (dioException.type) {
      case DioExceptionType.cancel:
        return ApiException(
          l10n.errorRequestCancelled,
          dioException.response?.statusCode,
        );
      case DioExceptionType.connectionTimeout:
        return ApiException(
          l10n.errorConnectionTimeout,
          dioException.response?.statusCode,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          l10n.errorReceiveTimeout,
          dioException.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        return _handleError(
          dioException.response?.statusCode,
          dioException.response?.data,
          l10n,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          l10n.errorSendTimeout,
          dioException.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          l10n.errorNoInternet,
          dioException.response?.statusCode,
        );
      default:
        return ApiException(
          l10n.errorUnexpected,
          dioException.response?.statusCode,
        );
    }
  }

  /// Helper method to extract specific error messages based on HTTP status codes.
  static ApiException _handleError(
    int? statusCode,
    dynamic errorData,
    AppLocalizations l10n,
  ) {
    if (statusCode == null) {
      return ApiException(l10n.errorUnknownStatus);
    }

    // If the server sends a specific message, prioritize it. Otherwise, use localized fallback.
    final String serverMessage = _extractMessage(errorData);

    switch (statusCode) {
      case 400:
        return ApiException(
          serverMessage.isNotEmpty ? serverMessage : l10n.errorBadRequest,
          statusCode,
        );
      case 401:
        return ApiException(
          serverMessage.isNotEmpty ? serverMessage : l10n.errorUnauthorized,
          statusCode,
        );
      case 403:
        return ApiException(
          serverMessage.isNotEmpty ? serverMessage : l10n.errorForbidden,
          statusCode,
        );
      case 404:
        return ApiException(
          serverMessage.isNotEmpty ? serverMessage : l10n.errorNotFound,
          statusCode,
        );
      case 422:
        return ApiException(
          serverMessage.isNotEmpty ? serverMessage : l10n.errorValidation,
          statusCode,
        );
      case 500:
        return ApiException(l10n.errorInternalServer, statusCode);
      case 502:
        return ApiException(l10n.errorBadGateway, statusCode);
      default:
        return ApiException(l10n.errorOops, statusCode);
    }
  }

  /// Extracts the detailed message string from the API JSON response if available.
  static String _extractMessage(dynamic errorData) {
    if (errorData is Map<String, dynamic>) {
      if (errorData.containsKey('message') && errorData['message'] != null) {
        return errorData['message'].toString();
      } else if (errorData.containsKey('detail') &&
          errorData['detail'] != null) {
        return errorData['detail'].toString();
      }
    }
    return '';
  }

  @override
  String toString() => message;
}
