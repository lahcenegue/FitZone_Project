import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
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

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  late AnimationController _cursorController;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;
  bool _isFocused = false;
  String? _otpErrorText;

  @override
  void initState() {
    super.initState();

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _otpFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _otpFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _otpFocusNode.dispose();
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
      setState(() => _otpErrorText = l10n.invalidOtp);
      return;
    }

    if (newPassword.isEmpty || newPassword != confirmPassword) {
      _showSnackBar(context, l10n.passwordsDoNotMatch, colors.error);
      return;
    }

    setState(() {
      _isLoading = true;
      _otpErrorText = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .confirmPasswordReset(widget.email, otp, newPassword);

      if (!mounted) return;
      _showSnackBar(context, l10n.resetPasswordSuccess, colors.success);
      context.go(RoutePaths.login);
    } catch (e) {
      if (!mounted) return;
      final String message = e is DioException
          ? ApiException.fromDioException(e, l10n).message
          : e.toString();
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

  // ARCHITECTURE FIX: Embedded the elegant Premium Continuous OTP Input
  Widget _buildPremiumContinuousOtpInput(AppColors colors) {
    final String text = _otpController.text;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: Dimensions.buttonHeight * 1.5,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            border: Border.all(
              color: _otpErrorText != null
                  ? colors.error
                  : (_isFocused
                        ? colors.primary
                        : colors.iconGrey.withValues(alpha: 0.1)),
              width: _isFocused ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(6, (index) {
              final bool isCurrentPos = text.length == index && _isFocused;
              final bool hasValue = text.length > index;
              final String digit = hasValue ? text[index] : '0';

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCurrentPos)
                    FadeTransition(
                      opacity: _cursorController,
                      child: Container(
                        width: 2,
                        height: Dimensions.iconLarge,
                        color: colors.primary,
                      ),
                    ),
                  if (isCurrentPos) SizedBox(width: Dimensions.spacingTiny),
                  Text(
                    digit,
                    style: TextStyle(
                      fontSize: Dimensions.fontHeading1,
                      fontWeight: FontWeight.w800,
                      color: hasValue
                          ? colors.textPrimary
                          : colors.iconGrey.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        Positioned.fill(
          child: TextField(
            focusNode: _otpFocusNode,
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            cursorColor: Colors.transparent,
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            decoration: const InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: "",
              fillColor: Colors.transparent,
            ),
            onChanged: (val) {
              setState(() {
                if (_otpErrorText != null) _otpErrorText = null;
              });
              if (val.length == 6) {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);

    final bool isEnabled = _otpController.text.length == 6 && !_isLoading;

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

              PremiumAlertBanner(
                colors: colors,
                themeColor: colors.primary,
                icon: Icons.password_rounded,
                title: l10n.resetPasswordTitle,
                subtitle: l10n.resetPasswordSubtitle,
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
                    Text(
                      l10n.enterOtpTitle,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodyLarge,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingSmall),

                    // The unified Premium OTP input field
                    _buildPremiumContinuousOtpInput(colors),

                    if (_otpErrorText != null)
                      Padding(
                        padding: EdgeInsets.only(top: Dimensions.spacingMedium),
                        child: Center(
                          child: Text(
                            _otpErrorText!,
                            style: TextStyle(
                              color: colors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: Dimensions.fontBodyMedium,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: Dimensions.spacingLarge),
                    Divider(color: colors.iconGrey.withValues(alpha: 0.1)),
                    SizedBox(height: Dimensions.spacingLarge),

                    PremiumTextField(
                      label: l10n.newPassword,
                      hintText: l10n.passwordHint,
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
                      onChanged: (val) => setState(() {}),
                    ),
                    SizedBox(height: Dimensions.spacingMedium),

                    PremiumTextField(
                      label: l10n.confirmNewPassword,
                      hintText: l10n.passwordHint,
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
                      onChanged: (val) => setState(() {}),
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
                    backgroundColor: isEnabled
                        ? colors.primary
                        : colors.iconGrey.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    elevation: isEnabled ? 4 : 0,
                    shadowColor: colors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadiusLarge,
                      ),
                    ),
                  ),
                  onPressed: isEnabled
                      ? () => _handleConfirmReset(l10n, colors)
                      : null,
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
