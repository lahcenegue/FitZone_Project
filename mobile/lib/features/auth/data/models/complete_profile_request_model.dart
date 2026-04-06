import 'package:dio/dio.dart';

/// Represents the data and files required to complete a user's profile.
class CompleteProfileRequestModel {
  final String phoneNumber;
  final String realFaceImagePath;
  final String idCardImagePath;
  final String? address;
  final double? lat;
  final double? lng;

  CompleteProfileRequestModel({
    required this.phoneNumber,
    required this.realFaceImagePath,
    required this.idCardImagePath,
    this.address,
    this.lat,
    this.lng,
  });

  /// Converts the model into a Dio FormData object for multipart/form-data upload.
  Future<FormData> toFormData() async {
    final Map<String, dynamic> data = {'phone_number': phoneNumber};

    if (address != null && address!.isNotEmpty) {
      data['address'] = address;
    }
    if (lat != null && lng != null) {
      data['lat'] = lat.toString();
      data['lng'] = lng.toString();
    }

    final FormData formData = FormData.fromMap(data);

    // Attach the physical files to the form data
    formData.files.addAll([
      MapEntry(
        'real_face_image',
        await MultipartFile.fromFile(realFaceImagePath),
      ),
      MapEntry('id_card_image', await MultipartFile.fromFile(idCardImagePath)),
    ]);

    return formData;
  }
}
