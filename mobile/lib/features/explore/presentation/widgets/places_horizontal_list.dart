import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../data/models/gym_model.dart';
import 'place_info_card.dart';

// State to track which card is currently expanded
final expandedCardProvider = StateProvider<int?>((ref) => null);

class PlacesHorizontalList extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (places.isEmpty) return const SizedBox.shrink();

    final expandedId = ref.watch(expandedCardProvider);

    // Smoothly animate the entire list height to accommodate the expanded card
    final double listHeight = expandedId != null
        ? Dimensions.mapCardExpandedHeight + Dimensions.spacingMedium
        : Dimensions.mapCardCollapsedHeight + Dimensions.spacingMedium;

    return GestureDetector(
      onTap: () {
        if (expandedId != null) {
          ref.read(expandedCardProvider.notifier).state = null;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutBack,
        height: listHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: places.length,
          clipBehavior: Clip.none,
          padding: EdgeInsets.only(
            right: Dimensions.spacingLarge,
            left: Dimensions.spacingMedium,
            bottom: Dimensions.spacingMedium,
          ),
          itemBuilder: (context, index) {
            final place = places[index];
            final bool isExpanded = expandedId == place.id;

            return Align(
              alignment: Alignment.bottomCenter,
              child: PlaceInfoCard(
                place: place,
                colors: colors,
                isExpanded: isExpanded,
                onExpandToggled: (expanded) {
                  if (expanded) {
                    ref.read(expandedCardProvider.notifier).state = place.id;
                  } else {
                    ref.read(expandedCardProvider.notifier).state = null;
                  }
                },
                onDetailsTap: () => onPlaceTap(place),
              ),
            );
          },
        ),
      ),
    );
  }
}
