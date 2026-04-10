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

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final Logger _logger = Logger('CompleteProfileScreen');

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
                leading: Container(
                  padding: EdgeInsets.all(Dimensions.spacingSmall),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: colors.primary,
                  ),
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
                leading: Container(
                  padding: EdgeInsets.all(Dimensions.spacingSmall),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: colors.primary,
                  ),
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

    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null && user.profileIsComplete) {
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
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Dimensions.spacingMedium),

              // Premium Info Banner
              Container(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withOpacity(0.15),
                      colors.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    Dimensions.borderRadiusLarge,
                  ),
                  border: Border.all(color: colors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Dimensions.spacingSmall),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        color: colors.primary,
                      ),
                    ),
                    SizedBox(width: Dimensions.spacingMedium),
                    Expanded(
                      child: Text(
                        l10n.completeProfileSubtitle,
                        style: TextStyle(
                          fontSize: Dimensions.fontBodyMedium,
                          color: colors.textPrimary,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge),

              Text(
                l10n.identityVerification,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: Dimensions.spacingMedium),

              // KYC Task List Style
              _buildDocumentTaskCard(
                title: l10n.idCardImage,
                subtitle: l10n.uploadIdCard,
                icon: Icons.badge_rounded,
                imagePath: formState.idCardImagePath,
                colors: colors,
                onTap: () => _showImageSourceActionSheet(
                  context,
                  colors,
                  l10n,
                  (source) => ref
                      .read(completeProfileFormProvider.notifier)
                      .pickIdCardImage(source),
                ),
              ),

              SizedBox(height: Dimensions.spacingMedium),

              _buildDocumentTaskCard(
                title: l10n.faceImage,
                subtitle: l10n.uploadFaceImage,
                icon: Icons.face_retouching_natural_rounded,
                imagePath: formState.realFaceImagePath,
                colors: colors,
                onTap: () => _showImageSourceActionSheet(
                  context,
                  colors,
                  l10n,
                  (source) => ref
                      .read(completeProfileFormProvider.notifier)
                      .pickFaceImage(source),
                ),
              ),

              if (formState.formError != null) ...[
                SizedBox(height: Dimensions.spacingLarge),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingMedium,
                    vertical: Dimensions.spacingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadius,
                    ),
                    border: Border.all(color: colors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_rounded,
                        color: colors.error,
                        size: Dimensions.iconMedium,
                      ),
                      SizedBox(width: Dimensions.spacingSmall),
                      Expanded(
                        child: Text(
                          formState.formError!,
                          style: TextStyle(
                            color: colors.error,
                            fontSize: Dimensions.fontBodyMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              _buildSubmitButton(l10n, formState, authState, colors),
              SizedBox(height: Dimensions.spacingExtraLarge),
            ],
          ),
        ),
      ),
    );
  }

  /// Out-of-the-box Professional KYC Card Design
  Widget _buildDocumentTaskCard({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(Dimensions.spacingMedium),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: hasImage
                ? Colors.green.withOpacity(0.5)
                : colors.iconGrey.withOpacity(0.15),
            width: hasImage ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: hasImage
                  ? Colors.green.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail or Icon Area with Animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: hasImage
                  ? Container(
                      key: const ValueKey('image'),
                      width: Dimensions.customButtonSize * 1.2,
                      height: Dimensions.customButtonSize * 1.2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadius,
                        ),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: FileImage(File(imagePath)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Transform.translate(
                          offset: const Offset(4, 4),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey('icon'),
                      width: Dimensions.customButtonSize * 1.2,
                      height: Dimensions.customButtonSize * 1.2,
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(
                          Dimensions.borderRadius,
                        ),
                        border: Border.all(
                          color: colors.iconGrey.withOpacity(0.1),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: colors.primary,
                        size: Dimensions.iconLarge,
                      ),
                    ),
            ),

            SizedBox(width: Dimensions.spacingLarge),

            // Text Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyLarge,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingTiny),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodySmall,
                      color: hasImage ? Colors.green : colors.textSecondary,
                      fontWeight: hasImage
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            Container(
              padding: EdgeInsets.all(Dimensions.spacingSmall),
              decoration: BoxDecoration(
                color: hasImage
                    ? colors.background
                    : colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasImage ? Icons.edit_rounded : Icons.add_rounded,
                color: hasImage ? colors.textSecondary : colors.primary,
                size: Dimensions.iconMedium,
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
    final bool isEnabled = formState.isValid && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: Dimensions.buttonHeight * 1.2,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? colors.primary
              : colors.iconGrey.withOpacity(0.3),
          foregroundColor: Colors.white,
          elevation: isEnabled ? 4 : 0,
          shadowColor: colors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
        ),
        onPressed: isEnabled
            ? () {
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
              }
            : null,
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
