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

    String subtitleText = l10n.fitnessCenter;
    if (place.category == PlaceCategory.restaurant)
      subtitleText = l10n.healthyFood;
    if (place.category == PlaceCategory.trainer)
      subtitleText = l10n.personalTrainer;

    if (place.sports.isNotEmpty) {
      subtitleText = place.sports.join(' • ');
    }

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

    final bool isClosed = place.isTemporarilyClosed || !place.isOpenNow;
    final String closedText = place.isTemporarilyClosed
        ? l10n.temporarilyClosed
        : l10n.closed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Dimensions.widthPercent(65.0, max: 280.0),
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
              color: colors.shadow.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(Dimensions.borderRadiusLarge),
                    ),
                    child: place.imageUrl.isNotEmpty
                        ? Image.network(
                            place.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPremiumPlaceholder(),
                          )
                        : _buildPremiumPlaceholder(),
                  ),
                  if (isClosed)
                    Positioned(
                      top: Dimensions.spacingSmall,
                      left: Dimensions.spacingSmall,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.spacingMedium,
                          vertical: Dimensions.spacingTiny,
                        ),
                        decoration: BoxDecoration(
                          color: colors.error.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: colors.surface,
                              size: Dimensions.iconSmall,
                            ),
                            SizedBox(width: Dimensions.spacingTiny),
                            Text(
                              closedText,
                              style: TextStyle(
                                color: colors.surface,
                                fontSize: Dimensions.fontBodySmall,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: Dimensions.fontTitleMedium,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: Dimensions.spacingTiny),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: Dimensions.fontBodySmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (place.rating > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: colors.star,
                                size: Dimensions.iconSmall * 1.2,
                              ),
                              SizedBox(width: Dimensions.spacingTiny),
                              Text(
                                place.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: Dimensions.fontBodyMedium,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: colors.primary,
                              size: Dimensions.iconSmall,
                            ),
                            SizedBox(width: Dimensions.spacingTiny),
                            Text(
                              dynamicDistance,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: Dimensions.fontBodySmall,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  Widget _buildPremiumPlaceholder() {
    return Container(
      width: double.infinity,
      color: colors.primary.withOpacity(0.05),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: colors.primary.withOpacity(0.3),
          size: Dimensions.iconLarge,
        ),
      ),
    );
  }
}
