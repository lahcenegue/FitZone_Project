import 'dart:ui';
import 'dart:math';

/// Core responsive dimensions for the FitZone application.
class Dimensions {
  Dimensions._();

  static late double screenWidth;
  static late double screenHeight;
  static late double _scaleFactor;

  static const double _referenceWidth = 390.0;
  static const double _maxScaleFactor = 1.25;

  static void init(FlutterView view) {
    final Size physicalSize = view.physicalSize;
    final double devicePixelRatio = view.devicePixelRatio;

    screenWidth = physicalSize.width / devicePixelRatio;
    screenHeight = physicalSize.height / devicePixelRatio;

    double rawScale = screenWidth / _referenceWidth;
    _scaleFactor = min(max(1.0, rawScale), _maxScaleFactor);
  }

  static double _scale(double value) => value * _scaleFactor;

  // Typography
  static double get fontHeading1 => _scale(26.0);
  static double get fontHeading2 => _scale(20.0);
  static double get fontHeading3 => _scale(16.0);
  static double get fontBodyLarge => _scale(14.0);
  static double get fontBodyMedium => _scale(12.0);
  static double get fontBodySmall => _scale(10.0);
  static double get fontButton => _scale(16.0);

  // Icon Sizes
  static double get iconSmall => _scale(16.0);
  static double get iconMedium => _scale(22.0);
  static double get iconLarge => _scale(28.0);

  // Spacing
  static double get spacingTiny => _scale(4.0);
  static double get spacingSmall => _scale(8.0);
  static double get spacingMedium => _scale(16.0);
  static double get spacingLarge => _scale(24.0);
  static double get spacingExtraLarge => _scale(32.0);

  // Structural Elements
  static double get borderRadius => _scale(16.0);
  static double get radiusPill => _scale(50.0); // For the target UI search bar
  static double get buttonHeight => _scale(48.0);
  static double get searchBarHeight => _scale(56.0);
  static double get fabSize => _scale(56.0);

  static const double cardMaxWidth = 500.0;
  static const double maxContentWidth = 800.0;

  // Map Specific Dimensions
  static double get mapFabBottomOffset => _scale(110.0);
  static double get zoomControlsBottomOffset => _scale(190.0);
  static double get searchBarTopOffset => _scale(16.0);

  // Custom Premium Button Dimensions
  static double get customButtonSize => _scale(48.0);
  static double get dividerHeight => _scale(1.0);
  static double get dividerWidth => _scale(32.0);
  static double get shadowBlurRadius => _scale(24.0);
  static double get shadowSpreadRadius => _scale(2.0);
  static double get shadowOffsetY => _scale(8.0);

  // Typography Extensions
  static double get fontTitleMedium => _scale(18.0);
  static double get fontTitleLarge =>
      _scale(22.0); // ADDED: Required for PersonalInfoScreen

  // Structural Elements
  static double get borderRadiusLarge => _scale(24.0);

  static double widthPercent(double percent, {double? max}) {
    double calculatedWidth = screenWidth * (percent / 100);
    if (max != null && calculatedWidth > max) return max;
    return calculatedWidth;
  }

  static double heightPercent(double percent) {
    return screenHeight * (percent / 100);
  }
}
