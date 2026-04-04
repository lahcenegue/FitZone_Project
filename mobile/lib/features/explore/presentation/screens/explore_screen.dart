import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';
import 'package:fitzone/l10n/app_localizations.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/storage/storage_provider.dart';

import '../widgets/explore_search_bar.dart';
import '../widgets/map_zoom_controls.dart';
import '../widgets/map_location_button.dart';
import '../widgets/places_horizontal_list.dart';

import '../../data/models/gym_model.dart';
import '../providers/explore_provider.dart';
import 'package:fitzone/features/explore/presentation/utils/map_marker_generator.dart';

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
    // Fetch fresh location in the background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userLocationProvider.notifier).fetchLocation();
    });
  }

  Future<void> _handleLocationTap() async {
    await ref.read(userLocationProvider.notifier).fetchLocation();
    _focusOnUserLocation();
  }

  Future<void> _focusOnUserLocation() async {
    final locationState = ref.read(userLocationProvider);
    if (locationState.location != null) {
      try {
        final GoogleMapController controller =
            await _mapControllerCompleter.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(locationState.location!, 14.5),
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
    } catch (e) {}
  }

  Future<void> _zoomOut() async {
    try {
      final GoogleMapController controller =
          await _mapControllerCompleter.future;
      await controller.animateCamera(CameraUpdate.zoomOut());
    } catch (e) {}
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
      } catch (e) {}
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
      ref
          .read(exploreFilterProvider.notifier)
          .updateFilters(currentState.copyWith(bounds: visibleRegion));
    } catch (e) {}
  }

  Future<void> _generateMapItems(
    List<GymModel> places,
    AppColors colors,
  ) async {
    final Set<Marker> newMarkers = {};
    final Set<Circle> newCircles = {};

    for (final place in places) {
      final baseColor = colors.markerGym; // Dynamic based on type if needed
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

  Future<void> _focusOnPlace(GymModel place) async {
    try {
      final GoogleMapController controller =
          await _mapControllerCompleter.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(place.location, 16.0),
      );
    } catch (e) {}
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
    final locationState = ref.watch(userLocationProvider);

    // Initial map position: Cached location -> Default (Riyadh) -> GPS (once loaded)
    final LatLng initialPos =
        locationState.location ??
        ref.read(storageServiceProvider).getLastLocation() ??
        AppConstants.defaultMapCenter;

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

    final bool showLocationWarning =
        !locationState.isServiceEnabled || !locationState.isPermissionGranted;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraIdle: _onCameraIdle,
            onTap: (LatLng _) =>
                ref.read(selectedPlaceProvider.notifier).selectPlace(null),
            initialCameraPosition: CameraPosition(
              target: initialPos,
              zoom: AppConstants.defaultMapZoom,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(
              AppConstants.minMapZoom,
              AppConstants.maxMapZoom,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: locationState.location != null,
            compassEnabled: false,
            mapToolbarEnabled: false,
            buildingsEnabled: false,
            trafficEnabled: false,
            markers: _markers,
            circles: _circles,
          ),

          // Safe Area Top Elements (Search Bar & Warning Banner)
          Positioned(
            top: safeArea.top + Dimensions.spacingSmall,
            left: Dimensions.spacingMedium,
            right: Dimensions.spacingMedium,
            child: Column(
              children: [
                ExploreSearchBar(colors: colors),

                // Non-intrusive Premium Location Warning Banner
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(
                    top: showLocationWarning ? Dimensions.spacingMedium : 0,
                  ),
                  height: showLocationWarning ? null : 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.spacingMedium,
                        vertical: Dimensions.spacingSmall,
                      ),
                      color: colors.surface.withOpacity(0.95),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_disabled_rounded,
                            color: colors.error,
                            size: Dimensions.iconSmall,
                          ),
                          SizedBox(width: Dimensions.spacingSmall),
                          Expanded(
                            child: Text(
                              l10n.locationWarningText, // <--- Using Localization
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: Dimensions.fontBodySmall,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // If GPS hardware is off -> Open Settings
                              if (!locationState.isServiceEnabled) {
                                ref
                                    .read(userLocationProvider.notifier)
                                    .openSettings();
                              }
                              // If app lacks permission -> Request Permission
                              else if (!locationState.isPermissionGranted) {
                                ref
                                    .read(userLocationProvider.notifier)
                                    .fetchLocation();
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.enable, // <--- Using Localization
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: Dimensions.fontBodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                      onPlaceTap: (place) =>
                          context.push(RoutePaths.gymDetailsPath(place.id)),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ],
      ),
    );
  }
}
