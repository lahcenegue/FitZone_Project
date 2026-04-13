import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // <-- IMPORT ADDED

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/subscription_model.dart';

class SubscriptionDetailsScreen extends ConsumerWidget {
  final SubscriptionModel subscription;
  static final Logger _logger = Logger('SubscriptionDetailsScreen');

  const SubscriptionDetailsScreen({super.key, required this.subscription});

  Future<void> _openMap(
    double? lat,
    double? lng,
    BuildContext context,
    AppColors colors,
  ) async {
    if (lat == null || lng == null) return;
    final Uri url = Uri.parse('http://maps.google.com/maps?q=loc:$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      _logger.warning('Could not launch map URL', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open maps'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  void _showFullScreenQr(
    BuildContext context,
    String qrData,
    AppColors colors,
    AppLocalizations l10n,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.all(Dimensions.spacingExtraLarge),
              padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
              decoration: BoxDecoration(
                color: Colors.white, // MUST be white for reliable scanning
                borderRadius: BorderRadius.circular(
                  Dimensions.borderRadiusLarge * 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: PrettyQrView.data(
                      data: qrData,
                      decoration: const PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingExtraLarge),
                  SizedBox(
                    width: double.infinity,
                    height: Dimensions.buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.borderRadiusLarge,
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Dimensions.fontTitleMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppColors colors = ref.watch(appThemeProvider);
    final bool isActive = subscription.status == 'active';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.subscriptionDetails,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: Dimensions.fontTitleLarge,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(Dimensions.spacingLarge),
          child: Column(
            children: [
              // --- 1. The Digital Ticket ---
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(
                    Dimensions.borderRadiusLarge * 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top Section (Logo & Info)
                    Padding(
                      padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
                      child: Column(
                        children: [
                          if (subscription.branchLogo != null &&
                              subscription.branchLogo!.isNotEmpty)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.background,
                                border: Border.all(
                                  color: colors.iconGrey.withOpacity(0.1),
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(subscription.branchLogo!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: colors.primary,
                                size: 40,
                              ),
                            ),
                          SizedBox(height: Dimensions.spacingMedium),
                          Text(
                            subscription.providerName,
                            style: TextStyle(
                              fontSize: Dimensions.fontBodyLarge,
                              fontWeight: FontWeight.bold,
                              color: colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: Dimensions.spacingTiny),
                          Text(
                            subscription.planName,
                            style: TextStyle(
                              fontSize: Dimensions.fontHeading1 * 1.1,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: Dimensions.spacingMedium),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimensions.spacingLarge,
                              vertical: Dimensions.spacingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : colors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusPill,
                              ),
                            ),
                            child: Text(
                              isActive
                                  ? l10n.activeSubscription
                                  : l10n.expiredSubscription,
                              style: TextStyle(
                                color: isActive ? Colors.green : colors.error,
                                fontWeight: FontWeight.w800,
                                fontSize: Dimensions.fontBodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dashed Divider (Ticket Effect)
                    Row(
                      children: [
                        SizedBox(
                          height: 20,
                          width: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Flex(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                direction: Axis.horizontal,
                                children: List.generate(
                                  (constraints.constrainWidth() / 15).floor(),
                                  (_) => SizedBox(
                                    width: 8,
                                    height: 2,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: colors.iconGrey.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          width: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Progress Section
                    Padding(
                      padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
                      child: _buildProgressSection(colors, l10n),
                    ),

                    // QR Code Section
                    if (isActive && subscription.qrCodeSignature.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showFullScreenQr(
                          context,
                          subscription.qrCodeSignature,
                          colors,
                          l10n,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(Dimensions.spacingExtraLarge),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.02),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(
                                Dimensions.borderRadiusLarge * 1.5,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                  Dimensions.spacingMedium,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.borderRadiusLarge,
                                  ),
                                ),
                                child: SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: PrettyQrView.data(
                                    data: subscription.qrCodeSignature,
                                    decoration: const PrettyQrDecoration(
                                      shape: PrettyQrSmoothSymbol(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: Dimensions.spacingMedium),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.zoom_out_map_rounded,
                                    color: colors.primary,
                                    size: Dimensions.iconSmall,
                                  ),
                                  SizedBox(width: Dimensions.spacingSmall),
                                  Text(
                                    l10n.tapToExpandQr,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: Dimensions.fontBodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: Dimensions.spacingExtraLarge),

              // --- 2. Embedded Location Section ---
              if (subscription.address != null &&
                  subscription.address!.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(Dimensions.spacingLarge),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(
                      Dimensions.borderRadiusLarge,
                    ),
                    border: Border.all(color: colors.iconGrey.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gymLocation,
                        style: TextStyle(
                          fontSize: Dimensions.fontTitleMedium,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: Dimensions.spacingMedium),

                      // Embedded Google Map
                      if (subscription.lat != null &&
                          subscription.lng != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimensions.borderRadius,
                          ),
                          child: SizedBox(
                            height: 180, // Premium fixed height
                            width: double.infinity,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  subscription.lat!,
                                  subscription.lng!,
                                ),
                                zoom: 15.0,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId(
                                    'gym_branch_location',
                                  ),
                                  position: LatLng(
                                    subscription.lat!,
                                    subscription.lng!,
                                  ),
                                ),
                              },
                              // Disable gestures so it doesn't interfere with page scrolling
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              mapToolbarEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingMedium),
                      ],

                      // Address Text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: colors.primary,
                            size: Dimensions.iconMedium,
                          ),
                          SizedBox(width: Dimensions.spacingMedium),
                          Expanded(
                            child: Text(
                              subscription.address!,
                              style: TextStyle(
                                fontSize: Dimensions.fontBodyMedium,
                                color: colors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Open in Maps Button
                      if (subscription.lat != null &&
                          subscription.lng != null) ...[
                        SizedBox(height: Dimensions.spacingLarge),
                        SizedBox(
                          width: double.infinity,
                          height: Dimensions.buttonHeight,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.primary,
                              side: BorderSide(
                                color: colors.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.borderRadius,
                                ),
                              ),
                            ),
                            onPressed: () => _openMap(
                              subscription.lat,
                              subscription.lng,
                              context,
                              colors,
                            ),
                            icon: Icon(
                              Icons.map_rounded,
                              size: Dimensions.iconMedium,
                            ),
                            label: Text(
                              l10n.openInMaps,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Dimensions.fontBodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(AppColors colors, AppLocalizations l10n) {
    try {
      final DateTime start = DateTime.parse(subscription.startDate);
      final DateTime end = DateTime.parse(subscription.endDate);
      final DateTime now = DateTime.now();

      final int totalDays = end.difference(start).inDays;
      final int passedDays = now.difference(start).inDays;
      final int remainingDays = end.difference(now).inDays;

      double progress = totalDays > 0 ? passedDays / totalDays : 0.0;
      progress = progress.clamp(0.0, 1.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.subscriptionProgress,
                style: TextStyle(
                  fontSize: Dimensions.fontBodyMedium,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                ),
              ),
              if (remainingDays > 0)
                Text(
                  '$remainingDays ${l10n.daysRemaining}',
                  style: TextStyle(
                    fontSize: Dimensions.fontBodyMedium,
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
            ],
          ),
          SizedBox(height: Dimensions.spacingMedium),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutQuart,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: colors.iconGrey.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              );
            },
          ),
          SizedBox(height: Dimensions.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subscription.startDate,
                style: TextStyle(
                  fontSize: Dimensions.fontBodySmall,
                  fontWeight: FontWeight.bold,
                  color: colors.iconGrey,
                ),
              ),
              Text(
                subscription.endDate,
                style: TextStyle(
                  fontSize: Dimensions.fontBodySmall,
                  fontWeight: FontWeight.bold,
                  color: colors.iconGrey,
                ),
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
