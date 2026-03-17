import 'package:flutter/material.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../data/models/gym_details_model.dart';

class GymLiveStatus extends StatelessWidget {
  final GymDetailsModel gym;
  final AppColors colors;

  const GymLiveStatus({super.key, required this.gym, required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String crowdText;
    Color crowdColor;

    switch (gym.currentCrowdLevel) {
      case CrowdLevel.low:
        crowdText = l10n.crowdLow;
        crowdColor = Colors.green;
        break;
      case CrowdLevel.medium:
        crowdText = l10n.crowdMedium;
        crowdColor = Colors.orange;
        break;
      case CrowdLevel.high:
        crowdText = l10n.crowdHigh;
        crowdColor = colors.error;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        border: Border.all(color: colors.iconGrey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expandable Weekly Hours Section
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(
                horizontal: Dimensions.spacingMedium,
              ),
              childrenPadding: EdgeInsets.only(
                left: Dimensions.spacingMedium,
                right: Dimensions.spacingMedium,
                bottom: Dimensions.spacingMedium,
              ),
              title: Row(
                children: [
                  Icon(
                    gym.isOpenNow
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    color: gym.isOpenNow ? Colors.green : colors.error,
                    size: Dimensions.iconMedium,
                  ),
                  SizedBox(width: Dimensions.spacingSmall),
                  Text(
                    gym.isOpenNow ? l10n.openNow : l10n.closed,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyMedium,
                      fontWeight: FontWeight.bold,
                      color: gym.isOpenNow ? Colors.green : colors.error,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${gym.openingTime} - ${gym.closingTime}',
                    style: TextStyle(
                      fontSize: Dimensions.fontBodySmall,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              children: gym.weeklyHours.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Dimensions.spacingTiny,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: Dimensions.fontBodyMedium,
                        ),
                      ),
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: Dimensions.fontBodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          Divider(color: colors.iconGrey.withOpacity(0.1), height: 1),

          // Crowdedness Section
          Padding(
            padding: EdgeInsets.all(Dimensions.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.liveStatus}: $crowdText',
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyMedium,
                    color: crowdColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Dimensions.spacingSmall),
                Row(
                  children: [
                    _buildCrowdSegment(
                      Colors.green,
                      isActive: gym.currentCrowdLevel != CrowdLevel.low,
                    ),
                    SizedBox(width: Dimensions.spacingTiny),
                    _buildCrowdSegment(
                      Colors.orange,
                      isActive:
                          gym.currentCrowdLevel == CrowdLevel.medium ||
                          gym.currentCrowdLevel == CrowdLevel.high,
                    ),
                    SizedBox(width: Dimensions.spacingTiny),
                    _buildCrowdSegment(
                      colors.error,
                      isActive: gym.currentCrowdLevel == CrowdLevel.high,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdSegment(Color color, {required bool isActive}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: 6.0,
        decoration: BoxDecoration(
          color: isActive ? color : colors.iconGrey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(Dimensions.radiusPill),
        ),
      ),
    );
  }
}
