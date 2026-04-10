import 'package:dio/dio.dart';
import 'package:fitzone/core/storage/storage_provider.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../data/models/auth_response_model.dart';
import '../../data/models/complete_profile_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_api_service.dart';

part 'auth_provider.g.dart';

@riverpod
AuthApiService authApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthApiService(dio);
}

@riverpod
class AuthController extends _$AuthController {
  static final Logger _logger = Logger('AuthController');

  @override
  AsyncValue<UserModel?> build() {
    final cachedUser = ref.read(storageServiceProvider).getCachedUser();
    return AsyncData(cachedUser);
  }

  Future<void> registerUser(RegisterRequestModel request) async {
    state = const AsyncLoading();
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      final UserModel user = await authService.register(request);
      state = AsyncData(user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      final AuthResponseModel response = await authService.login(
        email,
        password,
      );

      await ref
          .read(secureStorageServiceProvider)
          .saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );

      await ref.read(storageServiceProvider).cacheUser(response.user);
      state = AsyncData(response.user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> verifyEmail(String otp) async {
    state = const AsyncLoading();
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      final AuthResponseModel response = await authService.verifyEmail(otp);

      await ref
          .read(secureStorageServiceProvider)
          .saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );

      await ref.read(storageServiceProvider).cacheUser(response.user);
      state = AsyncData(response.user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      await authService.resendOtp(email);
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<void> completeProfile(CompleteProfileRequestModel request) async {
    state = const AsyncLoading();
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      final UserModel updatedUser = await authService.completeProfile(request);

      await ref.read(storageServiceProvider).cacheUser(updatedUser);
      state = AsyncData(updatedUser);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Logs out securely by sending the refresh token to the blacklist
  /// before clearing local data.
  Future<void> logout() async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final refreshToken = await secureStorage.getRefreshToken();

      if (refreshToken != null) {
        final authService = ref.read(authApiServiceProvider);
        await authService.logout(refreshToken);
      }
    } catch (error) {
      _logger.warning('Logout API failed, proceeding with local logout', error);
    } finally {
      await ref.read(secureStorageServiceProvider).clearAll();
      await ref.read(storageServiceProvider).clearCachedUser();
      state = const AsyncData(null);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      await authService.requestPasswordReset(email);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> confirmPasswordReset(
    String email,
    String otp,
    String newPassword,
  ) async {
    state = const AsyncLoading();
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      await authService.confirmPasswordReset(email, otp, newPassword);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      await authService.changePassword(oldPassword, newPassword);
    } catch (error) {
      rethrow; // Rethrow to handle it inside the specific UI screen
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      await authService.deleteAccount(password);

      // If successful, clear everything locally
      await ref.read(secureStorageServiceProvider).clearAll();
      await ref.read(storageServiceProvider).clearCachedUser();
      state = const AsyncData(null);
    } catch (error) {
      rethrow;
    }
  }

  Future<String?> uploadAvatarToApi(String imagePath) async {
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      return await authService.uploadUserAvatar(imagePath);
    } catch (error) {
      return null;
    }
  }

  void updateAvatarStateAndCache(String newAvatarUrl) {
    if (state.value != null) {
      final UserModel updatedUser = state.value!.copyWith(avatar: newAvatarUrl);
      state = AsyncData(updatedUser);
      ref.read(storageServiceProvider).cacheUser(updatedUser);
    }
  }

  void updateUserState(UserModel user) {
    state = AsyncData(user);
    ref.read(storageServiceProvider).cacheUser(user);
  }

  Future<bool> updateProfileData({
    required Map<String, dynamic> updateData,
    String? newFaceImagePath,
    String? newIdImagePath,
  }) async {
    try {
      dynamic dataToSend;

      if (newFaceImagePath != null || newIdImagePath != null) {
        final formData = FormData.fromMap(updateData);
        if (newFaceImagePath != null) {
          formData.files.add(
            MapEntry(
              'real_face_image',
              await MultipartFile.fromFile(newFaceImagePath),
            ),
          );
        }
        if (newIdImagePath != null) {
          formData.files.add(
            MapEntry(
              'id_card_image',
              await MultipartFile.fromFile(newIdImagePath),
            ),
          );
        }
        dataToSend = formData;
      } else {
        dataToSend = updateData;
      }

      final AuthApiService authService = ref.read(authApiServiceProvider);
      final Map<String, dynamic> response = await authService.updateProfile(
        dataToSend,
      );
      final UserModel updatedUser = UserModel.fromJson(
        response['user'] as Map<String, dynamic>,
      );

      updateUserState(updatedUser);
      return true;
    } catch (error) {
      return false;
    }
  }
}
