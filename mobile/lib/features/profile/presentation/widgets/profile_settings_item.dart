import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

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

    return InkWell(
      onTap: isSwitch ? null : onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: Dimensions.spacingMedium,
          horizontal: Dimensions.spacingSmall,
        ),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: Dimensions.iconLarge),
            SizedBox(width: Dimensions.spacingMedium),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyLarge,
                  fontWeight: FontWeight.w700,
                  color: itemColor,
                ),
              ),
            ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              SizedBox(width: Dimensions.spacingSmall),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.iconGrey,
                size: Dimensions.iconSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
