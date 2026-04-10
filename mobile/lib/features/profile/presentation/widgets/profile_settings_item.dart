import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// A premium settings row with a circular icon background and clean layout.
class ProfileSettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final AppColors colors;
  final String? trailingText;
  final bool isDestructive;
  final bool isSwitch;
  final bool switchValue;
  final VoidCallback? onTap;
  final Function(bool)? onSwitchChanged;

  const ProfileSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.colors,
    this.trailingText,
    this.isDestructive = false,
    this.isSwitch = false,
    this.switchValue = false,
    this.onTap,
    this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isDestructive ? colors.error : colors.textPrimary;
    final Color iconBgColor = isDestructive
        ? colors.error.withOpacity(0.1)
        : colors.primary.withOpacity(0.08);
    final Color iconColor = isDestructive ? colors.error : colors.primary;

    return InkWell(
      onTap: isSwitch ? null : onTap,
      borderRadius: BorderRadius.circular(Dimensions.borderRadius),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: Dimensions.spacingMedium,
          horizontal: Dimensions.spacingMedium,
        ),
        child: Row(
          children: [
            // Styled Icon Container
            Container(
              padding: EdgeInsets.all(Dimensions.spacingSmall * 1.2),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: Dimensions.iconMedium),
            ),
            SizedBox(width: Dimensions.spacingMedium),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyLarge,
                  fontWeight: FontWeight.w600,
                  color: itemColor,
                ),
              ),
            ),

            // Trailing Elements
            if (isSwitch)
              Switch.adaptive(
                value: switchValue,
                activeColor: colors.primary,
                onChanged: onSwitchChanged,
              )
            else ...[
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyMedium,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              SizedBox(width: Dimensions.spacingSmall),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.iconGrey.withOpacity(0.5),
                size: Dimensions.iconSmall * 0.8,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
