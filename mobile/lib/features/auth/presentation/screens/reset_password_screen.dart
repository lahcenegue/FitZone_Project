import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmReset(
    AppLocalizations l10n,
    AppColors colors,
  ) async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.length != 6) {
      _showSnackBar(context, l10n.invalidOtp, colors.error);
      return;
    }
    if (newPassword.isEmpty || newPassword != confirmPassword) {
      _showSnackBar(context, l10n.passwordsDoNotMatch, colors.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .confirmPasswordReset(widget.email, otp, newPassword);
      if (mounted) {
        _showSnackBar(context, l10n.resetPasswordSuccess, colors.success);
        context.go(
          RoutePaths.login,
        ); // Return to login directly after successful reset
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, e.toString(), colors.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Dimensions.spacingLarge),
              Text(
                l10n.resetPasswordTitle,
                style: TextStyle(
                  fontSize: Dimensions.fontHeading1 * 1.2,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: Dimensions.spacingTiny),
              Text(
                l10n.resetPasswordSubtitle,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyLarge,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: Dimensions.spacingExtraLarge),

              // OTP Input
              Text(
                l10n.otpHint,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyLarge,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: Dimensions.spacingSmall),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: Dimensions.fontHeading1,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 16.0,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: Dimensions.spacingMedium,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadius,
                    ),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
              ),
              SizedBox(height: Dimensions.spacingLarge),

              // New Password Input
              _buildPasswordField(
                l10n.newPassword,
                _newPasswordController,
                colors,
              ),
              SizedBox(height: Dimensions.spacingMedium),

              // Confirm Password Input
              _buildPasswordField(
                l10n.confirmNewPassword,
                _confirmPasswordController,
                colors,
              ),
              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              SizedBox(
                width: double.infinity,
                height: Dimensions.buttonHeight * 1.2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadiusLarge,
                      ),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => _handleConfirmReset(l10n, colors),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.verifyAndReset,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Dimensions.fontBodyLarge,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          controller: controller,
          obscureText: _isPasswordObscured,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(
              color: colors.iconGrey,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: colors.iconGrey,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: colors.iconGrey,
              ),
              onPressed: () =>
                  setState(() => _isPasswordObscured = !_isPasswordObscured),
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
        ),
      ],
    );
  }
}
