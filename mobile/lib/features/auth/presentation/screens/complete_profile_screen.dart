import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/auth_intent_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/complete_profile_form_provider.dart';
import '../../../maps/presentation/screens/map_picker_screen.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final Logger _logger = Logger('CompleteProfileScreen');
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _showImageSourceActionSheet(
    BuildContext context,
    AppColors colors,
    AppLocalizations l10n,
    Function(ImageSource) onSourceSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.borderRadiusLarge),
        ),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                child: Text(
                  l10n.selectImageSource,
                  style: TextStyle(
                    fontSize: Dimensions.fontTitleMedium,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_camera_rounded,
                  color: colors.primary,
                ),
                title: Text(
                  l10n.camera,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onSourceSelected(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: colors.primary,
                ),
                title: Text(
                  l10n.gallery,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onSourceSelected(ImageSource.gallery);
                },
              ),
              SizedBox(height: Dimensions.spacingLarge),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final formState = ref.watch(completeProfileFormProvider);
    final authState = ref.watch(authControllerProvider);

    ref.listen<CompleteProfileFormState>(completeProfileFormProvider, (
      previous,
      next,
    ) {
      if (previous?.address != next.address &&
          _addressController.text != next.address) {
        _addressController.text = next.address;
      }
    });

    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            _logger.info('Profile completed successfully.');
            _handleSmartRouting();
          }
        },
        error: (error, stackTrace) {
          _showSnackBar(context, error.toString(), colors.error);
        },
      );
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.completeProfileTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(Dimensions.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  border: Border.all(color: colors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: colors.primary),
                    SizedBox(width: Dimensions.spacingMedium),
                    Expanded(
                      child: Text(
                        l10n.completeProfileSubtitle,
                        style: TextStyle(
                          fontSize: Dimensions.fontBodyMedium,
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Dimensions.spacingExtraLarge),

              _buildCustomTextField(
                label: l10n.phoneNumber,
                hint: l10n.phoneNumberHint,
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                errorText: formState.phoneError,
                colors: colors,
                onChanged: (val) => ref
                    .read(completeProfileFormProvider.notifier)
                    .updatePhone(val, l10n),
              ),
              SizedBox(height: Dimensions.spacingExtraLarge),

              Row(
                children: [
                  Expanded(
                    child: _buildImageUploadCard(
                      title: l10n.idCardImage,
                      subtitle: l10n.uploadIdCard,
                      icon: Icons.badge_outlined,
                      imagePath: formState.idCardImagePath,
                      onTap: () => _showImageSourceActionSheet(
                        context,
                        colors,
                        l10n,
                        (source) => ref
                            .read(completeProfileFormProvider.notifier)
                            .pickIdCardImage(source),
                      ),
                      colors: colors,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingMedium),
                  Expanded(
                    child: _buildImageUploadCard(
                      title: l10n.faceImage,
                      subtitle: l10n.uploadFaceImage,
                      icon: Icons.face_retouching_natural_rounded,
                      imagePath: formState.realFaceImagePath,
                      onTap: () => _showImageSourceActionSheet(
                        context,
                        colors,
                        l10n,
                        (source) => ref
                            .read(completeProfileFormProvider.notifier)
                            .pickFaceImage(source),
                      ),
                      colors: colors,
                    ),
                  ),
                ],
              ),
              if (formState.formError != null) ...[
                SizedBox(height: Dimensions.spacingSmall),
                Text(
                  formState.formError!,
                  style: TextStyle(
                    color: colors.error,
                    fontSize: Dimensions.fontBodyMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              SizedBox(height: Dimensions.spacingExtraLarge),

              _buildAddressField(l10n, formState, colors),

              SizedBox(height: Dimensions.spacingExtraLarge * 2),

              _buildSubmitButton(l10n, formState, authState, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField(
    AppLocalizations l10n,
    CompleteProfileFormState formState,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.addressOptional,
          style: TextStyle(
            fontSize: Dimensions.fontBodyLarge,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          controller: _addressController,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: formState.isFetchingLocation
                ? l10n.fetchingAddress
                : l10n.addressHint,
            hintStyle: TextStyle(
              color: colors.iconGrey,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(Icons.map_outlined, color: colors.iconGrey),
            suffixIcon: formState.isFetchingLocation
                ? Padding(
                    padding: EdgeInsets.all(Dimensions.spacingMedium),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.my_location_rounded,
                      color: colors.primary,
                    ),
                    tooltip: l10n.refreshLocation,
                    onPressed: () async {
                      final dynamic result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapPickerScreen(),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        _addressController.text = result['address'];
                        ref
                            .read(completeProfileFormProvider.notifier)
                            .updateAddress(result['address']);
                      }
                    },
                  ),
            filled: true,
            fillColor: colors.surface,
            contentPadding: EdgeInsets.all(Dimensions.spacingMedium),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          onChanged: (val) =>
              ref.read(completeProfileFormProvider.notifier).updateAddress(val),
        ),
      ],
    );
  }

  void _handleSmartRouting() {
    final intentService = ref.read(authIntentServiceProvider);
    final intent = intentService.getIntent();
    intentService.clearIntent();

    if (intent.type == AuthIntentType.buyGymSubscription) {
      final int id = intent.payload['gym_id'] as int? ?? 0;
      context.go(RoutePaths.gymDetailsPath(id));
    } else {
      context.go(RoutePaths.explore);
    }
  }

  Widget _buildCustomTextField({
    required String label,
    required String hint,
    required IconData icon,
    required AppColors colors,
    required Function(String) onChanged,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Dimensions.fontBodyLarge,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          keyboardType: keyboardType,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colors.iconGrey,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: colors.iconGrey),
            filled: true,
            fillColor: colors.surface,
            errorText: errorText,
            contentPadding: EdgeInsets.all(Dimensions.spacingMedium),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide(color: colors.error, width: 1.5),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? imagePath,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    final bool hasImage = imagePath != null && imagePath.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Dimensions.heightPercent(18).clamp(140.0, 180.0),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: hasImage ? colors.primary : colors.iconGrey.withOpacity(0.3),
            width: hasImage ? 2 : 1,
          ),
          image: hasImage
              ? DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasImage ? Icons.check_circle_rounded : icon,
              color: hasImage ? Colors.white : colors.primary,
              size: Dimensions.iconLarge * 1.5,
            ),
            SizedBox(height: Dimensions.spacingSmall),
            Text(
              title,
              style: TextStyle(
                color: hasImage ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: Dimensions.fontBodyLarge,
              ),
            ),
            if (!hasImage)
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: Dimensions.fontBodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    AppLocalizations l10n,
    CompleteProfileFormState formState,
    AsyncValue<dynamic> authState,
    AppColors colors,
  ) {
    final bool isLoading = authState.isLoading;
    return SizedBox(
      width: double.infinity,
      height: Dimensions.buttonHeight * 1.2,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
        ),
        onPressed: isLoading
            ? null
            : () {
                if (ref
                    .read(completeProfileFormProvider.notifier)
                    .validateAll(l10n)) {
                  final request = ref
                      .read(completeProfileFormProvider.notifier)
                      .toRequestModel();
                  ref
                      .read(authControllerProvider.notifier)
                      .completeProfile(request);
                }
              },
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                l10n.submitProfile,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
