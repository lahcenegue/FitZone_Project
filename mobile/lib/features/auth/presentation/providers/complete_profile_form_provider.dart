import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/complete_profile_request_model.dart';

part 'complete_profile_form_provider.g.dart';

class CompleteProfileFormState {
  final String? realFaceImagePath;
  final String? idCardImagePath;
  final String? formError;

  CompleteProfileFormState({
    this.realFaceImagePath,
    this.idCardImagePath,
    this.formError,
  });

  bool get isValid => realFaceImagePath != null && idCardImagePath != null;

  CompleteProfileFormState copyWith({
    String? realFaceImagePath,
    String? idCardImagePath,
    String? formError,
    bool clearFormError = false,
  }) {
    return CompleteProfileFormState(
      realFaceImagePath: realFaceImagePath ?? this.realFaceImagePath,
      idCardImagePath: idCardImagePath ?? this.idCardImagePath,
      formError: clearFormError ? null : (formError ?? this.formError),
    );
  }
}

@riverpod
class CompleteProfileForm extends _$CompleteProfileForm {
  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger('CompleteProfileForm');

  @override
  CompleteProfileFormState build() {
    // Initial clean state, only handling images now
    return CompleteProfileFormState();
  }

  Future<void> pickIdCardImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      state = state.copyWith(idCardImagePath: image.path, clearFormError: true);
    }
  }

  Future<void> pickFaceImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null) {
      state = state.copyWith(
        realFaceImagePath: image.path,
        clearFormError: true,
      );
    }
  }

  bool validateAll(AppLocalizations l10n) {
    if (state.idCardImagePath == null || state.realFaceImagePath == null) {
      state = state.copyWith(formError: l10n.imagesRequiredError);
      return false;
    }
    return state.isValid;
  }

  CompleteProfileRequestModel toRequestModel() {
    return CompleteProfileRequestModel(
      realFaceImagePath: state.realFaceImagePath!,
      idCardImagePath: state.idCardImagePath!,
    );
  }
}
