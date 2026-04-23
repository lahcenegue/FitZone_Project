import 'package:flutter/material.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
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
    if (amenities.isEmpty) return const SizedBox.shrink();

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
    return Container(
      width: Dimensions.widthPercent(40.0, max: 180.0),
      padding: EdgeInsets.all(Dimensions.spacingSmall),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: Dimensions.iconMedium,
            height: Dimensions.iconMedium,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: amenity.iconImage != null && amenity.iconImage!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      amenity.iconImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildFallbackIcon(),
                    ),
                  )
                : _buildFallbackIcon(),
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

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        Icons.check_circle_rounded,
        size: Dimensions.iconSmall,
        color: colors.primary,
      ),
    );
  }
}
