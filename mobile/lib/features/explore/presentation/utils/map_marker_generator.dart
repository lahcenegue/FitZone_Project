import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

/// Utility class to generate a premium, seamlessly curved map pin (Teardrop shape)
/// containing a white separator ring and a circular avatar.
class MapMarkerGenerator {
  MapMarkerGenerator._();

  static final Logger _logger = Logger('MapMarkerGenerator');

  // ---------------------------------------------------------------------------
  // Canvas Dimensions & Coordinates
  // ---------------------------------------------------------------------------
  static const double _canvasWidth = 200.0;
  static const double _canvasHeight = 260.0;

  static const double _cx = _canvasWidth / 2;
  static const double _cy = 100.0; // Center of the upper circle area

  static const double _pinRadius = 76.0; // The main colored background radius
  static const double _tipY = 230.0; // The exact bottom point of the pin

  static const double _whiteRingWidth = 8.0;
  static const double _imageRadius = 60.0; // Avatar radius

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Generates the perfectly smooth teardrop pin marker.
  static Future<BitmapDescriptor> createCustomMarker({
    required Color markerColor,
    required String logoUrl,
  }) async {
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // 1. Build the mathematically smooth Teardrop path
      final Path pinPath = _buildSmoothTeardropPath();

      // 2. Draw the drop shadow for the entire pin to make it float
      _drawPinShadow(canvas, pinPath);

      // 3. Fill the teardrop shape with the category color
      _drawPinBase(canvas, pinPath, markerColor);

      // 4. Draw the inner white ring for high contrast
      _drawWhiteInnerRing(canvas);

      // 5. Draw the network image (avatar) flawlessly clipped
      await _drawAvatarImage(canvas, logoUrl);

      // 6. Render the canvas to a Bitmap
      return await _convertToDescriptor(recorder);
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to generate premium custom marker.',
        e,
        stackTrace,
      );
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  // ---------------------------------------------------------------------------
  // Drawing Steps
  // ---------------------------------------------------------------------------

  /// Constructs a mathematically perfect teardrop using exact Bezier control points.
  static Path _buildSmoothTeardropPath() {
    final Path path = Path();

    // Start at the bottom sharp tip
    path.moveTo(_cx, _tipY);

    // Curve smoothly up to the left side of the circle
    path.quadraticBezierTo(
      _cx - (_pinRadius * 0.8),
      _tipY - (_pinRadius * 0.85), // Control point pushing left
      _cx - (_pinRadius * 0.96),
      _cy + (_pinRadius * 0.25), // Anchor point on the circle
    );

    // Arc perfectly over the top to the right side
    path.arcToPoint(
      Offset(_cx + (_pinRadius * 0.96), _cy + (_pinRadius * 0.25)),
      radius: const Radius.circular(_pinRadius),
      largeArc: true,
      clockwise: true,
    );

    // Curve smoothly back down to the bottom tip
    path.quadraticBezierTo(
      _cx + (_pinRadius * 0.8),
      _tipY - (_pinRadius * 0.85), // Control point pushing right
      _cx,
      _tipY, // Back to the tip
    );

    path.close();
    return path;
  }

  /// Draws a soft, realistic shadow under the pin shape.
  static void _drawPinShadow(Canvas canvas, Path pinPath) {
    final Paint pinShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    // Shift shadow slightly down (Y) and right (X)
    canvas.drawPath(pinPath.shift(const Offset(4.0, 10.0)), pinShadowPaint);
  }

  /// Fills the entire teardrop shape with the solid primary color.
  static void _drawPinBase(Canvas canvas, Path pinPath, Color markerColor) {
    final Paint pinPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(pinPath, pinPaint);
  }

  /// Draws the precise white separator circle.
  static void _drawWhiteInnerRing(Canvas canvas) {
    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // The radius is the image radius + the white ring thickness
    canvas.drawCircle(
      const Offset(_cx, _cy),
      _imageRadius + _whiteRingWidth,
      whitePaint,
    );
  }

  /// Fetches, clips, and draws the avatar image into the center.
  static Future<void> _drawAvatarImage(Canvas canvas, String logoUrl) async {
    final Rect imageRect = Rect.fromCircle(
      center: const Offset(_cx, _cy),
      radius: _imageRadius,
    );

    // Fallback background color if image is empty or transparent
    final Paint bgPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawCircle(const Offset(_cx, _cy), _imageRadius, bgPaint);

    if (logoUrl.isEmpty) return;

    try {
      final ui.Image image = await _loadNetworkImage(logoUrl);

      final Path clipPath = Path()..addOval(imageRect);
      canvas.save();
      canvas.clipPath(clipPath);

      paintImage(
        canvas: canvas,
        rect: imageRect,
        image: image,
        fit: BoxFit.cover,
      );

      canvas.restore();
    } catch (e) {
      _logger.warning('Avatar image failed to load: $logoUrl');
    }
  }

  // ---------------------------------------------------------------------------
  // Conversion & Network Utils
  // ---------------------------------------------------------------------------

  static Future<BitmapDescriptor> _convertToDescriptor(
    ui.PictureRecorder recorder,
  ) async {
    final ui.Image finalImage = await recorder.endRecording().toImage(
      _canvasWidth.toInt(),
      _canvasHeight.toInt(),
    );

    final ByteData? byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  static Future<ui.Image> _loadNetworkImage(String url) async {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = NetworkImage(
      url,
    ).resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool syncCall) {
        if (!completer.isCompleted) {
          completer.complete(info.image);
          stream.removeListener(listener);
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
          stream.removeListener(listener);
        }
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
}
