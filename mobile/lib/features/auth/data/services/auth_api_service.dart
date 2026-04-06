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

  /// Registers a new user with the provided details.
  Future<UserModel> register(RegisterRequestModel request) async {
    try {
      _logger.info('Attempting to register user: ${request.email}');
      final Response response = await _dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );
      _logger.info('Registration successful for: ${request.email}');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.severe('Registration failed', e, e.stackTrace);
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      _logger.severe('Unexpected registration error', e, stackTrace);
      throw AuthException('An unexpected error occurred during registration.');
    }
  }

  /// Authenticates a user and returns tokens and profile data.
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

  /// Verifies the user email using the provided 6-digit OTP.
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

  /// Requests a new OTP code to be sent to the user's email.
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

  /// Completes the user profile by uploading sensitive data and images.
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

  /// Parses Dio exceptions into user-friendly AuthExceptions with detailed codes.
  AuthException _handleDioError(DioException error) {
    if (error.response != null) {
      final dynamic data = error.response?.data;
      String errorMessage = 'Server error occurred.';
      String? errorCode;
      String? errorEmail;

      if (data is Map<String, dynamic>) {
        errorCode = data['code']?.toString();
        errorEmail = data['email']?.toString();

        if (data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        } else if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else {
          errorMessage = 'Invalid request data provided.';
        }
      }
      return AuthException(errorMessage, code: errorCode, email: errorEmail);
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AuthException('Connection timed out. Please check your internet.');
    } else {
      return AuthException('Network error. Please try again later.');
    }
  }

  /// Requests a password reset OTP for the given email.
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
      _logger.severe(
        'Unexpected error during password reset request',
        e,
        stackTrace,
      );
      throw AuthException('An unexpected error occurred.');
    }
  }

  /// Confirms the password reset with OTP and new password.
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
      _logger.severe(
        'Unexpected error during password reset confirmation',
        e,
        stackTrace,
      );
      throw AuthException('An unexpected error occurred.');
    }
  }
}
