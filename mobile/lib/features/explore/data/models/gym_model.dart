import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

enum PlaceCategory { gym, restaurant, trainer, store }

enum CrowdLevel { low, medium, high }

class GymModel {
  final int id;
  final int providerId;
  final String providerName;
  final PlaceCategory category;
  final String name;
  final String city;
  final String address;
  final String gender;
  final LatLng location;
  final String? branchLogo;
  final bool isActive;
  final bool isTemporarilyClosed;
  final double rating;
  final bool isOpenNow;
  final CrowdLevel crowdLevel;

  final double? distanceKm;
  final double? minPrice;

  final List<String> sports;
  final List<String> amenities;

  static final Logger _logger = Logger('GymModel');

  const GymModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.category,
    required this.name,
    required this.city,
    required this.address,
    required this.gender,
    required this.location,
    this.branchLogo,
    required this.isActive,
    required this.isTemporarilyClosed,
    required this.rating,
    required this.isOpenNow,
    required this.crowdLevel,
    this.distanceKm,
    this.minPrice,
    required this.sports,
    required this.amenities,
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    try {
      PlaceCategory parsedCategory = PlaceCategory.gym;
      final String typeString = (json['type']?.toString() ?? 'gym')
          .toLowerCase();
      if (typeString == 'restaurant') parsedCategory = PlaceCategory.restaurant;
      if (typeString == 'trainer') parsedCategory = PlaceCategory.trainer;
      if (typeString == 'store') parsedCategory = PlaceCategory.store;

      CrowdLevel parsedCrowd = CrowdLevel.low;
      final String crowdString = (json['crowd_level']?.toString() ?? 'low')
          .toLowerCase();
      if (crowdString == 'medium') parsedCrowd = CrowdLevel.medium;
      if (crowdString == 'high') parsedCrowd = CrowdLevel.high;

      final List<dynamic> sportsList = json['sports'] as List? ?? [];
      final List<dynamic> amenitiesList = json['amenities'] as List? ?? [];

      // ARCHITECTURE FIX: Strict Parsing. Drop the model if coordinates are missing.
      if (json['lat'] == null || json['lng'] == null) {
        throw const FormatException('Missing required coordinates (lat/lng)');
      }

      final double lat = double.parse(json['lat'].toString());
      final double lng = double.parse(json['lng'].toString());

      return GymModel(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        providerId: int.tryParse(json['provider_id']?.toString() ?? '0') ?? 0,
        providerName: json['provider_name']?.toString() ?? '',
        category: parsedCategory,
        name: json['name']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        gender: json['gender']?.toString() ?? 'mixed',
        location: LatLng(lat, lng), // Safe and Mandatory
        branchLogo: json['branch_logo']?.toString(),
        isActive: json['is_active'] as bool? ?? true,
        isTemporarilyClosed: json['is_temporarily_closed'] as bool? ?? false,
        rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
        isOpenNow: json['is_open_now'] as bool? ?? false,
        crowdLevel: parsedCrowd,
        distanceKm: json['distance_km'] != null
            ? double.tryParse(json['distance_km'].toString())
            : null,
        minPrice: json['min_price'] != null
            ? double.tryParse(json['min_price'].toString())
            : null,
        sports: sportsList.map((e) => e.toString()).toList(),
        amenities: amenitiesList.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      _logger.warning(
        'Skipping corrupted GymModel for ID: ${json["id"]} - Reason: $e',
      );
      rethrow; // Rethrowing allows the service to filter it out smoothly
    }
  }
}
