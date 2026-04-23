import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/storage/storage_provider.dart';
import '../../../../core/database/database_service.dart';
import '../../../../l10n/app_localizations.dart';

import '../widgets/explore_search_bar.dart';
import '../widgets/map_zoom_controls.dart';
import '../widgets/map_location_button.dart';
import '../widgets/places_horizontal_list.dart';
import '../utils/map_marker_generator.dart';

import '../../data/models/gym_model.dart';
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
        _logger.warning(
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
    } catch (e, stackTrace) {
      _logger.warning('Failed to zoom in map', e, stackTrace);
    }
  }

  Future<void> _zoomOut() async {
    try {
      final GoogleMapController controller =
          await _mapControllerCompleter.future;
      await controller.animateCamera(CameraUpdate.zoomOut());
    } catch (e, stackTrace) {
      _logger.warning('Failed to zoom out map', e, stackTrace);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
    }
  }

  Future<void> _onCameraIdle() async {
    try {
      final GoogleMapController controller =
          await _mapControllerCompleter.future;
      final LatLngBounds visibleRegion = await controller.getVisibleRegion();

      if (visibleRegion.southwest.latitude == 0.0) {
        return;
      }

      final currentState = ref.read(exploreFilterProvider);
      ref
          .read(exploreFilterProvider.notifier)
          .updateFilters(currentState.copyWith(bounds: visibleRegion));
    } catch (e, stackTrace) {
      _logger.warning('Failed to process camera idle bounds', e, stackTrace);
    }
  }

  Future<void> _generateMapItems(
    List<GymModel> places,
    AppColors colors,
  ) async {
    final Set<Marker> newMarkers = {};
    final Set<Circle> newCircles = {};

    for (final place in places) {
      final baseColor = colors.markerGym;
      final BitmapDescriptor customIcon =
          await MapMarkerGenerator.createCustomMarker(
            markerColor: baseColor,
            logoUrl: place.branchLogo ?? '', // Using correct new field name
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

      // ARCHITECTURE FIX: Using withValues instead of deprecated withOpacity
      newCircles.add(
        Circle(
          circleId: CircleId('circle_outer_${place.id}'),
          center: place.location,
          radius: 80,
          fillColor: baseColor.withValues(alpha: 0.20),
          strokeWidth: 0,
        ),
      );

      newCircles.add(
        Circle(
          circleId: CircleId('circle_inner_${place.id}'),
          center: place.location,
          radius: 25,
          fillColor: baseColor.withValues(alpha: 0.85),
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
    } catch (e, stackTrace) {
      _logger.warning('Failed to focus on place marker', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final EdgeInsets safeArea = MediaQuery.of(context).padding;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AppColors colors = isDarkMode ? DarkColors() : LightColors();

    final asyncPlaces = ref.watch(nearbyPlacesProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);
    final locationState = ref.watch(userLocationProvider);

    // Initial map position
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

    // Handle Delayed GPS Auto Panning
    ref.listen<LocationState>(userLocationProvider, (previous, next) async {
      if (previous?.location == null && next.location != null) {
        try {
          final GoogleMapController controller =
              await _mapControllerCompleter.future;
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(next.location!, 14.5),
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to pan to delayed GPS location',
            e,
            stackTrace,
          );
        }
      }
    });

    // Handle Auto Panning on City Filter Change
    ref.listen<String?>(exploreFilterProvider.select((s) => s.cityId), (
      prev,
      currentCityId,
    ) async {
      if (currentCityId != null && currentCityId != prev) {
        final dbService = ref.read(databaseServiceProvider);
        final cities = await dbService.getCities();
        final selectedCity = cities.firstWhere(
          (c) => c['id'].toString() == currentCityId,
          orElse: () => <String, dynamic>{},
        );

        if (selectedCity.isNotEmpty &&
            selectedCity['lat'] != null &&
            selectedCity['lng'] != null) {
          final double lat = selectedCity['lat'] as double;
          final double lng = selectedCity['lng'] as double;
          try {
            final GoogleMapController controller =
                await _mapControllerCompleter.future;
            await controller.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(lat, lng), 12.0),
            );
          } catch (e, stackTrace) {
            _logger.warning('Failed to pan map to city', e, stackTrace);
          }
        }
      }
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
            // ARCHITECTURE FIX: Inject Map Style directly using the style property
            style: isDarkMode
                ? AppConstants.darkMapStyle
                : AppConstants.lightMapStyle,
            onMapCreated: _onMapCreated,
            onCameraIdle: _onCameraIdle,
            onTap: (_) =>
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

          Positioned(
            top: safeArea.top + Dimensions.spacingSmall,
            left: Dimensions.spacingMedium,
            right: Dimensions.spacingMedium,
            child: Column(
              children: [
                ExploreSearchBar(colors: colors),
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
                      // ARCHITECTURE FIX: Replace withOpacity with withValues
                      color: colors.surface.withValues(alpha: 0.95),
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
                              l10n.locationWarningText,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: Dimensions.fontBodySmall,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (!locationState.isServiceEnabled) {
                                ref
                                    .read(userLocationProvider.notifier)
                                    .openSettings();
                              } else if (!locationState.isPermissionGranted) {
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
                              l10n.enable,
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
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: child,
              ),
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
