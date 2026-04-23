import 'package:fitzone/core/location/location_provider.dart';
import 'package:fitzone/core/location/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/models/gym_details_model.dart';
import 'gym_section_title.dart';

class GymLocationSection extends ConsumerWidget {
  final GymDetailsModel gym;
  final AppColors colors;
  static final Logger _logger = Logger('GymLocationSection');

  const GymLocationSection({
    super.key,
    required this.gym,
    required this.colors,
  });

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      'http://maps.google.com/maps?q=loc:$lat,$lng',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _logger.severe('Error launching maps', e);
    }
  }

  /// Parses and shortens the long Saudi addresses intelligently.
  String _getShortAddress() {
    if (gym.address.isEmpty) return gym.city;
    final List<String> parts = gym.address.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}، ${parts[1].trim()}'; // Returns Street + Neighborhood
    }
    return gym.address;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gym.location == null) return const SizedBox.shrink();

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final locationState = ref.watch(userLocationProvider);
    final userLocation = locationState.location;
    final LocationService locationService = ref.read(locationServiceProvider);

    final String dynamicDistance = userLocation != null
        ? locationService.formatDistance(
            locationService.calculateDistanceInMeters(
              userLocation,
              gym.location!,
            ),
            kmLabel: l10n.km,
            mLabel: 'm',
          )
        : '-- ${l10n.km}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GymSectionTitle(title: l10n.gymLocation ?? 'Location', colors: colors),
        SizedBox(height: Dimensions.spacingMedium),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            border: Border.all(color: colors.iconGrey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Map Stack (Map + Floating Elements) ---
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(Dimensions.borderRadiusLarge),
                      ),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: gym.location!,
                            zoom: 15.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('gym_loc'),
                              position: gym.location!,
                            ),
                          },
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),

                    // Glassmorphic Distance Badge
                    Positioned(
                      top: Dimensions.spacingMedium,
                      right: Dimensions.spacingMedium,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusPill,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_run_rounded,
                              color: colors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dynamicDistance,
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Premium Floating Action Button for Navigation
                    Positioned(
                      bottom: Dimensions.spacingMedium,
                      left: Dimensions.spacingMedium,
                      child: FloatingActionButton.small(
                        heroTag: 'nav_fab_${gym.id}',
                        backgroundColor: colors.primary,
                        elevation: 4,
                        onPressed: () => _openGoogleMaps(
                          gym.location!.latitude,
                          gym.location!.longitude,
                        ),
                        child: const Icon(
                          Icons.directions_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. Clean Text Section ---
              Padding(
                padding: EdgeInsets.all(Dimensions.spacingMedium),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(Dimensions.spacingMedium),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: colors.primary,
                        size: Dimensions.iconMedium,
                      ),
                    ),
                    SizedBox(width: Dimensions.spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gym.city,
                            style: TextStyle(
                              fontSize: Dimensions.fontBodyLarge,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: Dimensions.spacingTiny),
                          Text(
                            _getShortAddress(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Dimensions.fontBodyMedium,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
