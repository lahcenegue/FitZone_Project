import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// The main profile screen displaying user info, settings, and app preferences.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);

    // Watch the auth state to rebuild the UI whenever the user logs in or out
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final bool isLoggedIn = user != null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primary,
        elevation: 0,
        title: Text(
          l10n.profileTitle ?? 'Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(context, isLoggedIn, user, colors, l10n),

            Padding(
              padding: EdgeInsets.all(Dimensions.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoggedIn) ...[
                    _buildSectionTitle(
                      l10n.accountSettings ?? 'Account',
                      colors,
                    ),
                    SizedBox(height: Dimensions.spacingSmall),
                    _buildMenuCard(
                      colors: colors,
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: l10n.personalInfo ?? 'Personal Information',
                          colors: colors,
                          onTap: () {}, // TODO: Navigate to Edit Profile
                        ),
                        _buildDivider(colors),
                        _buildMenuItem(
                          icon: Icons.card_membership_rounded,
                          title: 'My Subscriptions', // Add to l10n later
                          colors: colors,
                          onTap:
                              () {}, // TODO: Navigate to Subscriptions Screen
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.spacingExtraLarge),
                  ],

                  _buildSectionTitle(l10n.filters ?? 'Preferences', colors),
                  SizedBox(height: Dimensions.spacingSmall),
                  _buildMenuCard(
                    colors: colors,
                    children: [
                      _buildMenuItem(
                        icon: Icons.language_rounded,
                        title: l10n.language ?? 'Language',
                        trailingText: 'English', // Dynamic later
                        colors: colors,
                        onTap: () {}, // TODO: Show Language Picker
                      ),
                      _buildDivider(colors),
                      _buildMenuSwitch(
                        icon: Icons.dark_mode_outlined,
                        title: l10n.darkMode ?? 'Dark Mode',
                        value: Theme.of(context).brightness == Brightness.dark,
                        colors: colors,
                        onChanged: (val) {}, // TODO: Toggle Theme Provider
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingExtraLarge),

                  _buildSectionTitle('Support & About', colors),
                  SizedBox(height: Dimensions.spacingSmall),
                  _buildMenuCard(
                    colors: colors,
                    children: [
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        colors: colors,
                        onTap: () {},
                      ),
                      _buildDivider(colors),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        colors: colors,
                        onTap: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingExtraLarge),

                  if (isLoggedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      height: Dimensions.buttonHeight,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                          side: BorderSide(
                            color: colors.error.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.borderRadius,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          l10n.logout ?? 'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Dimensions.fontBodyLarge,
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          // Force navigation to home/explore after logout
                          if (context.mounted) {
                            context.go(RoutePaths.explore);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingExtraLarge),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    bool isLoggedIn,
    dynamic user,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: Dimensions.spacingExtraLarge,
        bottom: Dimensions.spacingExtraLarge * 1.5,
        left: Dimensions.spacingLarge,
        right: Dimensions.spacingLarge,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(Dimensions.borderRadiusLarge * 1.5),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 47,
              backgroundColor: colors.surface,
              // استخدام avatar بدلاً من profileImage
              backgroundImage: (isLoggedIn && user?.avatar != null)
                  ? NetworkImage(user.avatar!)
                  : null,
              child: (!isLoggedIn || user?.avatar == null)
                  ? Icon(Icons.person_rounded, size: 50, color: colors.iconGrey)
                  : null,
            ),
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            isLoggedIn
                ? (user?.fullName ?? 'FitZone Member')
                : (l10n.guestUser ?? 'Guest User'),
            style: TextStyle(
              fontSize: Dimensions.fontHeading2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: Dimensions.spacingTiny),
          Text(
            isLoggedIn
                ? (user?.email ?? '')
                : (l10n.loginToContinue ?? 'Login to unlock all features'),
            style: TextStyle(
              fontSize: Dimensions.fontBodyMedium,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          if (!isLoggedIn) ...[
            SizedBox(height: Dimensions.spacingLarge),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingExtraLarge,
                  vertical: Dimensions.spacingSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                ),
              ),
              onPressed: () => context.push(RoutePaths.login),
              child: Text(
                l10n.loginButton ?? 'Login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Dimensions.fontBodyLarge,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColors colors) {
    return Padding(
      padding: EdgeInsets.only(left: Dimensions.spacingSmall),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Dimensions.fontBodyLarge,
          fontWeight: FontWeight.bold,
          color: colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required AppColors colors,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius,
            offset: Offset(0, Dimensions.shadowOffsetY / 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required AppColors colors,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingTiny,
      ),
      leading: Container(
        padding: EdgeInsets.all(Dimensions.spacingSmall),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.primary, size: Dimensions.iconMedium),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Dimensions.fontBodyLarge,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: Dimensions.fontBodyMedium,
              ),
            ),
            SizedBox(width: Dimensions.spacingSmall),
          ],
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: colors.iconGrey,
            size: Dimensions.iconSmall,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildMenuSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required AppColors colors,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingLarge,
        vertical: Dimensions.spacingTiny,
      ),
      leading: Container(
        padding: EdgeInsets.all(Dimensions.spacingSmall),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.primary, size: Dimensions.iconMedium),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Dimensions.fontBodyLarge,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: colors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Divider(
      height: 1,
      thickness: 1,
      color: colors.iconGrey.withOpacity(0.1),
      indent: 60,
    );
  }
}
