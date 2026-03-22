import 'package:flutter/material.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/models/gym_details_model.dart';
import 'gym_section_title.dart';

class GymSportsSection extends StatelessWidget {
  final List<GymSport> sports;
  final AppColors colors;

  const GymSportsSection({
    super.key,
    required this.sports,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (sports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GymSectionTitle(
          title: AppLocalizations.of(context)!.sports,
          colors: colors,
        ),
        SizedBox(height: Dimensions.spacingMedium),
        Wrap(
          spacing: Dimensions.spacingMedium,
          runSpacing: Dimensions.spacingMedium,
          children: sports.map((sport) => _buildSportChip(sport)).toList(),
        ),
      ],
    );
  }

  Widget _buildSportChip(GymSport sport) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.spacingMedium,
        vertical: Dimensions.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colors.iconGrey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sport.imageUrl.isNotEmpty)
            Image.network(
              sport.imageUrl,
              width: Dimensions.iconMedium,
              height: Dimensions.iconMedium,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackIcon(),
            )
          else
            _buildFallbackIcon(),

          SizedBox(width: Dimensions.spacingSmall),
          Text(
            sport.name,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: Dimensions.fontBodyMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Icon(
      Icons.sports_score_rounded,
      size: Dimensions.iconMedium,
      color: colors.primary,
    );
  }
}
