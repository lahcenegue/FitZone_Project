import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:fitzone/l10n/app_localizations.dart';

/// Standardized exception class for handling all API and network errors,
/// localized for the user interface.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final String? email;

  ApiException(this.message, {this.statusCode, this.code, this.email});

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
          statusCode: dioException.response?.statusCode,
        );
      case DioExceptionType.connectionTimeout:
        return ApiException(
          l10n.errorConnectionTimeout,
          statusCode: dioException.response?.statusCode,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          l10n.errorReceiveTimeout,
          statusCode: dioException.response?.statusCode,
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
          statusCode: dioException.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          l10n.errorNoInternet,
          statusCode: dioException.response?.statusCode,
        );
      default:
        return ApiException(
          l10n.errorUnexpected,
          statusCode: dioException.response?.statusCode,
        );
    }
  }

  static ApiException _handleError(
    int? statusCode,
    dynamic errorData,
    AppLocalizations l10n,
  ) {
    if (statusCode == null) {
      return ApiException(l10n.errorUnknownStatus);
    }

    String serverMessage = _extractMessage(errorData);
    String? errorCode;
    String? errorEmail;

    if (errorData is Map<String, dynamic>) {
      errorCode = errorData['code']?.toString();
      if (errorData['email'] != null) {
        errorEmail = errorData['email'].toString();
      }
    }

    // Intercept raw English backend messages and translate them via l10n
    final String lowerMsg = serverMessage.toLowerCase();

    if (lowerMsg.contains('invalid or missing verification code') ||
        lowerMsg.contains('invalid otp')) {
      serverMessage = l10n.invalidOtp;
    } else if (errorCode == 'EMAIL_NOT_VERIFIED' ||
        lowerMsg.contains('email is not verified')) {
      serverMessage = l10n.awaitingVerificationSubtitle;
    } else if (errorCode == 'campaign_paused') {
      serverMessage = l10n.couponCampaignPaused;
    } else if (errorCode == 'coupon_exhausted' ||
        errorCode == 'invalid_coupon') {
      serverMessage = l10n.couponExhausted;
    } else if (errorCode == 'package_coupon_prohibited') {
      // ARCHITECTURE FIX: Catch points package security error
      serverMessage = l10n.couponProhibitedForPackages;
    } else if (serverMessage.isEmpty) {
      switch (statusCode) {
        case 400:
          serverMessage = l10n.errorBadRequest;
          break;
        case 401:
          serverMessage = l10n.errorUnauthorized;
          break;
        case 403:
          serverMessage = l10n.errorForbidden;
          break;
        case 404:
          serverMessage = l10n.errorNotFound;
          break;
        case 422:
          serverMessage = l10n.errorValidation;
          break;
        case 500:
          serverMessage = l10n.errorInternalServer;
          break;
        case 502:
          serverMessage = l10n.errorBadGateway;
          break;
        default:
          serverMessage = l10n.errorOops;
      }
    }

    return ApiException(
      serverMessage,
      statusCode: statusCode,
      code: errorCode,
      email: errorEmail,
    );
  }

  static String _extractMessage(dynamic errorData) {
    if (errorData is Map<String, dynamic>) {
      if (errorData.containsKey('message') && errorData['message'] != null) {
        return errorData['message'].toString();
      } else if (errorData.containsKey('detail') &&
          errorData['detail'] != null) {
        return errorData['detail'].toString();
      } else {
        // Extract validation list errors
        final List<String> fieldErrors = [];
        errorData.forEach((key, value) {
          if (key == 'code' || key == 'email') return;
          if (value is List && value.isNotEmpty) {
            fieldErrors.add(value.first.toString());
          } else if (value is String) {
            fieldErrors.add(value);
          }
        });
        if (fieldErrors.isNotEmpty) return fieldErrors.join('\n');
      }
    }
    return '';
  }

  @override
  String toString() => message;
}
