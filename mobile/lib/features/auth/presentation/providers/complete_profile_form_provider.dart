import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/app_constants.dart';
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
    return CompleteProfileFormState();
  }

  Future<void> pickIdCardImage(ImageSource source) async {
    try {
      _logger.info(
        'Attempting to pick ID card image from source: ${source.name}',
      );
      final XFile? image = await _picker.pickImage(
        source: source,
        // ARCHITECTURE FIX: Pulled from AppConstants instead of magic local variable
        imageQuality: AppConstants.imageCompressionQuality,
      );

      if (image != null) {
        _logger.info('ID card image picked successfully: ${image.path}');
        state = state.copyWith(
          idCardImagePath: image.path,
          clearFormError: true,
        );
      } else {
        _logger.info('ID card image picking was canceled by the user.');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to pick ID card image', e, stackTrace);
    }
  }

  Future<void> pickFaceImage(ImageSource source) async {
    try {
      _logger.info('Attempting to pick face image from source: ${source.name}');
      final XFile? image = await _picker.pickImage(
        source: source,
        // ARCHITECTURE FIX: Pulled from AppConstants
        imageQuality: AppConstants.imageCompressionQuality,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        _logger.info('Face image picked successfully: ${image.path}');
        state = state.copyWith(
          realFaceImagePath: image.path,
          clearFormError: true,
        );
      } else {
        _logger.info('Face image picking was canceled by the user.');
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to pick face image', e, stackTrace);
    }
  }

  bool validateAll(AppLocalizations l10n) {
    if (state.idCardImagePath == null || state.realFaceImagePath == null) {
      _logger.warning('Form validation failed: Missing required images.');
      state = state.copyWith(formError: l10n.imagesRequiredError);
      return false;
    }

    _logger.info('Form validation passed successfully.');
    return state.isValid;
  }

  CompleteProfileRequestModel toRequestModel() {
    return CompleteProfileRequestModel(
      realFaceImagePath: state.realFaceImagePath!,
      idCardImagePath: state.idCardImagePath!,
    );
  }
}
