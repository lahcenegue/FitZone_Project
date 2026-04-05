/// Represents the authenticated user profile.
class UserModel {
  final String email;
  final String fullName;
  final String gender;
  final String city;
  final bool profileIsComplete;

  UserModel({
    required this.email,
    required this.fullName,
    required this.gender,
    required this.city,
    required this.profileIsComplete,
  });

  /// Creates a UserModel from a JSON map returned by the API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      city: json['city'] as String? ?? '',
      profileIsComplete: json['profile_is_complete'] as bool? ?? false,
    );
  }
}
