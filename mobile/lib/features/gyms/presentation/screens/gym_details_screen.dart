import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../providers/gym_details_provider.dart';

import '../widgets/gym_image_gallery.dart';
import '../widgets/gym_smart_header.dart';
import '../widgets/gym_live_status.dart';
import '../widgets/gym_amenities_section.dart';
import '../widgets/gym_sports_section.dart';
import '../widgets/gym_plans_section.dart';
import '../widgets/gym_reviews_section.dart';

class GymDetailsScreen extends ConsumerWidget {
  final int gymId;
  static final Logger _logger = Logger('GymDetailsScreen');

  const GymDetailsScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AppColors colors = isDarkMode ? DarkColors() : LightColors();

    final gymDetailsAsync = ref.watch(gymDetailsProvider(gymId));

    return Scaffold(
      backgroundColor: colors.background,
      body: gymDetailsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primary)),
        error: (error, stack) {
          _logger.severe('Failed to load gym details', error, stack);
          return _buildErrorState(context, colors, l10n, ref);
        },
        data: (gym) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              GymImageGallery(
                images: gym.images,
                fallbackLogo: gym.branchLogo,
                colors: colors,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GymSmartHeader(gym: gym, colors: colors),
                      SizedBox(height: Dimensions.spacingLarge),

                      GymLiveStatus(gym: gym, colors: colors),
                      SizedBox(height: Dimensions.spacingExtraLarge),

                      if (gym.description.isNotEmpty) ...[
                        Text(
                          l10n.aboutGym,
                          style: TextStyle(
                            fontSize: Dimensions.fontHeading2,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingSmall),
                        Text(
                          gym.description,
                          style: TextStyle(
                            fontSize: Dimensions.fontBodyLarge,
                            color: colors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingExtraLarge),
                      ],

                      if (gym.sports.isNotEmpty) ...[
                        GymSportsSection(sports: gym.sports, colors: colors),
                        SizedBox(height: Dimensions.spacingExtraLarge),
                      ],

                      if (gym.amenities.isNotEmpty) ...[
                        GymAmenitiesSection(
                          amenities: gym.amenities,
                          colors: colors,
                        ),
                        SizedBox(height: Dimensions.spacingExtraLarge),
                      ],

                      if (gym.plans.isNotEmpty) ...[
                        // ARCHITECTURE FIX: Pass the real gym name to the plans section
                        GymPlansSection(
                          plans: gym.plans,
                          colors: colors,
                          gymId: gymId,
                          gymName: gym.providerName,
                        ),
                        SizedBox(height: Dimensions.spacingExtraLarge),
                      ],

                      if (gym.reviews.isNotEmpty) ...[
                        GymReviewsSection(
                          reviews: gym.reviews,
                          averageRating: gym.rating,
                          totalReviews: gym.totalReviews,
                          colors: colors,
                        ),
                        SizedBox(height: Dimensions.spacingExtraLarge),
                      ],

                      SizedBox(height: Dimensions.spacingExtraLarge * 2),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppColors colors,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: Dimensions.iconLarge * 2,
            color: colors.error,
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Text(
            l10n.errorLoadingDetails,
            style: TextStyle(
              fontSize: Dimensions.fontTitleMedium,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: Dimensions.spacingLarge),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.surface,
            ),
            onPressed: () => ref.invalidate(gymDetailsProvider(gymId)),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
