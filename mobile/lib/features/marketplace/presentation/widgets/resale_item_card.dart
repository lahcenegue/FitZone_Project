import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/resale_models.dart';

class ResaleItemCard extends StatelessWidget {
  final ResaleItem item;
  final AppColors colors;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const ResaleItemCard({
    super.key,
    required this.item,
    required this.colors,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: Dimensions.spacingLarge),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ARCHITECTURE FIX: Seller Info Header for Trust Building
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.spacingMedium,
                vertical: Dimensions.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: colors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(Dimensions.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: Dimensions.iconSmall * 0.8,
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                    backgroundImage: item.seller.avatar != null
                        ? NetworkImage(item.seller.avatar!)
                        : null,
                    child: item.seller.avatar == null
                        ? Icon(
                            Icons.person_rounded,
                            size: Dimensions.iconSmall,
                            color: colors.primary,
                          )
                        : null,
                  ),
                  SizedBox(width: Dimensions.spacingSmall),
                  Text(
                    '${l10n.sellerInfo}: ',
                    style: TextStyle(
                      fontSize: Dimensions.fontBodySmall,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.seller.name,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodySmall,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.iconGrey.withValues(alpha: 0.1)),

            // MIDDLE SECTION: Gym & Discount
            Padding(
              padding: EdgeInsets.all(Dimensions.spacingMedium),
              child: Row(
                children: [
                  Container(
                    width: Dimensions.iconLarge * 1.5,
                    height: Dimensions.iconLarge * 1.5,
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadius,
                      ),
                      border: Border.all(
                        color: colors.iconGrey.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Dimensions.borderRadius,
                      ),
                      child: item.gym.logo != null
                          ? Image.network(item.gym.logo!, fit: BoxFit.cover)
                          : Icon(
                              Icons.fitness_center_rounded,
                              color: colors.iconGrey,
                            ),
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingMedium),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.gym.brandName,
                          style: TextStyle(
                            fontSize: Dimensions.fontBodyLarge,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          item.gym.branchName,
                          style: TextStyle(
                            fontSize: Dimensions.fontBodySmall,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  if (item.pricing.discountPercentage > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.spacingSmall,
                        vertical: Dimensions.spacingTiny,
                      ),
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusPill,
                        ),
                      ),
                      child: Text(
                        '${item.pricing.discountPercentage}% ${l10n.discountTag}',
                        style: TextStyle(
                          fontSize: Dimensions.fontBodySmall,
                          fontWeight: FontWeight.w900,
                          color: colors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // DETAILS SECTION
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.spacingMedium,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today_rounded,
                    '${item.plan.daysLeft} ${l10n.daysLeft}',
                    colors.primary,
                  ),
                  _buildInfoChip(
                    Icons.people_alt_rounded,
                    _getGenderLabel(item.gym.genderAllowed),
                    colors.textSecondary,
                  ),
                  if (item.gym.distanceKm != null)
                    _buildInfoChip(
                      Icons.location_on_rounded,
                      '${item.gym.distanceKm} ${l10n.kmAway}',
                      colors.textSecondary,
                    ),
                ],
              ),
            ),

            SizedBox(height: Dimensions.spacingMedium),

            // BOTTOM PRICING ROW
            Padding(
              padding: EdgeInsets.only(
                left: Dimensions.spacingMedium,
                right: Dimensions.spacingMedium,
                bottom: Dimensions.spacingMedium,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.pricing.fairValue.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyMedium,
                      fontWeight: FontWeight.w600,
                      color: colors.iconGrey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingSmall),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item.pricing.askingPrice.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: Dimensions.fontHeading1,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                          letterSpacing: -1.0,
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingTiny),
                      Text(
                        'SAR',
                        style: TextStyle(
                          fontSize: Dimensions.fontBodySmall,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colors.iconGrey,
                    size: Dimensions.iconSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Dimensions.iconSmall, color: color),
        SizedBox(width: Dimensions.spacingTiny),
        Text(
          text,
          style: TextStyle(
            fontSize: Dimensions.fontBodySmall,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getGenderLabel(String type) {
    switch (type.toLowerCase()) {
      case 'male':
        return l10n.genderMale;
      case 'female':
        return l10n.genderFemale;
      default:
        return l10n.genderMixed;
    }
  }
}
