import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/models/gym_model.dart';
import 'place_info_card.dart';

/// A fully responsive horizontal list view for rendering map locations.
class PlacesHorizontalList extends StatelessWidget {
  final List<GymModel> places;
  final AppColors colors;
  final Function(GymModel) onPlaceTap;

  const PlacesHorizontalList({
    super.key,
    required this.places,
    required this.colors,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();

    // Responsive height: 32% of screen height, constrained within safe bounds
    final double listHeight = Dimensions.heightPercent(
      32.0,
    ).clamp(220.0, 280.0);

    return SizedBox(
      height: listHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: places.length,
        padding: EdgeInsets.only(right: Dimensions.spacingMedium),
        itemBuilder: (context, index) {
          final place = places[index];
          return PlaceInfoCard(
            place: place,
            colors: colors,
            onTap: () => onPlaceTap(place),
          );
        },
      ),
    );
  }
}
