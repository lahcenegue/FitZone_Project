import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/presentation/widgets/premium_alert_banner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/auth_api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/change_password_form_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final Logger _logger = Logger('ChangePasswordScreen');
  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  Future<void> _submit(AppLocalizations l10n, AppColors colors) async {
    if (!ref.read(changePasswordFormProvider.notifier).validateAll(l10n))
      return;

    setState(() => _isLoading = true);

    try {
      final formState = ref.read(changePasswordFormProvider);
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(formState.oldPassword, formState.newPassword);

      if (mounted) {
        _showSnackBar(context, l10n.passwordChangedSuccessfully, Colors.green);
        context.pop();
      }
    } catch (error) {
      _logger.warning('Failed to change password: $error');
      if (mounted) {
        final String message = error is AuthException
            ? error.getLocalizedMessage(l10n)
            : error.toString();
        _showSnackBar(context, message, colors.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final formState = ref.watch(changePasswordFormProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.changePassword,
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
              // ARCHITECTURE FIX: Using the unified Design System Component
              PremiumAlertBanner(
                colors: colors,
                themeColor: colors.primary,
                icon: Icons.security_rounded,
                subtitle: l10n.changePasswordSubtitle,
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
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPasswordField(
                      label: l10n.oldPassword,
                      value: formState.oldPassword,
                      errorText: formState.oldPasswordError,
                      isObscured: _isOldPasswordObscured,
                      onToggle: () => setState(
                        () => _isOldPasswordObscured = !_isOldPasswordObscured,
                      ),
                      onChanged: (val) => ref
                          .read(changePasswordFormProvider.notifier)
                          .updateOldPassword(val, l10n),
                      colors: colors,
                    ),
                    SizedBox(height: Dimensions.spacingLarge),
                    Divider(color: colors.iconGrey.withOpacity(0.1)),
                    SizedBox(height: Dimensions.spacingLarge),
                    _buildPasswordField(
                      label: l10n.newPassword,
                      value: formState.newPassword,
                      errorText: formState.newPasswordError,
                      isObscured: _isNewPasswordObscured,
                      onToggle: () => setState(
                        () => _isNewPasswordObscured = !_isNewPasswordObscured,
                      ),
                      onChanged: (val) => ref
                          .read(changePasswordFormProvider.notifier)
                          .updateNewPassword(val, l10n),
                      colors: colors,
                    ),
                    SizedBox(height: Dimensions.spacingLarge),
                    _buildPasswordField(
                      label: l10n.confirmNewPassword,
                      value: formState.confirmPassword,
                      errorText: formState.confirmPasswordError,
                      isObscured: _isConfirmPasswordObscured,
                      onToggle: () => setState(
                        () => _isConfirmPasswordObscured =
                            !_isConfirmPasswordObscured,
                      ),
                      onChanged: (val) => ref
                          .read(changePasswordFormProvider.notifier)
                          .updateConfirmPassword(val, l10n),
                      colors: colors,
                    ),
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              _buildSubmitButton(l10n, formState, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String value,
    required String? errorText,
    required bool isObscured,
    required VoidCallback onToggle,
    required Function(String) onChanged,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: Dimensions.fontBodyMedium,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          initialValue: value,
          obscureText: isObscured,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: colors.iconGrey,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: colors.iconGrey,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: colors.background,
            errorText: errorText,
            errorMaxLines: 2,
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
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    AppLocalizations l10n,
    ChangePasswordFormState formState,
    AppColors colors,
  ) {
    final bool isEnabled = formState.isValid && !_isLoading;

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
        onPressed: isEnabled ? () => _submit(l10n, colors) : null,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                l10n.saveChanges,
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
