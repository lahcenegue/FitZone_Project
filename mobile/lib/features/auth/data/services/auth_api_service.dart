import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

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

  /// Parses Dio exceptions into user-friendly AuthExceptions.
  AuthException _handleDioError(DioException error) {
    if (error.response != null) {
      // The server received the request and responded with a status code
      // outside of the 2xx range. Extract the error message from the API.
      final dynamic data = error.response?.data;
      String errorMessage = 'Server error occurred.';

      if (data is Map<String, dynamic>) {
        // Handle common Django REST Framework error formats
        if (data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        } else if (data.containsKey('email')) {
          errorMessage = 'Email: ${data['email'].toString()}';
        } else {
          errorMessage = 'Invalid registration data provided.';
        }
      }
      return AuthException(errorMessage);
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AuthException('Connection timed out. Please check your internet.');
    } else {
      return AuthException('Network error. Please try again later.');
    }
  }
}
