/// Represents the authenticated user profile.
class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String gender;
  final String? avatar;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final bool isActive;
  final bool isVerified;
  final int pointsBalance;
  final bool profileIsComplete;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.gender,
    this.avatar,
    required this.address,
    required this.city,
    this.lat,
    this.lng,
    required this.isActive,
    required this.isVerified,
    required this.pointsBalance,
    required this.profileIsComplete,
  });

  /// Creates a UserModel from a JSON map returned by the API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      avatar: json['avatar'] as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      pointsBalance: json['points_balance'] as int? ?? 0,
      profileIsComplete: json['profile_is_complete'] as bool? ?? false,
    );
  }
}
