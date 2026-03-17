import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../data/models/gym_details_model.dart';

class GymSmartHeader extends ConsumerWidget {
  final GymDetailsModel gym;
  final AppColors colors;
  static final Logger _logger = Logger('GymSmartHeader');

  const GymSmartHeader({super.key, required this.gym, required this.colors});

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _logger.severe('Error launching maps', e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final userLocation = ref.watch(userLocationProvider);

    final List<String> addressParts = gym.address.split(',');
    final String shortAddress = addressParts.isNotEmpty
        ? '${addressParts[0].trim()} - ${gym.city}'
        : gym.city;

    // Calculate real dynamic distance
    final String dynamicDistance = userLocation != null
        ? LocationService.formatDistance(
            LocationService.calculateDistanceInMeters(
              userLocation,
              gym.location,
            ),
            l10n.km,
            'm',
          )
        : '-- ${l10n.km}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      gym.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimensions.fontHeading1,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.spacingSmall,
                      vertical: Dimensions.spacingTiny,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusPill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: Dimensions.iconSmall,
                        ),
                        SizedBox(width: Dimensions.spacingTiny),
                        Text(
                          gym.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: Dimensions.fontBodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: Dimensions.spacingSmall),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: Dimensions.iconSmall,
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: Dimensions.spacingTiny),
                  Expanded(
                    child: Text(
                      shortAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimensions.fontBodyMedium,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    margin: EdgeInsets.symmetric(
                      horizontal: Dimensions.spacingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    dynamicDistance,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyMedium,
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: Dimensions.spacingMedium),
        GestureDetector(
          onTap: () =>
              _openGoogleMaps(gym.location.latitude, gym.location.longitude),
          child: Container(
            width: Dimensions.fabSize * 0.9,
            height: Dimensions.fabSize * 0.9,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_outlined,
              color: colors.primary,
              size: Dimensions.iconMedium,
            ),
          ),
        ),
      ],
    );
  }
}
