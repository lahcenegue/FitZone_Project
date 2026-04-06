import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppConstants {
  AppConstants._();

  static const String googleMapsApiKey =
      'AIzaSyABzM7d31JhW_SlgxSTrRlJWoa81MpHaaY';

  static const LatLng defaultMapCenter = LatLng(24.7136, 46.6753);
  static const double defaultMapZoom = 14.0;
  static const double maxMapZoom = 18.0;
  static const double minMapZoom = 3.0;
  static const double zoomStep = 1.0;

  static const String lightMapStyle = '''[
    {"featureType": "all","elementType": "geometry","stylers": [{"color": "#dce9f1"}]},
    {"featureType": "all","elementType": "labels.text.fill","stylers": [{"color": "#616161"}]},
    {"featureType": "all","elementType": "labels.text.stroke","stylers": [{"color": "#f5f5f5"}]},
    {"featureType": "all","elementType": "labels.icon","stylers": [{"visibility": "off"}]},
    {"featureType": "road","elementType": "geometry","stylers": [{"color": "#ffffff"}]},
    {"featureType": "road.arterial","elementType": "labels.text.fill","stylers": [{"color": "#757575"}]},
    {"featureType": "road.highway","elementType": "geometry","stylers": [{"color": "#ffffff"}]},
    {"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#616161"}]},
    {"featureType": "road.local","elementType": "labels.text.fill","stylers": [{"color": "#9e9e9e"}]},
    {"featureType": "water","elementType": "geometry","stylers": [{"color": "#c8d7e6"}]},
    {"featureType": "poi","elementType": "geometry","stylers": [{"color": "#dce9f1"}]}
  ]''';

  static const String darkMapStyle = '''[
    {"elementType": "geometry","stylers": [{"color": "#1e293b"}]},
    {"elementType": "labels.text.fill","stylers": [{"color": "#94a3b8"}]},
    {"elementType": "labels.text.stroke","stylers": [{"color": "#0f172a"}]},
    {"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#cbd5e1"}]},
    {"featureType": "poi","stylers": [{"visibility": "off"}]},
    {"featureType": "road","elementType": "geometry","stylers": [{"color": "#334155"}]},
    {"featureType": "road","elementType": "geometry.stroke","stylers": [{"color": "#1e293b"}]},
    {"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#94a3b8"}]},
    {"featureType": "road.highway","elementType": "geometry","stylers": [{"color": "#475569"}]},
    {"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1e293b"}]},
    {"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f8fafc"}]},
    {"featureType": "transit","stylers": [{"visibility": "off"}]},
    {"featureType": "water","elementType": "geometry","stylers": [{"color": "#0f172a"}]},
    {"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#3b82f6"}]}
  ]''';

  static const double maxdistamceKm = 200;
}
