import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../data/models/auth_response_model.dart';
import '../../data/models/complete_profile_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_api_service.dart';

part 'auth_provider.g.dart';

/// Provides the AuthApiService instance with the globally configured Dio client.
@riverpod
AuthApiService authApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthApiService(dio);
}

/// Manages the authentication state and operations.
@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<UserModel?> build() {
    return const AsyncData(null);
  }

  /// Registers a new user.
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

  /// Logs in an existing user and stores their tokens.
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

      state = AsyncData(response.user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Verifies the user's email via OTP.
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

      state = AsyncData(response.user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Resends the OTP verification code.
  Future<void> resendOtp(String email) async {
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      await authService.resendOtp(email);
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  /// Completes the user's profile.
  Future<void> completeProfile(CompleteProfileRequestModel request) async {
    state = const AsyncLoading();
    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      final UserModel updatedUser = await authService.completeProfile(request);
      state = AsyncData(updatedUser);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Logs out the current user by clearing tokens and resetting the state.
  Future<void> logout() async {
    try {
      // Clear secure storage (Tokens)
      await ref.read(secureStorageServiceProvider).clearAll();
      // Reset user state to null
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
