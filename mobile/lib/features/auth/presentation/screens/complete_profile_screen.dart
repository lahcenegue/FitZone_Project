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
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data from the authenticated user
    final user = ref.read(authControllerProvider).value;
    if (user != null) {
      _addressController.text = user.address ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
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
        centerTitle: true,
        title: Text(
          l10n.completeProfileTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: Dimensions.fontTitleLarge,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
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
                  color: colors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(
                    Dimensions.borderRadiusLarge,
                  ),
                  border: Border.all(color: colors.primary.withOpacity(0.15)),
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
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge),

              Container(
                padding: EdgeInsets.all(Dimensions.spacingLarge),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(
                    Dimensions.borderRadiusLarge,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhoneField(l10n, formState, colors),
                    SizedBox(height: Dimensions.spacingLarge),

                    _buildAddressField(l10n, formState, colors),
                    SizedBox(height: Dimensions.spacingLarge),

                    Text(
                      l10n.identityVerification,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: Dimensions.fontBodyMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingSmall),
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
                      SizedBox(height: Dimensions.spacingMedium),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.spacingMedium,
                          vertical: Dimensions.spacingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: colors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.borderRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: colors.error,
                              size: Dimensions.iconSmall,
                            ),
                            SizedBox(width: Dimensions.spacingSmall),
                            Expanded(
                              child: Text(
                                formState.formError!,
                                style: TextStyle(
                                  color: colors.error,
                                  fontSize: Dimensions.fontBodySmall,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              _buildSubmitButton(l10n, formState, authState, colors),
              SizedBox(height: Dimensions.spacingExtraLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(
    AppLocalizations l10n,
    CompleteProfileFormState formState,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.phoneNumber,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: Dimensions.fontBodyMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: l10n.phoneNumberHint,
            hintStyle: TextStyle(
              color: colors.iconGrey,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.phone_android_rounded,
              color: colors.iconGrey,
            ),
            filled: true,
            fillColor: colors.background,
            errorText: formState.phoneError,
            contentPadding: EdgeInsets.all(Dimensions.spacingMedium),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              borderSide: BorderSide(color: colors.iconGrey.withOpacity(0.1)),
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
          onChanged: (val) => ref
              .read(completeProfileFormProvider.notifier)
              .updatePhone(val, l10n),
        ),
      ],
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
            color: colors.textSecondary,
            fontSize: Dimensions.fontBodyMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        GestureDetector(
          onTap: () async {
            final dynamic result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapPickerScreen()),
            );

            if (result != null && result is Map<String, dynamic>) {
              _addressController.text = result['address'];
              ref
                  .read(completeProfileFormProvider.notifier)
                  .updateAddress(result['address']);
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: _addressController,
              readOnly: true,
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
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: colors.iconGrey,
                ),
                suffixIcon: Container(
                  margin: EdgeInsets.all(Dimensions.spacingTiny),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadius,
                    ),
                  ),
                  child: Icon(Icons.my_location_rounded, color: colors.primary),
                ),
                filled: true,
                fillColor: colors.background,
                contentPadding: EdgeInsets.all(Dimensions.spacingMedium),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(
                    color: colors.iconGrey.withOpacity(0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.borderRadius),
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
            ),
          ),
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
        height: Dimensions.heightPercent(16).clamp(130.0, 160.0),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
          border: Border.all(
            color: hasImage ? colors.primary : colors.iconGrey.withOpacity(0.2),
            width: hasImage ? 2 : 1,
          ),
          image: hasImage
              ? DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
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
              size: Dimensions.iconLarge * 1.2,
            ),
            SizedBox(height: Dimensions.spacingSmall),
            Text(
              title,
              style: TextStyle(
                color: hasImage ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: Dimensions.fontBodyMedium,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasImage)
              Padding(
                padding: EdgeInsets.only(top: Dimensions.spacingTiny),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: Dimensions.fontBodySmall,
                  ),
                  textAlign: TextAlign.center,
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
      height: Dimensions.buttonHeight * 1.1,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: colors.primary.withOpacity(0.4),
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
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                l10n.submitProfile,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        ),
        margin: EdgeInsets.all(Dimensions.spacingMedium),
      ),
    );
  }
}
