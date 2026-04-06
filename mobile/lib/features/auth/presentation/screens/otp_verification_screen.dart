import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/auth_intent_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Screen for verifying the user's email via a 6-digit OTP.
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
    try {
      await ref.read(authControllerProvider.notifier).resendOtp(widget.email);
      _startCooldown();
      if (mounted) {
        _showSnackBar(context, l10n.verificationSent, colors.success);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, e.toString(), colors.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _handleVerify(AppLocalizations l10n) async {
    final String otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorText = l10n.invalidOtp);
      return;
    }

    setState(() => _errorText = null);

    try {
      await ref.read(authControllerProvider.notifier).verifyEmail(otp);
      final authState = ref.read(authControllerProvider);

      if (authState.hasValue && authState.value != null) {
        _handleSmartRouting(authState.value!.profileIsComplete);
      } else if (authState.hasError) {
        setState(() => _errorText = authState.error.toString());
      }
    } catch (e) {
      setState(() => _errorText = e.toString());
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
        // DO NOT clear intent here, we need it for CompleteProfileScreen!
        context.go(RoutePaths.completeProfile);
      } else {
        intentService.clearIntent(); // Safe to clear, flow ends here
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
      intentService.clearIntent(); // Safe to clear, flow ends here
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final bool canResend = _cooldownSeconds == 0 && !_isResending;
    final bool isVerifying = ref.watch(authControllerProvider).isLoading;

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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: Dimensions.spacingLarge),
              Text(
                l10n.enterOtpTitle,
                style: TextStyle(
                  fontSize: Dimensions.fontHeading1,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: Dimensions.spacingMedium),
              Text(
                // Safely invokes the generated method from the AppLocalizations class
                l10n.enterOtpSubtitle(widget.email),
                style: TextStyle(
                  fontSize: Dimensions.fontBodyLarge,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              // Custom OTP Input Field
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: Dimensions.fontHeading1 * 1.2,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 16.0,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: l10n.otpHint,
                  hintStyle: TextStyle(color: colors.iconGrey.withOpacity(0.3)),
                  filled: true,
                  fillColor: colors.surface,
                  errorText: _errorText,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: Dimensions.spacingLarge,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusLarge,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusLarge,
                    ),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.length == 6) {
                    FocusScope.of(context).unfocus();
                    _handleVerify(l10n);
                  }
                },
              ),

              SizedBox(height: Dimensions.spacingExtraLarge * 2),

              // Verify Button
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
                  onPressed: isVerifying ? null : () => _handleVerify(l10n),
                  child: isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.verifyAccount,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: Dimensions.spacingLarge),

              // Resend Code Section
              Center(
                child: TextButton(
                  onPressed: canResend
                      ? () => _handleResend(l10n, colors)
                      : null,
                  child: _isResending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: colors.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          canResend
                              ? l10n.resendLink
                              : l10n.resendLinkCooldown(_cooldownSeconds),
                          style: TextStyle(
                            color: canResend
                                ? colors.primary
                                : colors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: Dimensions.fontBodyLarge,
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
