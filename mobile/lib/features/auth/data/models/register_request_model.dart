class RegisterRequestModel {
  final String email;
  final String password;
  final String fullName;
  final String gender;
  final String city;
  final String phoneNumber;
  final String address;
  final double lat;
  final double lng;

  RegisterRequestModel({
    required this.email,
    required this.password,
    required this.fullName,
    required this.gender,
    required this.city,
    required this.phoneNumber,
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'full_name': fullName,
      'gender': gender,
      'city': city,
      'phone_number': phoneNumber,
      'address': address,
      'lat': lat,
      'lng': lng,
    };
  }
}
