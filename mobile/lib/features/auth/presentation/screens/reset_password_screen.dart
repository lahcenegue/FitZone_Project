import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/premium_alert_banner.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
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

  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
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
        context.go(RoutePaths.login);
      }
    } catch (e) {
      if (mounted) _showSnackBar(context, e.toString(), colors.error);
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

              // ARCHITECTURE FIX: Unified Premium Alert Banner
              PremiumAlertBanner(
                colors: colors,
                themeColor: colors.primary,
                icon: Icons.password_rounded,
                title: l10n.resetPasswordTitle,
                subtitle: l10n.resetPasswordSubtitle,
              ),
              SizedBox(height: Dimensions.spacingExtraLarge),

              // ARCHITECTURE FIX: Premium Card Wrapper
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
                        fillColor: colors.background,
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
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingLarge),

                    PremiumTextField(
                      label: l10n.newPassword,
                      hintText: '••••••••',
                      controller: _newPasswordController,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _isNewPasswordObscured,
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
                    ),
                    SizedBox(height: Dimensions.spacingMedium),

                    PremiumTextField(
                      label: l10n.confirmNewPassword,
                      hintText: '••••••••',
                      controller: _confirmPasswordController,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _isConfirmPasswordObscured,
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
                    ),
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              SizedBox(
                width: double.infinity,
                height: Dimensions.buttonHeight * 1.2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: colors.primary.withOpacity(0.4),
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
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3.0,
                        )
                      : Text(
                          l10n.verifyAndReset,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
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
}
