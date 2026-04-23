import 'package:flutter/material.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/models/gym_details_model.dart';
import 'package:intl/intl.dart';

class GymLiveStatus extends StatefulWidget {
  final GymDetailsModel gym;
  final AppColors colors;

  const GymLiveStatus({super.key, required this.gym, required this.colors});

  @override
  State<GymLiveStatus> createState() => _GymLiveStatusState();
}

class _GymLiveStatusState extends State<GymLiveStatus> {
  late String _selectedGender;
  bool _showFullSchedule = false;

  @override
  void initState() {
    super.initState();
    if (widget.gym.gender.toLowerCase() == 'women') {
      _selectedGender = 'women';
    } else {
      _selectedGender = 'men';
    }
  }

  String _getTodayName() {
    return DateFormat('EEEE').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isMixed = widget.gym.gender.toLowerCase() == 'mixed';
    final Map<String, String> currentHours =
        widget.gym.weeklyHours[_selectedGender] ?? {};
    final String todayHours = currentHours[_getTodayName()] ?? '--';

    final bool isClosed =
        widget.gym.isTemporarilyClosed || !widget.gym.isOpenNow;
    final String statusText = widget.gym.isTemporarilyClosed
        ? l10n.temporarilyClosed
        : (widget.gym.isOpenNow ? l10n.openNow : l10n.closed);
    final Color statusColor = isClosed
        ? widget.colors.error
        : widget.colors.success;

    return Container(
      decoration: BoxDecoration(
        color: widget.colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        border: Border.all(
          color: widget.colors.iconGrey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colors.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMixed)
            Padding(
              padding: EdgeInsets.fromLTRB(
                Dimensions.spacingMedium,
                Dimensions.spacingMedium,
                Dimensions.spacingMedium,
                0,
              ),
              child: _buildGenderToggle(l10n),
            ),
          Padding(
            padding: EdgeInsets.all(Dimensions.spacingMedium),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Dimensions.spacingMedium),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isClosed
                        ? Icons.lock_outline_rounded
                        : Icons.lock_open_rounded,
                    color: statusColor,
                    size: Dimensions.iconLarge,
                  ),
                ),
                SizedBox(width: Dimensions.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: Dimensions.fontTitleMedium,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(height: Dimensions.spacingTiny),
                      // ARCHITECTURE FIX: Using Localized "Today"
                      Text(
                        '${l10n.today}: $todayHours',
                        style: TextStyle(
                          fontSize: Dimensions.fontBodyMedium,
                          color: widget.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showFullSchedule
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: widget.colors.primary,
                  ),
                  onPressed: () =>
                      setState(() => _showFullSchedule = !_showFullSchedule),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.colors.primary.withValues(
                      alpha: 0.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showFullSchedule
                ? Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.spacingMedium,
                      vertical: Dimensions.spacingSmall,
                    ),
                    color: widget.colors.background.withValues(alpha: 0.5),
                    child: Column(
                      children: currentHours.entries.map((entry) {
                        final bool isToday = entry.key == _getTodayName();
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color: isToday
                                      ? widget.colors.primary
                                      : widget.colors.textSecondary,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                entry.value,
                                style: TextStyle(
                                  color: isToday
                                      ? widget.colors.primary
                                      : widget.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Divider(
            color: widget.colors.iconGrey.withValues(alpha: 0.1),
            height: 1,
          ),
          Padding(
            padding: EdgeInsets.all(Dimensions.spacingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.liveStatus}: ${_getCrowdText(widget.gym.currentCrowdLevel, l10n)}',
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyMedium,
                    color: _getCrowdColor(widget.gym.currentCrowdLevel),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      _buildCrowdSegment(
                        _getCrowdColor(widget.gym.currentCrowdLevel),
                        isActive: true,
                      ),
                      SizedBox(width: 4),
                      _buildCrowdSegment(
                        _getCrowdColor(widget.gym.currentCrowdLevel),
                        isActive:
                            widget.gym.currentCrowdLevel != CrowdLevel.low,
                      ),
                      SizedBox(width: 4),
                      _buildCrowdSegment(
                        _getCrowdColor(widget.gym.currentCrowdLevel),
                        isActive:
                            widget.gym.currentCrowdLevel == CrowdLevel.high,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderToggle(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.colors.background,
        borderRadius: BorderRadius.circular(Dimensions.radiusPill),
      ),
      child: Row(
        children: [
          // ARCHITECTURE FIX: Localized names
          _buildToggleOption(
            title: l10n.menSchedule,
            value: 'men',
            icon: Icons.male_rounded,
          ),
          _buildToggleOption(
            title: l10n.womenSchedule,
            value: 'women',
            icon: Icons.female_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final bool isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: Dimensions.spacingSmall),
          decoration: BoxDecoration(
            color: isSelected ? widget.colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimensions.radiusPill),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.colors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: Dimensions.iconSmall,
                color: isSelected ? Colors.white : widget.colors.textSecondary,
              ),
              SizedBox(width: Dimensions.spacingTiny),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : widget.colors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: Dimensions.fontBodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdSegment(Color color, {required bool isActive}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 6.0,
        decoration: BoxDecoration(
          color: isActive
              ? color
              : widget.colors.iconGrey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Dimensions.radiusPill),
        ),
      ),
    );
  }

  String _getCrowdText(CrowdLevel level, AppLocalizations l10n) {
    switch (level) {
      case CrowdLevel.low:
        return l10n.crowdLow;
      case CrowdLevel.medium:
        return l10n.crowdMedium;
      case CrowdLevel.high:
        return l10n.crowdHigh;
    }
  }

  Color _getCrowdColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return widget.colors.success;
      case CrowdLevel.medium:
        return widget.colors.warning;
      case CrowdLevel.high:
        return widget.colors.error;
    }
  }
}
