import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_provider.dart';
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

/// Manages the authentication state and operations (e.g., Registration).
@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<UserModel?> build() {
    // Initial state: not loading, no user data yet.
    return const AsyncData(null);
  }

  /// Registers a new user and updates the state accordingly.
  Future<void> registerUser(RegisterRequestModel request) async {
    state = const AsyncLoading();

    try {
      final AuthApiService authService = ref.read(authApiServiceProvider);
      final UserModel user = await authService.register(request);

      state = AsyncData(user);
    } catch (error, stackTrace) {
      // The AuthException message will be caught here and passed to the UI
      state = AsyncError(error, stackTrace);
    }
  }
}
