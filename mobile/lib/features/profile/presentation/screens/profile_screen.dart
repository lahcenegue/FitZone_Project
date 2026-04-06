import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/l10n/app_locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:fitzone/core/location/location_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../widgets/profile_hero_card.dart';
import '../widgets/profile_action_grid.dart';
import '../widgets/profile_gamification_card.dart';
import '../widgets/profile_settings_item.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);

    final authState = ref.watch(authControllerProvider);
    final UserModel? user = authState.value;
    final bool isLoggedIn = user != null;

    final locationState = ref.watch(userLocationProvider);
    final currentLocale = ref.watch(appLocaleProvider);
    final bool isArabic = currentLocale.languageCode == 'ar';
    final bool isDarkMode = colors is DarkColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Dimensions.spacingLarge,
                  Dimensions.spacingExtraLarge,
                  Dimensions.spacingLarge,
                  Dimensions.spacingMedium,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.profile,
                      style: TextStyle(
                        fontSize: Dimensions.fontHeading1 * 1.3,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    if (isLoggedIn)
                      CircleAvatar(
                        backgroundColor: colors.surface,
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: colors.textPrimary,
                          ),
                          onPressed: () {},
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingLarge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeroCard(
                      user: user,
                      isLoggedIn: isLoggedIn,
                      colors: colors,
                      l10n: l10n,
                    ),
                    SizedBox(height: Dimensions.spacingExtraLarge),

                    if (isLoggedIn) ...[
                      ProfileActionGrid(colors: colors, l10n: l10n),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      ProfileGamificationCard(
                        user: user,
                        colors: colors,
                        l10n: l10n,
                      ),
                      SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

                      _buildSectionHeader(l10n.accountSettings, colors),
                      ProfileSettingsItem(
                        icon: Icons.person_outline_rounded,
                        title: l10n.personalInfo,
                        colors: colors,
                        onTap: () {},
                      ),
                      _buildDivider(colors),
                      ProfileSettingsItem(
                        icon: Icons.payment_rounded,
                        title: l10n.paymentMethods,
                        colors: colors,
                        onTap: () {},
                      ),
                      _buildDivider(colors),
                      ProfileSettingsItem(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.changePassword,
                        colors: colors,
                        onTap: () {},
                      ),
                      _buildDivider(colors),
                      ProfileSettingsItem(
                        icon: Icons.delete_outline_rounded,
                        title: l10n.deleteAccount,
                        colors: colors,
                        isDestructive: true,
                        onTap: () {},
                      ),
                      SizedBox(height: Dimensions.spacingExtraLarge),
                    ],

                    _buildSectionHeader(l10n.appSettings, colors),
                    ProfileSettingsItem(
                      icon: Icons.language_rounded,
                      title: l10n.language,
                      trailingText: isArabic ? 'العربية' : 'English',
                      colors: colors,
                      onTap: () =>
                          _showLanguagePicker(context, ref, colors, isArabic),
                    ),
                    _buildDivider(colors),
                    ProfileSettingsItem(
                      icon: Icons.dark_mode_outlined,
                      title: l10n.darkMode,
                      isSwitch: true,
                      switchValue: isDarkMode,
                      colors: colors,
                      onSwitchChanged: (val) {
                        ref.read(appThemeProvider.notifier).toggleTheme();
                      },
                    ),
                    _buildDivider(colors),
                    ProfileSettingsItem(
                      icon: Icons.location_on_outlined,
                      title: l10n.locationServices,
                      isSwitch: true,
                      switchValue: locationState.isServiceEnabled,
                      colors: colors,
                      onSwitchChanged: (val) {
                        ref
                            .read(userLocationProvider.notifier)
                            .promptEnableLocation();
                      },
                    ),

                    SizedBox(height: Dimensions.spacingExtraLarge),
                    _buildSectionHeader(l10n.supportAndAbout, colors),
                    ProfileSettingsItem(
                      icon: Icons.help_outline_rounded,
                      title: l10n.helpCenter,
                      colors: colors,
                      onTap: () {},
                    ),
                    _buildDivider(colors),
                    ProfileSettingsItem(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.privacyPolicy,
                      colors: colors,
                      onTap: () {},
                    ),
                    _buildDivider(colors),
                    ProfileSettingsItem(
                      icon: Icons.description_outlined,
                      title: l10n.termsOfService,
                      colors: colors,
                      onTap: () {},
                    ),

                    if (isLoggedIn) ...[
                      SizedBox(height: Dimensions.spacingExtraLarge * 2),
                      _buildLogoutButton(context, ref, colors, l10n),
                    ],
                    SizedBox(height: Dimensions.spacingExtraLarge * 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    bool isCurrentlyArabic,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.borderRadiusLarge),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentlyArabic ? 'اختر اللغة' : 'Select Language',
                  style: TextStyle(
                    fontSize: Dimensions.fontHeading2,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: Dimensions.spacingLarge),
                ListTile(
                  title: Text(
                    'العربية',
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyLarge,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  trailing: isCurrentlyArabic
                      ? Icon(Icons.check_circle_rounded, color: colors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadius,
                    ),
                  ),
                  tileColor: isCurrentlyArabic
                      ? colors.primary.withOpacity(0.05)
                      : null,
                  onTap: () {
                    ref.read(appLocaleProvider.notifier).setLocale('ar');
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: Dimensions.spacingSmall),
                ListTile(
                  title: Text(
                    'English',
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyLarge,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  trailing: !isCurrentlyArabic
                      ? Icon(Icons.check_circle_rounded, color: colors.primary)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadius,
                    ),
                  ),
                  tileColor: !isCurrentlyArabic
                      ? colors.primary.withOpacity(0.05)
                      : null,
                  onTap: () {
                    ref.read(appLocaleProvider.notifier).setLocale('en');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Dimensions.spacingMedium,
        top: Dimensions.spacingSmall,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Dimensions.fontTitleMedium,
          fontWeight: FontWeight.w900,
          color: colors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Divider(
      height: Dimensions.dividerHeight,
      thickness: Dimensions.dividerHeight,
      color: colors.iconGrey.withOpacity(0.15),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: Dimensions.buttonHeight * 1.2,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.error.withOpacity(0.1),
          foregroundColor: colors.error,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          ),
        ),
        onPressed: () async {
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) context.go(RoutePaths.explore);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: Dimensions.iconLarge),
            SizedBox(width: Dimensions.spacingMedium),
            Text(
              l10n.logout,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: Dimensions.fontTitleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
