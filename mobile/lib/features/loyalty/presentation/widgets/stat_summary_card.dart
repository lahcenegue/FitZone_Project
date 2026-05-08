import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class StatSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AppColors colors;
  final double currentValue;
  final double totalValue;

  const StatSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.colors,
    required this.currentValue,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    // Prevent division by zero if the total is 0
    final double safeTotal = totalValue > 0 ? totalValue : 1.0;

    return Container(
      // ARCHITECTURE FIX: Defining a strict width prevents unbounded constraints
      // when the card is used inside horizontal scroll views like TransactionsHistoryScreen.
      width: Dimensions.screenWidth * 0.45,
      padding: EdgeInsets.all(Dimensions.spacingLarge),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusLarge * 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title Only (Clean & Minimal)
          Text(
            title,
            style: TextStyle(
              fontSize: Dimensions.fontBodyMedium,
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: Dimensions.spacingExtraLarge),

          // Bottom Row: Large Number + Radial Gauge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: Dimensions.fontHeading1 * 1.3,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              SizedBox(width: Dimensions.spacingSmall),

              // Elegant Radial Gauge acting as an Icon Container
              SizedBox(
                height: Dimensions.iconLarge * 2.4,
                width: Dimensions.iconLarge * 2.4,
                child: SfRadialGauge(
                  axes: <RadialAxis>[
                    RadialAxis(
                      minimum: 0,
                      maximum: safeTotal,
                      showLabels: false,
                      showTicks: false,
                      startAngle: 270,
                      endAngle: 270,
                      radiusFactor: 1.0,
                      axisLineStyle: AxisLineStyle(
                        thickness: 0.18,
                        thicknessUnit: GaugeSizeUnit.factor,
                        color: color.withValues(alpha: 0.15), // Track color
                      ),
                      pointers: <GaugePointer>[
                        RangePointer(
                          value: currentValue,
                          width: 0.18,
                          sizeUnit: GaugeSizeUnit.factor,
                          cornerStyle: CornerStyle.bothCurve,
                          color: color, // Progress color
                          enableAnimation: true,
                          animationDuration: 1500,
                          animationType: AnimationType.easeOutBack,
                        ),
                      ],
                      annotations: <GaugeAnnotation>[
                        GaugeAnnotation(
                          positionFactor: 0.0,
                          widget: Icon(
                            icon,
                            color: color,
                            size: Dimensions.iconLarge * 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
