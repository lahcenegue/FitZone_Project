import 'package:equatable/equatable.dart';

/// Represents the core user data returned from the backend.
class UserModel extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String gender;
  final String? avatar;
  final String? address;
  final String city;
  final double? lat;
  final double? lng;
  final bool isActive;
  final bool isVerified;
  final int pointsBalance;
  final bool profileIsComplete;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.gender,
    this.avatar,
    this.address,
    required this.city,
    this.lat,
    this.lng,
    required this.isActive,
    required this.isVerified,
    required this.pointsBalance,
    required this.profileIsComplete,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      gender: json['gender'] as String,
      avatar: json['avatar'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String,
      lat: json['lat'] as double?,
      lng: json['lng'] as double?,
      isActive: json['is_active'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      pointsBalance: json['points_balance'] as int? ?? 0,
      profileIsComplete: json['profile_is_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'gender': gender,
      'avatar': avatar,
      'address': address,
      'city': city,
      'lat': lat,
      'lng': lng,
      'is_active': isActive,
      'is_verified': isVerified,
      'points_balance': pointsBalance,
      'profile_is_complete': profileIsComplete,
    };
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phoneNumber,
    gender,
    avatar,
    address,
    city,
    lat,
    lng,
    isActive,
    isVerified,
    pointsBalance,
    profileIsComplete,
  ];
}
