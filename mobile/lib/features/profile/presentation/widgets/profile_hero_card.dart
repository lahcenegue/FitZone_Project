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

  const ProfileHeroCard({
    super.key,
    required this.user,
    required this.isLoggedIn,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return _buildGuestCard(context);

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
            // Avatar & Name
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
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
                      if (user?.isVerified == true)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified_rounded,
                            color: colors.error,
                            size: Dimensions.iconLarge,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: Dimensions.spacingMedium),
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
                  Text(
                    user?.city ?? l10n.guest ?? 'Guest',
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

            // Divider
            VerticalDivider(
              width: Dimensions.spacingExtraLarge,
              thickness: Dimensions.dividerHeight,
              color: colors.iconGrey.withOpacity(0.2),
              indent: Dimensions.spacingMedium,
              endIndent: Dimensions.spacingMedium,
            ),

            // Stats
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    user?.pointsBalance.toString() ?? '0',
                    l10n.points ?? 'Points',
                  ),
                  Divider(
                    height: Dimensions.spacingLarge,
                    color: colors.iconGrey.withOpacity(0.2),
                    thickness: Dimensions.dividerHeight,
                  ),
                  _buildStatItem('0', l10n.activePlans ?? 'Active Plans'),
                  Divider(
                    height: Dimensions.spacingLarge,
                    color: colors.iconGrey.withOpacity(0.2),
                    thickness: Dimensions.dividerHeight,
                  ),
                  _buildStatItem(
                    l10n.basicMembership ?? 'Basic',
                    l10n.membership ?? 'Membership',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            l10n.loginToContinue ?? 'Login to unlock features',
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
              l10n.login ?? 'Login',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
