import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileActionGrid extends StatelessWidget {
  final AppColors colors;
  final AppLocalizations l10n;

  const ProfileActionGrid({
    super.key,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: _buildGridCard(
              title: l10n.mySubscriptions,
              icon: Icons.qr_code_scanner_rounded,
              onTap: () {},
              compact: false,
            ),
          ),
          SizedBox(width: Dimensions.spacingMedium),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildGridCard(
                    title: l10n.myOrders,
                    icon: Icons.shopping_bag_rounded,
                    onTap: () {},
                    compact: true,
                  ),
                ),
                SizedBox(height: Dimensions.spacingMedium),
                Expanded(
                  child: _buildGridCard(
                    title: l10n.saved,
                    icon: Icons.favorite_rounded,
                    iconColor: colors.error,
                    onTap: () {},
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
    bool compact = false,
  }) {
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          child: Padding(
            padding: EdgeInsets.all(
              compact ? Dimensions.spacingSmall : Dimensions.spacingMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: iconColor ?? colors.textPrimary,
                  size: compact ? Dimensions.iconMedium : Dimensions.iconLarge,
                ),
                SizedBox(
                  height: compact
                      ? Dimensions.spacingSmall
                      : Dimensions.spacingMedium,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact
                        ? Dimensions.fontBodyLarge
                        : Dimensions.fontHeading3,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
