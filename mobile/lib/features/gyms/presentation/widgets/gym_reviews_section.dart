import 'package:flutter/material.dart';
import 'package:fitzone/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/models/gym_details_model.dart';
import 'gym_section_title.dart';

class GymReviewsSection extends StatelessWidget {
  final List<GymReview> reviews;
  final double averageRating;
  final int totalReviews;
  final AppColors colors;

  const GymReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GymSectionTitle(
              title: l10n.reviews,
              colors: colors,
            ), // Needs translation
            TextButton(
              onPressed: () {}, // TODO: Open all reviews screen
              child: Text(
                l10n.viewAllReviews,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Dimensions.spacingSmall),

        // Horizontal list of review cards
        SizedBox(
          height: Dimensions.heightPercent(20.0).clamp(140.0, 180.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: Dimensions.spacingMedium),
            itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(GymReview review) {
    return Container(
      width: Dimensions.widthPercent(70.0).clamp(250.0, 320.0),
      padding: EdgeInsets.all(Dimensions.spacingMedium),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        border: Border.all(color: colors.iconGrey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontSize: Dimensions.fontBodyMedium,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: colors.primary,
                    size: Dimensions.iconSmall,
                  ), // Using primary instead of hardcoded amber
                  SizedBox(width: Dimensions.spacingTiny),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: Dimensions.spacingSmall),
          Expanded(
            child: Text(
              review.comment,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: Dimensions.fontBodySmall,
                height: 1.4,
              ),
            ),
          ),
          Text(
            review.date,
            style: TextStyle(
              color: colors.iconGrey,
              fontSize: Dimensions.fontBodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
