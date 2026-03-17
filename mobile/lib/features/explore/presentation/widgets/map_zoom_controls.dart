import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/dimensions.dart';

class MapZoomControls extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapZoomControls({
    super.key,
    required this.colors,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimensions.borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: Dimensions.shadowBlurRadius,
            spreadRadius: Dimensions.shadowSpreadRadius,
            offset: Offset(0, Dimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.add,
            color: colors.textPrimary,
            onTap: onZoomIn,
            isTop: true,
          ),
          Container(
            height: Dimensions.dividerHeight,
            width: Dimensions.dividerWidth,
            color: colors.background,
          ),
          _ZoomButton(
            icon: Icons.remove,
            color: colors.textPrimary,
            onTap: onZoomOut,
            isBottom: true,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isTop;
  final bool isBottom;

  const _ZoomButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isTop = false,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isTop ? Radius.circular(Dimensions.borderRadius) : Radius.zero,
          bottom: isBottom
              ? Radius.circular(Dimensions.borderRadius)
              : Radius.zero,
        ),
        onTap: onTap,
        child: SizedBox(
          width: Dimensions.customButtonSize,
          height: Dimensions.customButtonSize,
          child: Center(
            child: Icon(icon, color: color, size: Dimensions.iconMedium),
          ),
        ),
      ),
    );
  }
}
