import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/gym_model.dart';

class PlaceInfoCard extends ConsumerWidget {
  final GymModel place;
  final AppColors colors;
  final bool isExpanded;
  final Function(bool) onExpandToggled;
  final VoidCallback onDetailsTap;

  const PlaceInfoCard({
    super.key,
    required this.place,
    required this.colors,
    required this.isExpanded,
    required this.onExpandToggled,
    required this.onDetailsTap,
  });

  double _calculateDistanceFallback(LatLng p1, LatLng p2) {
    const double earthRadius = 6371;
    final double dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final double dLon = _degreesToRadians(p2.longitude - p1.longitude);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(p1.latitude)) *
            math.cos(_degreesToRadians(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  Color _getCrowdColor(CrowdLevel level, AppColors c) {
    switch (level) {
      case CrowdLevel.low:
        return c.success;
      case CrowdLevel.medium:
        return c.warning;
      case CrowdLevel.high:
        return c.error;
    }
  }

  double _getCrowdGaugeValue(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return 30.0;
      case CrowdLevel.medium:
        return 60.0;
      case CrowdLevel.high:
        return 90.0;
    }
  }

  String _getCrowdText(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return 'ازدحام منخفض';
      case CrowdLevel.medium:
        return 'ازدحام متوسط';
      case CrowdLevel.high:
        return 'ازدحام مرتفع';
    }
  }

  IconData _getSportIconFallback(String sportStr) {
    final String s = sportStr.toLowerCase();
    if (s.contains('box') || s.contains('mma')) return Icons.sports_mma_rounded;
    if (s.contains('foot') || s.contains('socc'))
      return Icons.sports_soccer_rounded;
    if (s.contains('swim') || s.contains('pool')) return Icons.pool_rounded;
    if (s.contains('tenn')) return Icons.sports_tennis_rounded;
    return Icons.fitness_center_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final locationState = ref.watch(userLocationProvider);
    final userLocation = locationState.location;

    String dynamicDistance = '-- ${l10n.km}';
    if (place.distanceKm != null) {
      dynamicDistance = '${place.distanceKm!.toStringAsFixed(1)} ${l10n.km}';
    } else if (userLocation != null) {
      final double calculatedDist = _calculateDistanceFallback(
        userLocation,
        place.location,
      );
      dynamicDistance = '${calculatedDist.toStringAsFixed(1)} ${l10n.km}';
    }

    final bool isClosed = place.isTemporarilyClosed || !place.isOpenNow;
    final Color crowdColor = _getCrowdColor(place.crowdLevel, colors);

    // MOCK DATA: For UI presentation
    final bool acceptsRoaming = true;
    final int roamingPrice = 50;

    return GestureDetector(
      onTap: onDetailsTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutBack,
        width: Dimensions.screenWidth * 0.88,
        height: isExpanded
            ? Dimensions.mapCardExpandedHeight
            : Dimensions.mapCardCollapsedHeight,
        margin: EdgeInsets.only(right: Dimensions.spacingMedium),
        padding: EdgeInsets.all(Dimensions.spacingMedium),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- HEADER: IMAGE & MAIN INFO ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LEFT: Syncfusion Gauges & Image
                SizedBox(
                  width: 95,
                  height: 95,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      SfRadialGauge(
                        axes: <RadialAxis>[
                          RadialAxis(
                            minimum: 0,
                            maximum: 5,
                            showLabels: false,
                            showTicks: false,
                            startAngle: 140,
                            endAngle: 140,
                            radiusFactor: 1.0,
                            axisLineStyle: AxisLineStyle(
                              thickness: 4,
                              color: colors.primary.withValues(alpha: 0.05),
                            ),
                            pointers: <GaugePointer>[
                              RangePointer(
                                value: place.rating,
                                width: 4,
                                color: colors.star,
                                enableAnimation: true,
                                animationDuration: 1500,
                                cornerStyle: CornerStyle.bothCurve,
                              ),
                            ],
                          ),
                          RadialAxis(
                            minimum: 0,
                            maximum: 100,
                            showLabels: false,
                            showTicks: false,
                            startAngle: 270,
                            endAngle: 270,
                            radiusFactor: 0.85,
                            axisLineStyle: AxisLineStyle(
                              thickness: 4,
                              color: colors.primary.withValues(alpha: 0.05),
                            ),
                            pointers: <GaugePointer>[
                              RangePointer(
                                value: _getCrowdGaugeValue(place.crowdLevel),
                                width: 4,
                                color: crowdColor,
                                enableAnimation: true,
                                animationDuration: 1500,
                                cornerStyle: CornerStyle.bothCurve,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withValues(alpha: 0.05),
                          image:
                              place.branchLogo != null &&
                                  place.branchLogo!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(place.branchLogo!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            place.branchLogo == null ||
                                place.branchLogo!.isEmpty
                            ? Icon(
                                Icons.fitness_center_rounded,
                                color: colors.primary.withValues(alpha: 0.3),
                              )
                            : null,
                      ),
                      if (place.rating > 0)
                        Positioned(
                          bottom: -2,
                          left: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.star,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.star.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  place.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(width: Dimensions.spacingMedium),

                // 2. RIGHT: Texts & Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: Dimensions.fontTitleMedium,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: Dimensions.spacingSmall),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isClosed
                                  ? colors.error.withValues(alpha: 0.1)
                                  : colors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusPill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isClosed
                                        ? colors.error
                                        : colors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isClosed ? 'مغلق' : 'مفتوح',
                                  style: TextStyle(
                                    color: isClosed
                                        ? colors.error
                                        : colors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: crowdColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusPill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: crowdColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _getCrowdText(place.crowdLevel),
                                  style: TextStyle(
                                    color: crowdColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: Dimensions.spacingMedium),

                      if (place.sports.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: place.sports.take(4).map((s) {
                            return Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Icon(
                                _getSportIconFallback(s),
                                color: colors.primary,
                                size: 14,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // --- MIDDLE: BOTTOM ACTION ROW (ALL IN ONE LINE) ---
            // ARCHITECTURE FIX: Everything beautifully aligned on a single row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left: Distance and Roaming (Scrollable to prevent overflow on small screens)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Distance Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusPill,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_walk_rounded,
                                color: colors.primary,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                dynamicDistance,
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: Dimensions.spacingSmall),

                        // Roaming Badge
                        if (acceptsRoaming)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusPill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  color: colors.warning,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "تجوال: $roamingPrice ر.س",
                                  style: TextStyle(
                                    color: colors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: Dimensions.spacingSmall),

                // Right: Price & Expand Chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (place.minPrice != null && place.minPrice! > 0)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            place.minPrice!.toStringAsFixed(0),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: Dimensions.fontHeading1, // Big and bold
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 2),
                          Text(
                            l10n.sar,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(width: Dimensions.spacingSmall),

                    // The Expand Toggle Button
                    GestureDetector(
                      onTap: () => onExpandToggled(!isExpanded),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // --- BOTTOM: EXPANDED DASHBOARD ---
            if (isExpanded) ...[
              SizedBox(height: Dimensions.spacingMedium),
              Divider(color: colors.iconGrey.withValues(alpha: 0.2)),
              SizedBox(height: Dimensions.spacingSmall),

              // 1. Vibe Score
              _buildSyncfusionEnergyBar(
                title: "Vibe Score",
                icon: Icons.bolt_rounded,
                progress: 55,
                color: colors.warning,
                textColor: colors.textPrimary,
              ),

              SizedBox(height: Dimensions.spacingSmall),

              // 2. Specific Stats
              _buildSyncfusionEnergyBar(
                title: "نظافة",
                progress: 88,
                color: colors.primary,
                textColor: colors.textSecondary,
              ),
              SizedBox(height: Dimensions.spacingSmall),
              _buildSyncfusionEnergyBar(
                title: "معدات",
                progress: 75,
                color: colors.primary,
                textColor: colors.textSecondary,
              ),
              SizedBox(height: Dimensions.spacingSmall),
              _buildSyncfusionEnergyBar(
                title: "مدربون",
                progress: 92,
                color: colors.primary,
                textColor: colors.textSecondary,
              ),

              SizedBox(height: Dimensions.spacingMedium),

              // 3. Full Detail Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onDetailsTap,
                  icon: Icon(Icons.flash_on_rounded, size: 18),
                  label: Text(
                    "عرض التفاصيل الكاملة",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncfusionEnergyBar({
    required String title,
    IconData? icon,
    required double progress,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) Icon(icon, color: color, size: 16),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 12,
            child: SfLinearGauge(
              minimum: 0,
              maximum: 100,
              showLabels: false,
              showTicks: false,
              axisTrackStyle: LinearAxisTrackStyle(
                thickness: 6,
                color: color.withValues(alpha: 0.15),
                edgeStyle: LinearEdgeStyle.bothCurve,
              ),
              barPointers: [
                LinearBarPointer(
                  value: progress,
                  thickness: 6,
                  color: color,
                  edgeStyle: LinearEdgeStyle.bothCurve,
                  animationDuration: 1500,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text(
            '${progress.toInt()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
