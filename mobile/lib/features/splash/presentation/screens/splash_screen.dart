import 'dart:async';
import 'package:fitzone/core/location/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/init/app_init_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<ServiceStatus>? _locationSubscription;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _setupAutoRetryListeners();
  }

  void _triggerSafeRetry(bool isOfflineError) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final startupState = ref.read(appStartupProvider);

      if (startupState.hasError) {
        final error = startupState.error;
        if ((isOfflineError && error is OfflineException) ||
            (!isOfflineError && error is LocationDisabledException)) {
          ref.invalidate(appStartupProvider);
        }
      }
    });
  }

  void _setupAutoRetryListeners() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        _triggerSafeRetry(true);
      }
    });

    _locationSubscription = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) {
      if (status == ServiceStatus.enabled) {
        _triggerSafeRetry(false);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _locationSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleNavigation(
    StartupStatus status,
    AppLocalizations l10n,
    AppColors colors,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      if (status == StartupStatus.locationTimeout) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.locationTimeoutMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: colors.warning,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(Dimensions.spacingMedium),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.borderRadius),
            ),
          ),
        );
      }
      context.go(RoutePaths.explore);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = ref.watch(appThemeProvider);
    final startupState = ref.watch(appStartupProvider);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      body: startupState.when(
        data: (status) {
          _handleNavigation(status, l10n, colors);
          return _buildLoadingUI(colors);
        },
        error: (error, stackTrace) {
          if (error is OfflineException) {
            return _buildErrorUI(
              colors: colors,
              icon: Icons.wifi_off_rounded,
              title: l10n.noInternetTitle,
              message: l10n.noInternetMessage,
              buttonText: l10n.retryButton,
              onPressed: () => ref.invalidate(appStartupProvider),
            );
          } else if (error is LocationDisabledException) {
            return _buildErrorUI(
              colors: colors,
              icon: Icons.location_off_rounded,
              title: l10n.locationRequiredTitle,
              message: l10n.locationRequiredMessage,
              buttonText: l10n.enableLocationButton,
              onPressed: () async {
                await ref
                    .read(userLocationProvider.notifier)
                    .promptEnableLocation();

                final bool isEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (isEnabled) {
                  ref.invalidate(appStartupProvider);
                }
              },
            );
          }

          _handleNavigation(StartupStatus.success, l10n, colors);
          return _buildLoadingUI(colors);
        },
        loading: () => _buildLoadingUI(colors),
      ),
    );
  }

  Widget _buildLoadingUI(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: Dimensions.iconLarge * 3,
            color: colors.primary,
          ),
          SizedBox(height: Dimensions.spacingExtraLarge),
          CircularProgressIndicator(color: colors.primary),
        ],
      ),
    );
  }

  Widget _buildErrorUI({
    required AppColors colors,
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Dimensions.spacingLarge),
              decoration: BoxDecoration(
                color: colors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: Dimensions.iconLarge * 2.5,
                color: colors.error,
              ),
            ),
            SizedBox(height: Dimensions.spacingLarge),
            Text(
              title,
              style: TextStyle(
                fontSize: Dimensions.fontHeading2,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Dimensions.spacingSmall),
            Text(
              message,
              style: TextStyle(
                fontSize: Dimensions.fontBodyLarge,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Dimensions.spacingExtraLarge),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.surface,
                minimumSize: Size(double.infinity, Dimensions.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Dimensions.borderRadiusLarge,
                  ),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: Dimensions.fontTitleMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
