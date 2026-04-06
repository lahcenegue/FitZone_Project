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
    // استخدام AspectRatio يجعل الشبكة متجاوبة 100% مع الهواتف والتابلت بدون تحديد ارتفاع ثابت
    return AspectRatio(
      aspectRatio: 2.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Large Card
          Expanded(
            flex: 1,
            child: _buildGridCard(
              title: l10n.mySubscriptions ?? 'My Subscriptions',
              subtitle: l10n.accessGym ?? 'Access Gym',
              icon: Icons.qr_code_scanner_rounded,
              onTap: () {},
            ),
          ),
          SizedBox(width: Dimensions.spacingMedium),
          // Right Small Cards
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildGridCard(
                    title: l10n.myOrders ?? 'My Orders',
                    icon: Icons.shopping_bag_rounded,
                    onTap: () {},
                  ),
                ),
                SizedBox(height: Dimensions.spacingMedium),
                Expanded(
                  child: _buildGridCard(
                    title: l10n.saved ?? 'Saved',
                    icon: Icons.favorite_rounded,
                    iconColor: colors.error,
                    onTap: () {},
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
    String? subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
      elevation: 2,
      shadowColor: colors.shadow.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.spacingMedium),
          // استخدام FittedBox يمنع أي Overflow مستقبلي مهما كبر الخط
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: iconColor ?? colors.textPrimary,
                  size: Dimensions.iconLarge * 1.3,
                ),
                SizedBox(height: Dimensions.spacingMedium),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyLarge,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: Dimensions.spacingTiny),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyMedium,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
