import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/presentation/widgets/premium_alert_banner.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/auth_intent_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final Logger _logger = Logger('OtpVerificationScreen');
  final TextEditingController _otpController = TextEditingController();

  Timer? _timer;
  int _cooldownSeconds = 60;
  bool _isResending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend(AppLocalizations l10n, AppColors colors) async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);
    _logger.info('User requested to resend OTP for email: ${widget.email}');

    try {
      await ref.read(authControllerProvider.notifier).resendOtp(widget.email);
      _startCooldown();
      if (mounted) {
        _showSnackBar(context, l10n.verificationSent, colors.success);
      }
    } catch (e) {
      _logger.severe('Failed to resend OTP', e);
      if (mounted) {
        final apiException = e is DioException
            ? ApiException.fromDioException(e, l10n)
            : ApiException(l10n.errorUnexpected);
        _showSnackBar(context, apiException.message, colors.error);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleVerify(AppLocalizations l10n) async {
    final String otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorText = l10n.invalidOtp);
      return;
    }

    setState(() => _errorText = null);
    _logger.info('Attempting to verify OTP');

    try {
      await ref.read(authControllerProvider.notifier).verifyEmail(otp);

      if (mounted) {
        final user = ref.read(authControllerProvider).value;
        if (user != null) {
          _logger.info('OTP Verification Successful');
          _handleSmartRouting(user.profileIsComplete);
        }
      }
    } catch (e) {
      _logger.severe('Exception during OTP verification', e);
      if (mounted) {
        final apiException = e is DioException
            ? ApiException.fromDioException(e, l10n)
            : ApiException(l10n.errorUnexpected);
        setState(() => _errorText = apiException.message);
      }
    }
  }

  void _handleSmartRouting(bool profileIsComplete) {
    if (!mounted) return;

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.read(appThemeProvider);
    final intentService = ref.read(authIntentServiceProvider);
    final intent = intentService.getIntent();

    if (!profileIsComplete) {
      if (intent.type == AuthIntentType.buyGymSubscription) {
        context.go(RoutePaths.completeProfile);
      } else {
        intentService.clearIntent();
        context.go(RoutePaths.explore);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.profileIncompleteWarning,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: colors.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        });
      }
    } else {
      intentService.clearIntent();
      if (intent.type == AuthIntentType.buyGymSubscription) {
        final int id = intent.payload['gym_id'] as int? ?? 0;
        context.go(RoutePaths.gymDetailsPath(id));
      } else {
        context.go(RoutePaths.explore);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final bool canResend = _cooldownSeconds == 0 && !_isResending;
    final bool isVerifying = ref.watch(authControllerProvider).isLoading;

    final bool isOtpComplete = _otpController.text.length == 6;
    final bool isButtonEnabled = isOtpComplete && !isVerifying;

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
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Dimensions.spacingLarge),

              PremiumAlertBanner(
                colors: colors,
                themeColor: colors.primary,
                icon: Icons.mark_email_unread_rounded,
                title: l10n.enterOtpTitle,
                subtitle: l10n.enterOtpSubtitle(widget.email),
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
                    SizedBox(height: Dimensions.spacingLarge),

                    // ARCHITECTURE FIX: Restored original approved UI matching the screenshot
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      style: TextStyle(
                        fontSize: Dimensions.fontHeading1 * 1.2,
                        fontWeight: FontWeight.bold,
                        letterSpacing:
                            16.0, // Reduced from 24 for a more balanced look
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "000000",
                        hintStyle: TextStyle(
                          color: colors.iconGrey.withValues(alpha: 0.3),
                          letterSpacing: 16.0,
                        ),
                        filled: true,
                        fillColor: colors.background,
                        errorText: _errorText,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: Dimensions
                              .spacingLarge, // Adjusted height to be elegant
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.borderRadiusLarge,
                          ),
                          borderSide: BorderSide(
                            color: colors.iconGrey.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.borderRadiusLarge,
                          ),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.borderRadiusLarge,
                          ),
                          borderSide: BorderSide(
                            color: colors.error,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.borderRadiusLarge,
                          ),
                          borderSide: BorderSide(color: colors.error, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _errorText = null;
                        });
                        if (val.length == 6) {
                          FocusScope.of(context).unfocus();
                          _handleVerify(l10n); // Auto-verify
                        }
                      },
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
                    backgroundColor: isButtonEnabled
                        ? colors.primary
                        : colors.iconGrey.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    elevation: isButtonEnabled ? 4 : 0,
                    shadowColor: colors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadiusLarge,
                      ),
                    ),
                  ),
                  onPressed: isButtonEnabled ? () => _handleVerify(l10n) : null,
                  child: isVerifying
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3.0,
                        )
                      : Text(
                          l10n.verifyAccount,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              SizedBox(height: Dimensions.spacingLarge),

              Center(
                child: canResend
                    ? TextButton(
                        onPressed: () => _handleResend(l10n, colors),
                        child: Text(
                          l10n.resendLink,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: Dimensions.fontBodyLarge,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: colors.textSecondary,
                            size: Dimensions.iconMedium,
                          ),
                          SizedBox(width: Dimensions.spacingSmall),
                          Text(
                            '00:${_cooldownSeconds.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: Dimensions.fontBodyLarge,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
