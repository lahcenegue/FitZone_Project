import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class PremiumHistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingText;
  final IconData icon;
  final Color color;
  final AppColors colors;
  final VoidCallback? onTap;

  const PremiumHistoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.icon,
    required this.color,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimensions.spacingMedium),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // ARCHITECTURE FIX: Anti-alias clipping ensures inner children (like the side line)
          // are perfectly trimmed to the border radius, fixing the layout bleed.
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left/Right Status Indicator Line
                // ARCHITECTURE FIX: Removed manual border radius, relying entirely on parent's clipping
                Container(width: 6, color: color),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(Dimensions.spacingMedium),
                    child: Row(
                      children: [
                        // Circular Icon
                        Container(
                          padding: EdgeInsets.all(Dimensions.spacingMedium),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: Dimensions.iconMedium,
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingMedium),
                        // Title and Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: Dimensions.fontBodyLarge,
                                  color: colors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: Dimensions.spacingTiny),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: Dimensions.fontBodySmall,
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingSmall),
                        // Value Pill
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.spacingMedium,
                            vertical: Dimensions.spacingTiny,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusPill,
                            ),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            trailingText,
                            style: TextStyle(
                              fontSize: Dimensions.fontBodySmall * 1.1,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
