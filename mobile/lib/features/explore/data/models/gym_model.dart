import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PlaceCategory { gym, restaurant, trainer, store }

enum CrowdLevel { low, medium, high }

class GymModel {
  final int id;
  final int providerId;
  final PlaceCategory category;
  final String name;
  final LatLng location;
  final String imageUrl;
  final bool isActive;
  final double rating;
  final bool isOpenNow;
  final CrowdLevel crowdLevel;

  const GymModel({
    required this.id,
    required this.providerId,
    required this.category,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.isActive,
    required this.rating,
    required this.isOpenNow,
    required this.crowdLevel,
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    PlaceCategory parsedCategory = PlaceCategory.gym;
    final String typeString = (json['type']?.toString() ?? 'gym').toLowerCase();
    if (typeString == 'restaurant') parsedCategory = PlaceCategory.restaurant;
    if (typeString == 'trainer') parsedCategory = PlaceCategory.trainer;
    if (typeString == 'store') parsedCategory = PlaceCategory.store;

    CrowdLevel parsedCrowd = CrowdLevel.low;
    final String crowdString = (json['crowd_level']?.toString() ?? 'low')
        .toLowerCase();
    if (crowdString == 'medium') parsedCrowd = CrowdLevel.medium;
    if (crowdString == 'high') parsedCrowd = CrowdLevel.high;

    String safeImageUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      return url.contains('localhost')
          ? url.replaceAll('localhost', '10.0.2.2')
          : url;
    }

    return GymModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      providerId: int.tryParse(json['provider_id']?.toString() ?? '0') ?? 0,
      category: parsedCategory,
      name: json['name']?.toString() ?? '',
      location: LatLng(
        double.tryParse(json['lat']?.toString() ?? '0.0') ?? 0.0,
        double.tryParse(json['lng']?.toString() ?? '0.0') ?? 0.0,
      ),
      imageUrl: safeImageUrl(json['image_url']?.toString()),
      isActive: json['is_active'] as bool? ?? true,
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      isOpenNow: json['is_open_now'] as bool? ?? false,
      crowdLevel: parsedCrowd,
    );
  }
}
