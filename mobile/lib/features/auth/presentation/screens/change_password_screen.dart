import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/premium_alert_banner.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
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

  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isOldPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n, AppColors colors) async {
    if (!ref.read(changePasswordFormProvider.notifier).validateAll(l10n)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formState = ref.read(changePasswordFormProvider);
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(formState.oldPassword, formState.newPassword);

      if (!mounted) return;
      _showSnackBar(context, l10n.passwordChangedSuccessfully, colors.success);
      context.pop();
    } catch (error) {
      _logger.warning('Failed to change password: $error');
      if (!mounted) return;

      final String message = error is DioException
          ? ApiException.fromDioException(error, l10n).message
          : error.toString();

      _showSnackBar(context, message, colors.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumTextField(
                      label: l10n.oldPassword,
                      hintText: '••••••••',
                      controller: _oldPasswordController,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _isOldPasswordObscured,
                      errorText: formState.oldPasswordError,
                      colors: colors,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isOldPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colors.iconGrey,
                        ),
                        onPressed: () => setState(
                          () =>
                              _isOldPasswordObscured = !_isOldPasswordObscured,
                        ),
                      ),
                      onChanged: (val) => ref
                          .read(changePasswordFormProvider.notifier)
                          .updateOldPassword(val, l10n),
                    ),
                    SizedBox(height: Dimensions.spacingLarge),
                    Divider(color: colors.iconGrey.withValues(alpha: 0.1)),
                    SizedBox(height: Dimensions.spacingLarge),

                    PremiumTextField(
                      label: l10n.newPassword,
                      hintText: '••••••••',
                      controller: _newPasswordController,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _isNewPasswordObscured,
                      errorText: formState.newPasswordError,
                      colors: colors,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colors.iconGrey,
                        ),
                        onPressed: () => setState(
                          () =>
                              _isNewPasswordObscured = !_isNewPasswordObscured,
                        ),
                      ),
                      onChanged: (val) => ref
                          .read(changePasswordFormProvider.notifier)
                          .updateNewPassword(val, l10n),
                    ),
                    SizedBox(height: Dimensions.spacingLarge),

                    PremiumTextField(
                      label: l10n.confirmNewPassword,
                      hintText: '••••••••',
                      controller: _confirmPasswordController,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _isConfirmPasswordObscured,
                      errorText: formState.confirmPasswordError,
                      colors: colors,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colors.iconGrey,
                        ),
                        onPressed: () => setState(
                          () => _isConfirmPasswordObscured =
                              !_isConfirmPasswordObscured,
                        ),
                      ),
                      onChanged: (val) => ref
                          .read(changePasswordFormProvider.notifier)
                          .updateConfirmPassword(val, l10n),
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
              : colors.iconGrey.withValues(alpha: 0.3),
          foregroundColor: Colors.white,
          elevation: isEnabled ? 4 : 0,
          shadowColor: colors.primary.withValues(alpha: 0.4),
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
}
