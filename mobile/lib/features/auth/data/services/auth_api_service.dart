import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/auth_response_model.dart';
import '../models/complete_profile_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

/// Custom exception for authentication errors with built-in localization support.
class AuthException implements Exception {
  final String message;
  final String? code;
  final String? email;

  AuthException(this.message, {this.code, this.email});

  /// Translates local network error keys to localized strings.
  /// If the message is not a known key, it assumes it's a translated string from the backend.
  String getLocalizedMessage(AppLocalizations l10n) {
    switch (message) {
      case 'errorInternalServer':
        return l10n.errorInternalServer;
      case 'errorValidation':
        return l10n.errorValidation;
      case 'errorConnectionTimeout':
        return l10n.errorConnectionTimeout;
      case 'errorUnexpected':
        return l10n.errorUnexpected;
      default:
        return message; // Message already translated by Django backend
    }
  }

  @override
  String toString() => message;
}

class AuthApiService {
  final Dio _dio;
  static final Logger _logger = Logger('AuthApiService');

  AuthApiService(this._dio);

  Future<UserModel> register(RegisterRequestModel request) async {
    try {
      _logger.info('Attempting to register user: ${request.email}');
      final Response response = await _dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<AuthResponseModel> login(String email, String password) async {
    try {
      _logger.info('Attempting to login user: $email');
      final Response response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      _logger.info('Attempting to logout and blacklist token.');
      await _dio.post(ApiConstants.logout, data: {'refresh': refreshToken});
      _logger.info('Token blacklisted successfully.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<AuthResponseModel> verifyEmail(String otp) async {
    try {
      final Response response = await _dio.post(
        ApiConstants.verifyEmail,
        data: {'otp': otp},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      await _dio.post(ApiConstants.resendVerification, data: {'email': email});
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<UserModel> completeProfile(CompleteProfileRequestModel request) async {
    try {
      final FormData formData = await request.toFormData();
      final Response response = await _dio.post(
        ApiConstants.completeProfile,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post(
        ApiConstants.requestPasswordReset,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<void> confirmPasswordReset(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        ApiConstants.confirmPasswordReset,
        data: {'email': email, 'otp': otp, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      _logger.info('Attempting to change password.');
      await _dio.post(
        ApiConstants.changePassword,
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
      _logger.info('Password changed successfully.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      _logger.info('Attempting to delete account.');
      await _dio.delete(
        ApiConstants.deleteAccount,
        data: {'password': password},
      );
      _logger.info('Account deleted successfully.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  Future<String?> uploadUserAvatar(String imagePath) async {
    try {
      final File file = File(imagePath);
      final String fileName = imagePath.split('/').last;
      final List<int> bytes = await file.readAsBytes();

      final FormData formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        ApiConstants.updateAvatar,
        data: formData,
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('avatar')) {
          return data['avatar'].toString();
        } else if (data.containsKey('user') && data['user']['avatar'] != null) {
          return data['user']['avatar'].toString();
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(dynamic updateData) async {
    try {
      final Response response = await _dio.patch(
        ApiConstants.updateProfile,
        data: updateData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException('errorUnexpected');
    }
  }

  AuthException _handleDioError(DioException error) {
    if (error.response != null) {
      final dynamic data = error.response?.data;
      String errorMessage = 'errorInternalServer'; // Now returns a key
      String? errorCode;
      String? errorEmail;

      if (data is Map<String, dynamic>) {
        errorCode = data['code']?.toString();
        if (data['email'] is String) {
          errorEmail = data['email'].toString();
        }

        if (data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        } else if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else {
          final List<String> fieldErrors = [];
          data.forEach((key, value) {
            if (key == 'code') return;
            if (value is List && value.isNotEmpty) {
              fieldErrors.add(value.first.toString());
            } else if (value is String && key != 'email') {
              fieldErrors.add(value);
            }
          });

          if (fieldErrors.isNotEmpty) {
            errorMessage = fieldErrors.join('\n');
          } else {
            errorMessage = 'errorValidation'; // Return key
          }
        }
      }
      return AuthException(errorMessage, code: errorCode, email: errorEmail);
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AuthException('errorConnectionTimeout'); // Return key
    } else {
      return AuthException('errorUnexpected'); // Return key
    }
  }
}
