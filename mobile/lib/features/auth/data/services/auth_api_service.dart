import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../../../core/config/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/complete_profile_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

class AuthApiService {
  final Dio _dio;
  static final Logger _logger = Logger('AuthApiService');

  AuthApiService(this._dio);

  Future<UserModel> register(RegisterRequestModel request) async {
    _logger.info('Attempting to register user: ${request.email}');
    final Response response = await _dio.post(
      ApiConstants.register,
      data: request.toJson(),
    );
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<AuthResponseModel> login(String email, String password) async {
    _logger.info('Attempting to login user: $email');
    final Response response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    _logger.info('Attempting to logout and blacklist token.');
    await _dio.post(ApiConstants.logout, data: {'refresh': refreshToken});
    _logger.info('Token blacklisted successfully.');
  }

  Future<AuthResponseModel> verifyEmail(String otp) async {
    final Response response = await _dio.post(
      ApiConstants.verifyEmail,
      data: {'otp': otp},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> resendOtp(String email) async {
    await _dio.post(ApiConstants.resendVerification, data: {'email': email});
  }

  Future<UserModel> completeProfile(CompleteProfileRequestModel request) async {
    final FormData formData = await request.toFormData();
    final Response response = await _dio.post(
      ApiConstants.completeProfile,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.post(ApiConstants.requestPasswordReset, data: {'email': email});
  }

  Future<void> confirmPasswordReset(
    String email,
    String otp,
    String newPassword,
  ) async {
    await _dio.post(
      ApiConstants.confirmPasswordReset,
      data: {'email': email, 'otp': otp, 'new_password': newPassword},
    );
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    _logger.info('Attempting to change password.');
    await _dio.post(
      ApiConstants.changePassword,
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  Future<void> deleteAccount(String password) async {
    _logger.info('Attempting to delete account.');
    await _dio.delete(ApiConstants.deleteAccount, data: {'password': password});
  }

  Future<String?> uploadUserAvatar(String imagePath) async {
    final File file = File(imagePath);
    final String fileName = imagePath.split('/').last;
    final List<int> bytes = await file.readAsBytes();

    final FormData formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await _dio.post(ApiConstants.updateAvatar, data: formData);

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('avatar')) {
        return data['avatar'].toString();
      } else if (data.containsKey('user') && data['user']['avatar'] != null) {
        return data['user']['avatar'].toString();
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfile(dynamic updateData) async {
    final Response response = await _dio.patch(
      ApiConstants.updateProfile,
      data: updateData,
    );
    return response.data as Map<String, dynamic>;
  }
}
