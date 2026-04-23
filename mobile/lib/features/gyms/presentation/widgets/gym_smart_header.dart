import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/models/gym_details_model.dart';

class GymSmartHeader extends ConsumerWidget {
  final GymDetailsModel gym;
  final AppColors colors;

  const GymSmartHeader({super.key, required this.gym, required this.colors});

  /// Intelligent logic to strictly define gender allocation without using "mixed"
  String _getGenderText(String gender, AppLocalizations l10n) {
    if (gender.toLowerCase() == 'men') return l10n.menOnly ?? 'للرجال فقط';
    if (gender.toLowerCase() == 'women') return l10n.womenOnly ?? 'للنساء فقط';
    return l10n.menAndWomen ?? 'للرجال والنساء';
  }

  /// Assigns highly specific icons based on gender allocation
  IconData _getGenderIcon(String gender) {
    if (gender.toLowerCase() == 'men') return Icons.male_rounded;
    if (gender.toLowerCase() == 'women') return Icons.female_rounded;
    return Icons.people_alt_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // --- Location & Distance Logic ---
    final locationState = ref.watch(userLocationProvider);
    final userLocation = locationState.location;
    final LocationService locationService = ref.read(locationServiceProvider);

    final String dynamicDistance = userLocation != null && gym.location != null
        ? locationService.formatDistance(
            locationService.calculateDistanceInMeters(
              userLocation,
              gym.location!,
            ),
            kmLabel: l10n.km,
            mLabel: 'm',
          )
        : '--';

    // --- Extracted Data ---
    final String genderText = _getGenderText(gym.gender, l10n);
    final IconData genderIcon = _getGenderIcon(gym.gender);
    final String ratingValue = gym.rating > 0
        ? gym.rating.toStringAsFixed(1)
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. Branding Header (Logo + Name + Provider) ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Premium Circular Logo
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.iconGrey.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: gym.branchLogo != null && gym.branchLogo!.isNotEmpty
                    ? Image.network(
                        gym.branchLogo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackLogo(),
                      )
                    : _buildFallbackLogo(),
              ),
            ),
            SizedBox(width: Dimensions.spacingMedium),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Dimensions.fontHeading1 * 1.05,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      height: 1.2,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingTiny),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.corporate_fare_rounded,
                          size: 12,
                          color: colors.primary,
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingSmall),
                      Expanded(
                        child: Text(
                          gym.providerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: Dimensions.spacingExtraLarge),

        // --- 2. The Premium Dashboard Stats Card ---
        Container(
          padding: EdgeInsets.symmetric(vertical: Dimensions.spacingMedium),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
            border: Border.all(color: colors.iconGrey.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Stat 1: Rating
              _buildDashboardItem(
                icon: Icons.star_rounded,
                iconColor: colors.star,
                value: ratingValue,
                label: '(${gym.totalReviews}) ${l10n.reviewsCount ?? 'مراجعة'}',
                textColor: colors.textPrimary,
              ),

              _buildVerticalDivider(),

              // Stat 2: Distance
              _buildDashboardItem(
                icon: Icons.route_rounded,
                iconColor: colors.primary,
                value: dynamicDistance,
                label: l10n.distanceFromYou ?? 'عن موقعك',
                textColor: colors.primary,
              ),

              _buildVerticalDivider(),

              // Stat 3: Gender Allocation
              _buildDashboardItem(
                icon: genderIcon,
                iconColor: colors.primary,
                value: genderText,
                label: l10n.gymAllocation ?? 'التخصيص',
                textColor: colors.textPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a vertical separator for the dashboard
  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: colors.iconGrey.withValues(alpha: 0.2),
    );
  }

  /// Builds an individual stat column for the dashboard (With Auto-Scaling to prevent truncation)
  Widget _buildDashboardItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color textColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 16),
              SizedBox(width: Dimensions.spacingTiny),
              // ARCHITECTURE FIX: FittedBox ensures text shrinks elegantly instead of truncating
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: Dimensions.fontTitleMedium,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingTiny),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Center(
      child: Icon(
        Icons.fitness_center_rounded,
        color: colors.primary.withValues(alpha: 0.3),
        size: 30,
      ),
    );
  }
}
