import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileHeroCard extends StatelessWidget {
  final UserModel? user;
  final bool isLoggedIn;
  final AppColors colors;
  final AppLocalizations l10n;

  // Added a callback to handle avatar update logic externally
  // keeping this widget strictly for UI presentation (Single Responsibility).
  final VoidCallback? onEditAvatarPressed;

  const ProfileHeroCard({
    super.key,
    required this.user,
    required this.isLoggedIn,
    required this.colors,
    required this.l10n,
    this.onEditAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return _buildGuestCard(context);

    // Provide a fallback initial if the user's name is missing
    final String initial = user?.fullName.isNotEmpty == true
        ? user!.fullName[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius,
            offset: Offset(0, Dimensions.shadowOffsetY),
          ),
        ],
      ),
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar & Name Section
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar Stack with Edit Button and Verified Badge
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Main Avatar
                      GestureDetector(
                        onTap: onEditAvatarPressed,
                        child: CircleAvatar(
                          radius: Dimensions.iconLarge * 1.5,
                          backgroundColor: colors.textPrimary,
                          backgroundImage: user?.avatar != null
                              ? NetworkImage(user!.avatar!)
                              : null,
                          child: user?.avatar == null
                              ? Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: Dimensions.fontHeading1 * 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: colors.surface,
                                  ),
                                )
                              : null,
                        ),
                      ),

                      // Verified Badge (Bottom Right)
                      // FIXED: Now checks if the KYC profile is complete instead of just email verification
                      if (user?.profileIsComplete == true)
                        Positioned(
                          bottom: 0,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              color: Colors
                                  .green, // Optional: Changed to green for a stronger 'verified' feeling, adjust to colors.primary if you prefer
                              size: Dimensions.iconLarge,
                            ),
                          ),
                        ),

                      // Edit Avatar Button (Bottom Left)
                      Positioned(
                        bottom: 0,
                        left: -4,
                        child: GestureDetector(
                          onTap: onEditAvatarPressed,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.shadow.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: Dimensions.iconMedium * 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingMedium),

                  // User Name
                  Text(
                    user?.fullName ?? '',
                    style: TextStyle(
                      fontSize: Dimensions.fontHeading2,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Dimensions.spacingTiny),

                  // User City
                  Text(
                    user?.city ?? l10n.guest,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyLarge,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Vertical Divider
            VerticalDivider(
              width: Dimensions.spacingExtraLarge,
              thickness: Dimensions.dividerHeight,
              color: colors.iconGrey.withOpacity(0.2),
              indent: Dimensions.spacingMedium,
              endIndent: Dimensions.spacingMedium,
            ),

            // User Stats Section
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    user?.pointsBalance.toString() ?? '0',
                    l10n.points,
                  ),
                  Divider(
                    height: Dimensions.spacingLarge,
                    color: colors.iconGrey.withOpacity(0.2),
                    thickness: Dimensions.dividerHeight,
                  ),
                  _buildStatItem('0', l10n.activePlans),
                  Divider(
                    height: Dimensions.spacingLarge,
                    color: colors.iconGrey.withOpacity(0.2),
                    thickness: Dimensions.dividerHeight,
                  ),
                  _buildStatItem(l10n.basicMembership, l10n.membership),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an individual statistics item (Value and Label)
  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: Dimensions.fontTitleMedium,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: Dimensions.fontBodyMedium,
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Builds the alternative card displayed when the user is not authenticated
  Widget _buildGuestCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius,
            offset: Offset(0, Dimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_rounded,
            size: Dimensions.iconLarge * 2.5,
            color: colors.iconGrey,
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            l10n.loginToContinue,
            style: TextStyle(
              fontSize: Dimensions.fontTitleMedium,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimensions.spacingLarge),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.surface,
              minimumSize: Size(double.infinity, Dimensions.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.borderRadius),
              ),
            ),
            onPressed: () => context.push(RoutePaths.login),
            child: Text(
              l10n.login,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
