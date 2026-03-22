import 'package:flutter/material.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/models/gym_details_model.dart';

class GymLiveStatus extends StatelessWidget {
  final GymDetailsModel gym;
  final AppColors colors;

  const GymLiveStatus({super.key, required this.gym, required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bool isClosed = gym.isTemporarilyClosed || !gym.isOpenNow;
    final String statusText = gym.isTemporarilyClosed
        ? l10n.temporarilyClosed
        : (gym.isOpenNow ? l10n.openNow : l10n.closed);
    final Color statusColor = isClosed ? colors.error : colors.success;

    String crowdText;
    Color crowdColor;

    switch (gym.currentCrowdLevel) {
      case CrowdLevel.low:
        crowdText = l10n.crowdLow;
        crowdColor = colors.success;
        break;
      case CrowdLevel.medium:
        crowdText = l10n.crowdMedium;
        crowdColor = colors.warning;
        break;
      case CrowdLevel.high:
        crowdText = l10n.crowdHigh;
        crowdColor = colors.error;
        break;
    }

    final bool isLow = gym.currentCrowdLevel == CrowdLevel.low;
    final bool isMed = gym.currentCrowdLevel == CrowdLevel.medium;
    final bool isHigh = gym.currentCrowdLevel == CrowdLevel.high;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(color: colors.iconGrey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    isClosed
                        ? Icons.lock_outline_rounded
                        : Icons.lock_open_rounded,
                    color: statusColor,
                    size: Dimensions.iconMedium,
                  ),
                  SizedBox(width: Dimensions.spacingSmall),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: Dimensions.fontBodyMedium,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${gym.openingTime.substring(0, 5)} - ${gym.closingTime.substring(0, 5)}',
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: Dimensions.spacingSmall),
                Row(
                  children: [
                    _buildCrowdSegment(crowdColor, isActive: true),
                    SizedBox(width: Dimensions.spacingTiny),
                    _buildCrowdSegment(crowdColor, isActive: isMed || isHigh),
                    SizedBox(width: Dimensions.spacingTiny),
                    _buildCrowdSegment(crowdColor, isActive: isHigh),
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
        duration: const Duration(milliseconds: 300),
        height: 6.0,
        decoration: BoxDecoration(
          color: isActive ? color : colors.iconGrey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(Dimensions.radiusPill),
        ),
      ),
    );
  }
}
