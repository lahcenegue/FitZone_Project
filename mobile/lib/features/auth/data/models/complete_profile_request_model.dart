import 'package:dio/dio.dart';

/// Represents the data and files required to complete a user's profile.
class CompleteProfileRequestModel {
  final String realFaceImagePath;
  final String idCardImagePath;

  CompleteProfileRequestModel({
    required this.realFaceImagePath,
    required this.idCardImagePath,
  });

  /// Converts the model into a Dio FormData object for multipart/form-data upload.
  Future<FormData> toFormData() async {
    final FormData formData = FormData();

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
