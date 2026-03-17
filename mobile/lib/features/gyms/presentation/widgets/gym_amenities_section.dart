import 'package:flutter/material.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../data/models/gym_details_model.dart';
import 'gym_section_title.dart';

class GymAmenitiesSection extends StatelessWidget {
  final List<GymAmenity> amenities;
  final AppColors colors;

  const GymAmenitiesSection({
    super.key,
    required this.amenities,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GymSectionTitle(
          title: AppLocalizations.of(context)!.amenities,
          colors: colors,
        ),
        SizedBox(height: Dimensions.spacingMedium),
        Wrap(
          spacing: Dimensions.spacingMedium,
          runSpacing: Dimensions.spacingMedium,
          children: amenities
              .map((amenity) => _buildPremiumAmenityItem(amenity))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPremiumAmenityItem(GymAmenity amenity) {
    // Dynamic icon resolution based on your backend string
    IconData iconData = Icons.done_all_rounded;
    if (amenity.iconName.contains('pool')) iconData = Icons.pool_rounded;
    if (amenity.iconName.contains('sauna')) iconData = Icons.hot_tub_rounded;
    if (amenity.iconName.contains('wifi')) iconData = Icons.wifi_rounded;

    return Container(
      width: Dimensions.widthPercent(
        40.0,
        max: 180.0,
      ), // Responsive width for 2 columns
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingSmall,
        vertical: Dimensions.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        border: Border.all(color: colors.iconGrey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Dimensions.spacingTiny),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: Dimensions.iconSmall,
              color: colors.primary,
            ),
          ),
          SizedBox(width: Dimensions.spacingSmall),
          Expanded(
            child: Text(
              amenity.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: Dimensions.fontBodyMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
