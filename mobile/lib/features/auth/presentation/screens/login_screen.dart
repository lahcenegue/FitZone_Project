import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/auth_intent_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/auth_api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/login_form_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final Logger _logger = Logger('LoginScreen');
  bool _isPasswordObscured = true;

  void _handleSmartRouting(bool profileIsComplete) {
    final intentService = ref.read(authIntentServiceProvider);
    final intent = intentService.getIntent();

    if (!profileIsComplete) {
      // Intent is NOT cleared here because it's needed in CompleteProfileScreen
      context.go(RoutePaths.completeProfile);
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

  void _handleLoginError(Object error, AppColors colors) {
    _logger.warning('Login failed: $error');

    // Automatically trigger OTP resend and navigate if email is not verified
    if (error is AuthException &&
        error.code == 'EMAIL_NOT_VERIFIED' &&
        error.email != null) {
      _showSnackBar(context, error.message, colors.warning);

      // Silently request a new OTP in the background
      ref.read(authControllerProvider.notifier).resendOtp(error.email!);

      // Navigate the user to the OTP screen
      context.push('${RoutePaths.verifyOtp}?email=${error.email}');
    } else {
      _showSnackBar(context, error.toString(), colors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final formState = ref.watch(loginFormProvider);
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            _logger.info('Login successful for: ${user.email}');
            _handleSmartRouting(user.profileIsComplete);
          }
        },
        error: (error, stackTrace) => _handleLoginError(error, colors),
      );
    });

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
              SizedBox(height: Dimensions.spacingMedium),
              _buildHeader(l10n, colors),
              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              _buildCustomTextField(
                label: l10n.emailAddress,
                hint: 'user@fitzone.sa',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                errorText: formState.emailError,
                colors: colors,
                onChanged: (val) =>
                    ref.read(loginFormProvider.notifier).updateEmail(val, l10n),
              ),
              SizedBox(height: Dimensions.spacingMedium),

              _buildPasswordField(l10n, formState, colors),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.push(RoutePaths.forgotPassword);
                  },
                  child: Text(
                    l10n.forgotPassword,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: Dimensions.fontBodyMedium,
                    ),
                  ),
                ),
              ),

              SizedBox(height: Dimensions.spacingLarge),

              _buildSubmitButton(l10n, formState, authState, colors),

              SizedBox(height: Dimensions.spacingExtraLarge),

              Center(
                child: TextButton(
                  onPressed: () => context.push(RoutePaths.register),
                  child: Text(
                    l10n.dontHaveAccount,
                    style: TextStyle(
                      color: colors.textSecondary,
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

  Widget _buildHeader(AppLocalizations l10n, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.loginTitle,
          style: TextStyle(
            fontSize: Dimensions.fontHeading1 * 1.2,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: Dimensions.spacingTiny),
        Text(
          l10n.loginSubtitle,
          style: TextStyle(
            fontSize: Dimensions.fontBodyLarge,
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
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
            fontWeight: FontWeight.w700,
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
          decoration: _getPremiumInputDecoration(hint, icon, colors, errorText),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    AppLocalizations l10n,
    LoginFormState formState,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.password,
          style: TextStyle(
            fontSize: Dimensions.fontBodyLarge,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: Dimensions.spacingSmall),
        TextFormField(
          obscureText: _isPasswordObscured,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration:
              _getPremiumInputDecoration(
                '••••••••',
                Icons.lock_outline_rounded,
                colors,
                formState.passwordError,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colors.iconGrey,
                  ),
                  onPressed: () => setState(
                    () => _isPasswordObscured = !_isPasswordObscured,
                  ),
                ),
              ),
          onChanged: (val) =>
              ref.read(loginFormProvider.notifier).updatePassword(val, l10n),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    AppLocalizations l10n,
    LoginFormState formState,
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
                if (ref.read(loginFormProvider.notifier).validateAll(l10n)) {
                  ref
                      .read(authControllerProvider.notifier)
                      .login(formState.email, formState.password);
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
                l10n.loginButton,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  InputDecoration _getPremiumInputDecoration(
    String hint,
    IconData icon,
    AppColors colors,
    String? errorText,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.iconGrey, fontWeight: FontWeight.w400),
      prefixIcon: Icon(icon, color: colors.iconGrey),
      filled: true,
      fillColor: colors.surface,
      errorText: errorText,
      errorMaxLines: 2,
      contentPadding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingMedium,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        borderSide: BorderSide(color: colors.error, width: 2),
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
