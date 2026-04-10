import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';

/// A unified, highly reusable premium alert banner for consistent UI across the app.
class PremiumAlertBanner extends StatelessWidget {
  final AppColors colors;
  final Color themeColor;
  final IconData icon;
  final String? title;
  final String subtitle;
  final Widget? actionWidget;
  final bool isCentered;
  final double? customIconSize;

  const PremiumAlertBanner({
    super.key,
    required this.colors,
    required this.themeColor,
    required this.icon,
    this.title,
    required this.subtitle,
    this.actionWidget,
    this.isCentered = false,
    this.customIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor.withOpacity(0.12), themeColor.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: themeColor.withOpacity(0.2), width: 1.5),
      ),
      child: isCentered ? _buildCenteredLayout() : _buildHorizontalLayout(),
    );
  }

  Widget _buildCenteredLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIcon(),
        SizedBox(height: Dimensions.spacingMedium),
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              fontSize: Dimensions.fontTitleMedium,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimensions.spacingSmall),
        ],
        Text(
          subtitle,
          style: TextStyle(
            fontSize: Dimensions.fontBodyMedium,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (actionWidget != null) ...[
          SizedBox(height: Dimensions.spacingMedium),
          actionWidget!,
        ],
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: title != null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        _buildIcon(),
        SizedBox(width: Dimensions.spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyLarge,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                SizedBox(height: Dimensions.spacingTiny),
              ],
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyMedium,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (actionWidget != null) ...[
          SizedBox(width: Dimensions.spacingMedium),
          actionWidget!,
        ],
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(Dimensions.spacingMedium),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: themeColor,
        size: customIconSize ?? Dimensions.iconLarge,
      ),
    );
  }
}
