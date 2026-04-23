import 'package:fitzone/core/location/location_provider.dart';
import 'package:fitzone/core/location/location_service.dart';
import 'package:fitzone/core/theme/app_colors.dart';
import 'package:fitzone/core/theme/app_dimensions.dart';
import 'package:fitzone/features/explore/data/models/gym_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitzone/l10n/app_localizations.dart';

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

  String _getLocalizedGender(String gender, AppLocalizations l10n) {
    if (gender.toLowerCase() == 'men') return l10n.men ?? 'رجال';
    if (gender.toLowerCase() == 'women') return l10n.women ?? 'نساء';
    return 'متاح للجنسين';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final locationState = ref.watch(userLocationProvider);
    final userLocation = locationState.location;
    final LocationService locationService = ref.read(locationServiceProvider);

    String subtitleText = l10n.fitnessCenter;
    if (place.category == PlaceCategory.restaurant)
      subtitleText = l10n.healthyFood;
    if (place.category == PlaceCategory.trainer)
      subtitleText = l10n.personalTrainer;
    if (place.sports.isNotEmpty) subtitleText = place.sports.join(' • ');

    final String dynamicDistance =
        userLocation != null && place.distanceKm != null
        ? '${place.distanceKm!.toStringAsFixed(1)} ${l10n.km}'
        : '-- ${l10n.km}';

    final bool isClosed = place.isTemporarilyClosed || !place.isOpenNow;
    final String closedText = place.isTemporarilyClosed
        ? l10n.temporarilyClosed
        : l10n.closed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Dimensions.widthPercent(70.0, max: 280.0),
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
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ARCHITECTURE FIX: Changed flex ratio to 4:6 to give text more breathing room, preventing Overflow
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(Dimensions.borderRadiusLarge),
                    ),
                    child:
                        place.branchLogo != null && place.branchLogo!.isNotEmpty
                        ? Image.network(
                            place.branchLogo!,
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.95),
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
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              closedText,
                              style: TextStyle(
                                color: colors.surface,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: Dimensions.spacingSmall,
                    right: Dimensions.spacingSmall,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            place.gender.toLowerCase() == 'women'
                                ? Icons.female_rounded
                                : (place.gender.toLowerCase() == 'men'
                                      ? Icons.male_rounded
                                      : Icons.people_alt_rounded),
                            color: colors.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getLocalizedGender(place.gender, l10n),
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 10,
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
              flex: 6, // More space for text to prevent 8.4px overflow
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.spacingMedium,
                  vertical: Dimensions.spacingSmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      place.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: Dimensions.fontTitleMedium,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      place.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: Dimensions.fontBodySmall,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primary.withValues(alpha: 0.8),
                        fontSize: Dimensions.fontBodySmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                place.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusPill,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: colors.primary,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                dynamicDistance,
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  Widget _buildPremiumPlaceholder() {
    return Container(
      width: double.infinity,
      color: colors.primary.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: colors.primary.withValues(alpha: 0.3),
          size: Dimensions.iconLarge,
        ),
      ),
    );
  }
}
