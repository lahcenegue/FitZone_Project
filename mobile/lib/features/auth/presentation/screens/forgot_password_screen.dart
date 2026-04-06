import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset(
    AppLocalizations l10n,
    AppColors colors,
  ) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar(context, l10n.invalidEmail, colors.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestPasswordReset(email);
      if (mounted) {
        _showSnackBar(context, l10n.resetCodeSent, colors.success);
        // Pass the email to the reset screen via query parameter
        context.push('${RoutePaths.resetPassword}?email=$email');
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
              Icon(
                Icons.lock_reset_rounded,
                size: Dimensions.iconLarge * 2.5,
                color: colors.primary,
              ),
              SizedBox(height: Dimensions.spacingLarge),
              Text(
                l10n.forgotPasswordTitle,
                style: TextStyle(
                  fontSize: Dimensions.fontHeading1 * 1.2,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: Dimensions.spacingTiny),
              Text(
                l10n.forgotPasswordSubtitle,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyLarge,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

              Text(
                l10n.emailAddress,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyLarge,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: Dimensions.spacingSmall),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'user@fitzone.sa',
                  hintStyle: TextStyle(
                    color: colors.iconGrey,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: colors.iconGrey,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: EdgeInsets.all(Dimensions.spacingMedium),
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
                      : () => _handleRequestReset(l10n, colors),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.sendResetCode,
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
}
