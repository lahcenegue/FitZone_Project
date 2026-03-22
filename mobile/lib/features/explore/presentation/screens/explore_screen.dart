import 'dart:async';

import 'package:fitzone/core/location/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import 'package:fitzone/core/routing/app_router.dart';

import '../widgets/explore_search_bar.dart';
import '../widgets/map_zoom_controls.dart';
import '../widgets/map_location_button.dart';
import '../widgets/places_horizontal_list.dart';

import '../../data/models/gym_model.dart';
import '../providers/explore_provider.dart';
import 'package:fitzone/features/explore/presentation/utils/map_marker_generator.dart';

import '../providers/explore_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final Logger _logger = Logger('ExploreScreen');
  final Completer<GoogleMapController> _mapControllerCompleter =
      Completer<GoogleMapController>();

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // Request permission and fetch initial location on startup
    await ref.read(userLocationProvider.notifier).fetchLocation();
    _focusOnUserLocation();
  }

  void _handleSearchTap() {
    // TODO: Transition to Search/Filters logic
    _logger.info('Search bar tapped.');
  }

  void _handleFiltersTap() {
    // TODO: Transition to Search/Filters logic
    _logger.info('Filters icon tapped.');
  }

  Future<void> _handleLocationTap() async {
    await ref.read(userLocationProvider.notifier).fetchLocation();
    _focusOnUserLocation();
  }

  Future<void> _focusOnUserLocation() async {
    final userLocation = ref.read(userLocationProvider);
    if (userLocation != null) {
      try {
        final GoogleMapController controller =
            await _mapControllerCompleter.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(userLocation, 14.5),
        );
      } catch (e, stackTrace) {
        _logger.severe(
          'Failed to focus camera on user location.',
          e,
          stackTrace,
        );
      }
    }
  }

  Future<void> _zoomIn() async {
    try {
      final GoogleMapController controller =
          await _mapControllerCompleter.future;
      await controller.animateCamera(CameraUpdate.zoomIn());
    } catch (e) {
      _logger.severe('Failed to zoom in.', e);
    }
  }

  Future<void> _zoomOut() async {
    try {
      final GoogleMapController controller =
          await _mapControllerCompleter.future;
      await controller.animateCamera(CameraUpdate.zoomOut());
    } catch (e) {
      _logger.severe('Failed to zoom out.', e);
    }
  }

  Future<void> _applyMapStyle(bool isDarkMode) async {
    if (_mapControllerCompleter.isCompleted) {
      try {
        final GoogleMapController controller =
            await _mapControllerCompleter.future;
        final String style = isDarkMode
            ? AppConstants.darkMapStyle
            : AppConstants.lightMapStyle;
        await controller.setMapStyle(style);
      } catch (e) {
        _logger.severe('Failed to update map style.', e);
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
      final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
      _applyMapStyle(isDarkMode);
    }
  }

  Future<void> _onCameraIdle() async {
    try {
      final GoogleMapController controller =
          await _mapControllerCompleter.future;
      final LatLngBounds visibleRegion = await controller.getVisibleRegion();

      if (visibleRegion.southwest.latitude == 0.0) return;

      final currentState = ref.read(exploreFilterProvider);
      ref.read(exploreFilterProvider.notifier).state = currentState.copyWith(
        bounds: visibleRegion,
      );
    } catch (e) {
      _logger.severe('Failed to get visible region.', e);
    }
  }

  Future<void> _focusOnPlace(GymModel place) async {
    try {
      final GoogleMapController controller =
          await _mapControllerCompleter.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(place.location, 16.0),
      );
    } catch (e) {
      _logger.severe('Failed to focus on place.', e);
    }
  }

  Future<void> _generateMapItems(
    List<GymModel> places,
    AppColors colors,
  ) async {
    final Set<Marker> newMarkers = {};
    final Set<Circle> newCircles = {};

    for (final place in places) {
      Color baseColor;
      switch (place.category) {
        case PlaceCategory.gym:
          baseColor = colors.markerGym;
          break;
        case PlaceCategory.restaurant:
          baseColor = colors.markerRestaurant;
          break;
        case PlaceCategory.trainer:
          baseColor = colors.markerTrainer;
          break;
        default:
          baseColor = colors.markerGym;
      }

      final BitmapDescriptor customIcon =
          await MapMarkerGenerator.createCustomMarker(
            markerColor: baseColor,
            logoUrl: place.imageUrl,
          );

      newMarkers.add(
        Marker(
          markerId: MarkerId(place.id.toString()),
          position: place.location,
          icon: customIcon,
          anchor: const Offset(0.5, 0.88),
          onTap: () {
            ref.read(selectedPlaceProvider.notifier).selectPlace(place);
            _focusOnPlace(place);
          },
        ),
      );

      newCircles.add(
        Circle(
          circleId: CircleId('circle_outer_${place.id}'),
          center: place.location,
          radius: 80,
          fillColor: baseColor.withOpacity(0.20),
          strokeWidth: 0,
        ),
      );

      newCircles.add(
        Circle(
          circleId: CircleId('circle_inner_${place.id}'),
          center: place.location,
          radius: 25,
          fillColor: baseColor.withOpacity(0.85),
          strokeColor: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _circles = newCircles;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final EdgeInsets safeArea = MediaQuery.of(context).padding;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AppColors colors = isDarkMode ? DarkColors() : LightColors();

    _applyMapStyle(isDarkMode);

    final asyncPlaces = ref.watch(nearbyPlacesProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);
    final userLocation = ref.watch(userLocationProvider);

    final List<GymModel> allPlaces = asyncPlaces.value ?? [];
    final List<GymModel> displayPlaces = selectedPlace != null
        ? [selectedPlace]
        : allPlaces;

    ref.listen<AsyncValue<List<GymModel>>>(nearbyPlacesProvider, (
      previous,
      next,
    ) {
      next.whenData((places) => _generateMapItems(places, colors));
    });

    final double controlsBottomOffset = displayPlaces.isNotEmpty
        ? Dimensions.heightPercent(32.0).clamp(220.0, 280.0) +
              Dimensions.spacingMedium
        : Dimensions.mapFabBottomOffset;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraIdle: _onCameraIdle,
            onTap: (LatLng _) =>
                ref.read(selectedPlaceProvider.notifier).selectPlace(null),
            initialCameraPosition: const CameraPosition(
              target: AppConstants.defaultMapCenter,
              zoom: AppConstants.defaultMapZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(
              AppConstants.minMapZoom,
              AppConstants.maxMapZoom,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled:
                userLocation != null, // Displays the native blue dot securely
            compassEnabled: false,
            mapToolbarEnabled: false,
            buildingsEnabled: false,
            trafficEnabled: false,
            markers: _markers,
            circles: _circles,
          ),

          Positioned(
            top: safeArea.top + Dimensions.searchBarTopOffset,
            left: Dimensions.spacingMedium,
            right: Dimensions.spacingMedium,
            child: ExploreSearchBar(colors: colors),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: controlsBottomOffset,
            right: Dimensions.spacingMedium,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MapLocationButton(
                  colors: colors,
                  onLocationTap: _handleLocationTap,
                ),
                SizedBox(height: Dimensions.spacingMedium),
                MapZoomControls(
                  colors: colors,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                ),
              ],
            ),
          ),

          if (asyncPlaces.isLoading)
            Positioned(
              top:
                  safeArea.top +
                  Dimensions.searchBarTopOffset +
                  Dimensions.searchBarHeight +
                  Dimensions.spacingMedium,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.spacingMedium,
                    vertical: Dimensions.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: Dimensions.shadowBlurRadius,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: Dimensions.iconSmall,
                        height: Dimensions.iconSmall,
                        child: CircularProgressIndicator(
                          color: colors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingSmall),
                      Text(
                        l10n.searchingArea,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: Dimensions.fontBodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                );
              },
              child: displayPlaces.isNotEmpty
                  ? PlacesHorizontalList(
                      key: ValueKey(displayPlaces.length),
                      places: displayPlaces,
                      colors: colors,
                      onPlaceTap: (place) {
                        context.push(RoutePaths.gymDetailsPath(place.id));
                      },
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ],
      ),
    );
  }
}
