import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../core/presentation/widgets/premium_text_field.dart';
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

    if (intent.type == AuthIntentType.buyGymSubscription) {
      if (!profileIsComplete) {
        _logger.info(
          'User intent is subscription, but KYC is missing. Redirecting to KYC.',
        );
        context.go(RoutePaths.completeProfile);
      } else {
        _logger.info(
          'User intent is subscription and KYC is complete. Redirecting to Gym.',
        );
        intentService.clearIntent();
        final int id = intent.payload['gym_id'] as int? ?? 0;
        context.go(RoutePaths.gymDetailsPath(id));
      }
    } else {
      _logger.info('Standard login flow. Redirecting to Explore.');
      intentService.clearIntent();
      context.go(RoutePaths.explore);
    }
  }

  void _handleLoginError(Object error, AppColors colors) {
    _logger.warning('Login failed: $error');

    if (error is AuthException &&
        error.code == 'EMAIL_NOT_VERIFIED' &&
        error.email != null) {
      _showSnackBar(context, error.message, colors.warning);
      ref.read(authControllerProvider.notifier).resendOtp(error.email!);
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

    // ARCHITECTURE FIX: Event-Driven Navigation perfectly safe from state updates
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          // Make sure we only navigate IF the previous state was null (actual login)
          // This prevents navigating again if the user updates avatar or points later!
          if (user != null && previous?.value == null) {
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.explore);
            }
          },
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
                    PremiumTextField(
                      label: l10n.emailAddress,
                      hintText: 'user@fitzone.sa',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: formState.emailError,
                      colors: colors,
                      onChanged: (val) => ref
                          .read(loginFormProvider.notifier)
                          .updateEmail(val, l10n),
                    ),
                    SizedBox(height: Dimensions.spacingMedium),

                    PremiumTextField(
                      label: l10n.password,
                      hintText: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _isPasswordObscured,
                      errorText: formState.passwordError,
                      colors: colors,
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
                      onChanged: (val) => ref
                          .read(loginFormProvider.notifier)
                          .updatePassword(val, l10n),
                    ),

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
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

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
