import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

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

  static final Logger _logger = Logger('ProfileScreen');

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
            // 1. Header Row
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
                    if (isLoggedIn) _buildHeaderNotification(colors),
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
                    // 2. Profile Hero Card (Handles both logged in and guest UI)
                    ProfileHeroCard(
                      user: user,
                      isLoggedIn: isLoggedIn,
                      colors: colors,
                      l10n: l10n,
                      onEditAvatarPressed: () =>
                          _handleAvatarUpdate(context, ref, colors, l10n),
                    ),
                    SizedBox(height: Dimensions.spacingExtraLarge),

                    // 3. Authenticated Content
                    if (isLoggedIn) ...[
                      ProfileActionGrid(colors: colors, l10n: l10n),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      ProfileGamificationCard(
                        user: user,
                        colors: colors,
                        l10n: l10n,
                      ),
                      SizedBox(height: Dimensions.spacingExtraLarge * 1.5),

                      _buildSectionLabel(l10n.accountSettings, colors),
                      _buildSettingsGroup(colors, [
                        ProfileSettingsItem(
                          icon: Icons.person_outline_rounded,
                          title: l10n.personalInfo,
                          colors: colors,
                          onTap: () => context.push(RoutePaths.personalInfo),
                        ),
                        ProfileSettingsItem(
                          icon: Icons.payment_rounded,
                          title: l10n.paymentMethods,
                          colors: colors,
                          onTap: () {},
                        ),
                        ProfileSettingsItem(
                          icon: Icons.lock_outline_rounded,
                          title: l10n.changePassword,
                          colors: colors,
                          onTap: () {},
                        ),
                        ProfileSettingsItem(
                          icon: Icons.delete_outline_rounded,
                          title: l10n.deleteAccount,
                          colors: colors,
                          isDestructive: true,
                          onTap: () {},
                        ),
                      ]),
                      SizedBox(height: Dimensions.spacingExtraLarge),
                    ],

                    // 4. App Preferences Group (Visible to All)
                    _buildSectionLabel(l10n.appSettings, colors),
                    _buildSettingsGroup(colors, [
                      ProfileSettingsItem(
                        icon: Icons.language_rounded,
                        title: l10n.language,
                        trailingText: isArabic ? 'العربية' : 'English',
                        colors: colors,
                        onTap: () =>
                            _showLanguagePicker(context, ref, colors, isArabic),
                      ),
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
                    ]),

                    // 5. Support Group (Visible to All)
                    SizedBox(height: Dimensions.spacingExtraLarge),
                    _buildSectionLabel(l10n.supportAndAbout, colors),
                    _buildSettingsGroup(colors, [
                      ProfileSettingsItem(
                        icon: Icons.help_outline_rounded,
                        title: l10n.helpCenter,
                        colors: colors,
                        onTap: () {},
                      ),
                      ProfileSettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.privacyPolicy,
                        colors: colors,
                        onTap: () {},
                      ),
                      ProfileSettingsItem(
                        icon: Icons.description_outlined,
                        title: l10n.termsOfService,
                        colors: colors,
                        onTap: () {},
                      ),
                    ]),

                    // 6. Logout Section (Logged In Only)
                    if (isLoggedIn) ...[
                      SizedBox(height: Dimensions.spacingExtraLarge * 2),
                      _buildLogoutSection(context, ref, colors, l10n),
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

  // --- UI Component Helpers ---

  Widget _buildSectionLabel(String text, AppColors colors) {
    return Padding(
      padding: EdgeInsets.only(
        left: Dimensions.spacingSmall,
        bottom: Dimensions.spacingSmall,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Dimensions.fontBodyMedium,
          fontWeight: FontWeight.w800,
          color: colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(AppColors colors, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget item = entry.value;
          return Column(
            children: [
              item,
              if (idx < items.length - 1)
                Padding(
                  padding: EdgeInsets.only(
                    left: Dimensions.spacingExtraLarge * 1.5,
                  ),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: colors.iconGrey.withOpacity(0.1),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutSection(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          _logger.info('User initiated logout.');
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) {
            _logger.info('Logout successful, navigating to explore screen.');
            context.go(RoutePaths.explore);
          }
        },
        icon: Icon(Icons.logout_rounded, color: colors.error),
        label: Text(
          l10n.logout,
          style: TextStyle(
            color: colors.error,
            fontWeight: FontWeight.w800,
            fontSize: Dimensions.fontTitleMedium,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.spacingExtraLarge,
            vertical: Dimensions.spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            side: BorderSide(color: colors.error.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderNotification(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.notifications_none_rounded, color: colors.textPrimary),
        onPressed: () {},
      ),
    );
  }

  // --- Existing Logic Handlers ---

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
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageTile('العربية', isCurrentlyArabic, colors, () {
                  ref.read(appLocaleProvider.notifier).setLocale('ar');
                  Navigator.pop(ctx);
                }),
                SizedBox(height: Dimensions.spacingSmall),
                _buildLanguageTile('English', !isCurrentlyArabic, colors, () {
                  ref.read(appLocaleProvider.notifier).setLocale('en');
                  Navigator.pop(ctx);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageTile(
    String title,
    bool selected,
    AppColors colors,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: colors.primary)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
      ),
      tileColor: selected ? colors.primary.withOpacity(0.05) : null,
    );
  }

  Future<void> _handleAvatarUpdate(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    AppLocalizations l10n,
  ) async {
    _logger.info('User initiated avatar update process.');
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null || !context.mounted) {
      _logger.info('Avatar selection cancelled by user.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          Center(child: CircularProgressIndicator(color: colors.primary)),
    );

    _logger.info('Uploading new avatar to API...');
    final String? newAvatarUrl = await ref
        .read(authControllerProvider.notifier)
        .uploadAvatarToApi(pickedFile.path);

    if (context.mounted) Navigator.pop(context);

    if (newAvatarUrl != null) {
      _logger.info('Avatar uploaded successfully. Updating local state.');
      ref
          .read(authControllerProvider.notifier)
          .updateAvatarStateAndCache(newAvatarUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.avatarUpdatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      _logger.severe('Avatar upload failed. Received null URL.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOops),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }
}
