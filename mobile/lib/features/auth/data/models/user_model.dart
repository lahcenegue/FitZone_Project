import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String gender;
  final String? avatar;
  final String? realFaceImage;
  final String? idCardImage;
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
    this.realFaceImage,
    this.idCardImage,
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
    // ARCHITECTURE FIX: Safe parsing using num and tryParse for better robustness
    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      gender: json['gender']?.toString() ?? 'male',
      avatar: json['avatar']?.toString(),
      realFaceImage: json['real_face_image']?.toString(),
      idCardImage: json['id_card_image']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString() ?? '',
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      isActive: json['is_active'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      pointsBalance:
          int.tryParse(json['points_balance']?.toString() ?? '0') ?? 0,
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
      'real_face_image': realFaceImage,
      'id_card_image': idCardImage,
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

  UserModel copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? gender,
    String? avatar,
    String? realFaceImage,
    String? idCardImage,
    String? address,
    String? city,
    double? lat,
    double? lng,
    bool? isActive,
    bool? isVerified,
    int? pointsBalance,
    bool? profileIsComplete,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      avatar: avatar ?? this.avatar,
      realFaceImage: realFaceImage ?? this.realFaceImage,
      idCardImage: idCardImage ?? this.idCardImage,
      address: address ?? this.address,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      profileIsComplete: profileIsComplete ?? this.profileIsComplete,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phoneNumber,
    gender,
    avatar,
    realFaceImage,
    idCardImage,
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
