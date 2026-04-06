import 'user_model.dart';

/// Wraps the API response containing both the user profile and JWT tokens.
class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> tokens = json['tokens'] as Map<String, dynamic>;

    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: tokens['access'] as String,
      refreshToken: tokens['refresh'] as String,
    );
  }
}
