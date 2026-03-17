import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../data/models/gym_model.dart';

class PlaceInfoCard extends ConsumerWidget {
  final GymModel place;
  final AppColors colors;
  final VoidCallback onTap;

  const PlaceInfoCard({
    super.key,
    required this.place,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final userLocation = ref.watch(userLocationProvider);

    String categoryText = l10n.fitnessCenter;
    if (place.category == PlaceCategory.restaurant)
      categoryText = l10n.healthyFood;
    if (place.category == PlaceCategory.trainer)
      categoryText = l10n.personalTrainer;

    final String dynamicDistance = userLocation != null
        ? LocationService.formatDistance(
            LocationService.calculateDistanceInMeters(
              userLocation,
              place.location,
            ),
            l10n.km,
            'm',
          )
        : '-- ${l10n.km}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Dimensions.widthPercent(45.0, max: 200.0),
        margin: EdgeInsets.only(
          left: Dimensions.spacingMedium,
          bottom: Dimensions.spacingMedium,
          top: Dimensions.spacingMedium,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: Dimensions.shadowBlurRadius,
              offset: Offset(0, Dimensions.shadowOffsetY / 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(Dimensions.borderRadiusLarge),
                ),
                child: place.imageUrl.isNotEmpty
                    ? Image.network(
                        place.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: Dimensions.fontTitleMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      categoryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary.withOpacity(0.8),
                        fontSize: Dimensions.fontBodyMedium,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: Dimensions.iconSmall,
                            ),
                            SizedBox(width: Dimensions.spacingTiny / 2),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: Dimensions.fontBodyMedium,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          dynamicDistance,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: Dimensions.fontBodySmall,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: colors.background,
      child: Icon(Icons.image_not_supported, color: colors.iconGrey),
    );
  }
}
