import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../l10n/app_localizations.dart';

import '../providers/map_picker_provider.dart';
import 'package:fitzone/features/explore/presentation/widgets/map_location_button.dart';

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(mapPickerControllerProvider.notifier).searchPlaces(query);
    });
  }

  Future<void> _moveCamera(LatLng target) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: AppConstants.maxMapZoom - 2.0),
      ),
    );
  }

  Future<void> _handleLocationTap() async {
    await ref.read(userLocationProvider.notifier).fetchLocation();
    final locationState = ref.read(userLocationProvider);
    if (locationState.location != null) {
      final target = LatLng(
        locationState.location!.latitude,
        locationState.location!.longitude,
      );
      await _moveCamera(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final mapState = ref.watch(mapPickerControllerProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: mapState.currentCenter,
              zoom: AppConstants.defaultMapZoom,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            style: isDarkMode
                ? AppConstants.darkMapStyle
                : AppConstants.lightMapStyle,
            onMapCreated: (controller) => _mapController.complete(controller),
            onCameraMove: (position) {
              ref
                  .read(mapPickerControllerProvider.notifier)
                  .onCameraMove(position);
            },
            onCameraIdle: () {
              ref.read(mapPickerControllerProvider.notifier).onCameraIdle();
            },
          ),

          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: Dimensions.customButtonSize),
              child: Icon(
                Icons.location_on_rounded,
                size: Dimensions.customButtonSize,
                color: colors.primary,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.spacingLarge),
              child: Column(
                children: [
                  _buildSearchBar(colors, l10n, mapState),
                  if (mapState.searchResults.isNotEmpty)
                    _buildAutocompleteList(colors, mapState),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: Dimensions.heightPercent(32.0).clamp(260.0, 300.0),
            right: Dimensions.spacingMedium,
            child: MapLocationButton(
              colors: colors,
              onLocationTap: _handleLocationTap,
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildLocationSummaryCard(colors, l10n, mapState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    AppColors colors,
    AppLocalizations l10n,
    MapPickerState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius,
            offset: Offset(0, Dimensions.shadowOffsetY),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchLocationHint,
          hintStyle: TextStyle(color: colors.iconGrey),
          prefixIcon: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary,
              size: Dimensions.iconSmall,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          suffixIcon: state.isSearching
              ? Padding(
                  padding: EdgeInsets.all(Dimensions.spacingMedium),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              : _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.iconGrey),
                  onPressed: () {
                    _searchController.clear();
                    ref
                        .read(mapPickerControllerProvider.notifier)
                        .clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: Dimensions.spacingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteList(AppColors colors, MapPickerState state) {
    return Container(
      margin: EdgeInsets.only(top: Dimensions.spacingSmall),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius,
          ),
        ],
      ),
      constraints: BoxConstraints(maxHeight: Dimensions.heightPercent(30.0)),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: state.searchResults.length,
        separatorBuilder: (_, __) => Divider(
          height: Dimensions.dividerHeight,
          color: colors.iconGrey.withOpacity(0.2),
        ),
        itemBuilder: (context, index) {
          final result = state.searchResults[index];
          final mainText = result['structured_formatting']?['main_text'] ?? '';
          final secondaryText =
              result['structured_formatting']?['secondary_text'] ?? '';

          return ListTile(
            leading: Icon(
              Icons.location_on_outlined,
              color: colors.iconGrey,
              size: Dimensions.iconMedium,
            ),
            title: Text(
              mainText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontSize: Dimensions.fontBodyLarge,
              ),
            ),
            subtitle: Text(
              secondaryText,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: Dimensions.fontBodySmall,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () async {
              FocusScope.of(context).unfocus();
              final target = await ref
                  .read(mapPickerControllerProvider.notifier)
                  .getPlaceDetailsAndMove(result['place_id']);
              if (target != null) _moveCamera(target);
            },
          );
        },
      ),
    );
  }

  Widget _buildLocationSummaryCard(
    AppColors colors,
    AppLocalizations l10n,
    MapPickerState state,
  ) {
    return Container(
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.borderRadiusLarge * 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius * 2,
            offset: Offset(0, -Dimensions.shadowOffsetY),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.confirmLocation,
              style: TextStyle(
                fontSize: Dimensions.fontBodyMedium,
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: Dimensions.spacingSmall),
            Row(
              children: [
                Icon(
                  Icons.map_rounded,
                  color: colors.primary,
                  size: Dimensions.iconMedium,
                ),
                SizedBox(width: Dimensions.spacingMedium),
                Expanded(
                  child: state.isFetchingAddress
                      ? LinearProgressIndicator(
                          backgroundColor: colors.primary.withOpacity(0.1),
                          color: colors.primary,
                        )
                      : Text(
                          state.currentAddress,
                          style: TextStyle(
                            fontSize: Dimensions.fontTitleMedium,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
            SizedBox(height: Dimensions.spacingExtraLarge),
            SizedBox(
              width: double.infinity,
              height: Dimensions.buttonHeight * 1.2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusLarge,
                    ),
                  ),
                  elevation: 0,
                ),
                onPressed:
                    (state.isFetchingAddress || state.currentAddress.isEmpty)
                    ? null
                    : () {
                        Navigator.pop(context, {
                          'address': state.currentAddress,
                          'lat': state.currentCenter.latitude,
                          'lng': state.currentCenter.longitude,
                        });
                      },
                child: Text(
                  l10n.useThisAddress,
                  style: TextStyle(
                    fontSize: Dimensions.fontTitleMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
