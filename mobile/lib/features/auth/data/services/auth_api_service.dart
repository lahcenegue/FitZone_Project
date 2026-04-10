import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/complete_profile_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  final String? code;
  final String? email;

  AuthException(this.message, {this.code, this.email});

  @override
  String toString() => message;
}

/// Service responsible for handling authentication API requests.
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
      _logger.info('Registration successful for: ${request.email}');
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.severe('Registration failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe('Unexpected registration error', e, stackTrace);
      throw AuthException('An unexpected error occurred during registration.');
    }
  }

  Future<AuthResponseModel> login(String email, String password) async {
    try {
      _logger.info('Attempting to login user: $email');
      final Response response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      _logger.info('Login successful for: $email');
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.severe('Login failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe('Unexpected login error', e, stackTrace);
      throw AuthException('An unexpected error occurred during login.');
    }
  }

  Future<AuthResponseModel> verifyEmail(String otp) async {
    try {
      _logger.info('Attempting to verify email with OTP.');
      final Response response = await _dio.post(
        ApiConstants.verifyEmail,
        data: {'otp': otp},
      );
      _logger.info('Email verified successfully.');
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.severe('Email verification failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe('Unexpected verification error', e, stackTrace);
      throw AuthException(
        'An unexpected error occurred during email verification.',
      );
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      _logger.info('Requesting new OTP for: $email');
      await _dio.post(ApiConstants.resendVerification, data: {'email': email});
      _logger.info('OTP resent successfully.');
    } on DioException catch (e) {
      _logger.severe('Resend OTP failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe('Unexpected resend error', e, stackTrace);
      throw AuthException(
        'An unexpected error occurred while resending the OTP.',
      );
    }
  }

  Future<UserModel> completeProfile(CompleteProfileRequestModel request) async {
    try {
      _logger.info('Attempting to complete user profile.');
      final FormData formData = await request.toFormData();
      final Response response = await _dio.post(
        ApiConstants.completeProfile,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      _logger.info('Profile completed successfully.');
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.severe('Profile completion failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe(
        'Unexpected error during profile completion',
        e,
        stackTrace,
      );
      throw AuthException('An unexpected error occurred while uploading data.');
    }
  }

  AuthException _handleDioError(DioException error) {
    if (error.response != null) {
      final dynamic data = error.response?.data;
      String errorMessage = 'Server error occurred.';
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
            errorMessage = 'Invalid request data provided.';
          }
        }
      }
      return AuthException(errorMessage, code: errorCode, email: errorEmail);
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AuthException('Connection timed out. Please check your network.');
    } else {
      return AuthException('Network error. Please try again later.');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      _logger.info('Requesting password reset for: $email');
      await _dio.post(
        ApiConstants.requestPasswordReset,
        data: {'email': email},
      );
      _logger.info('Password reset request completed.');
    } on DioException catch (e) {
      _logger.severe('Password reset request failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error', e, stackTrace);
      throw AuthException('An unexpected error occurred.');
    }
  }

  Future<void> confirmPasswordReset(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      _logger.info('Confirming password reset for: $email');
      await _dio.post(
        ApiConstants.confirmPasswordReset,
        data: {'email': email, 'otp': otp, 'new_password': newPassword},
      );
      _logger.info('Password reset confirmed successfully.');
    } on DioException catch (e) {
      _logger.severe('Password reset confirmation failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error', e, stackTrace);
      throw AuthException('An unexpected error occurred.');
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

  /// ARCHITECTURE FIX: Accepts dynamic data (Map or FormData) to support unified updates
  Future<Map<String, dynamic>> updateProfile(dynamic updateData) async {
    try {
      _logger.info('Attempting to update user profile (Mixed Data).');
      final Response response = await _dio.patch(
        ApiConstants.updateProfile,
        data: updateData,
      );
      _logger.info('Profile updated successfully.');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.severe('Profile update failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe('Unexpected profile update error', e, stackTrace);
      throw AuthException(
        'An unexpected error occurred while updating the profile.',
      );
    }
  }
}
