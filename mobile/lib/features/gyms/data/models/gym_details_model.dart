import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

enum PlaceCategory { gym, restaurant, trainer, store }

enum CrowdLevel { low, medium, high }

class GymAmenity {
  final int id;
  final String name;
  final String iconName;

  const GymAmenity({
    required this.id,
    required this.name,
    required this.iconName,
  });

  factory GymAmenity.fromJson(Map<String, dynamic> json) {
    return GymAmenity(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      iconName: json['icon_name']?.toString() ?? '',
    );
  }
}

class GymPlanFeature {
  final String name;

  const GymPlanFeature({required this.name});

  factory GymPlanFeature.fromJson(Map<String, dynamic> json) {
    return GymPlanFeature(name: json['name']?.toString() ?? '');
  }
}

class GymPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final int rewardPoints;
  final List<GymPlanFeature> features;

  const GymPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.rewardPoints,
    required this.features,
  });

  factory GymPlan.fromJson(Map<String, dynamic> json) {
    final double planPrice =
        double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0;
    final List<dynamic> featuresList = json['features'] as List? ?? [];

    return GymPlan(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: planPrice,
      durationDays: int.tryParse(json['duration_days']?.toString() ?? '0') ?? 0,
      rewardPoints: int.tryParse(json['reward_points']?.toString() ?? '0') ?? 0,
      features: featuresList
          .map((f) => GymPlanFeature.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GymReview {
  final int id;
  final String userName;
  final double rating;
  final String comment;
  final String date;

  const GymReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory GymReview.fromJson(Map<String, dynamic> json) {
    return GymReview(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? 'Unknown User',
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      comment: json['comment']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}

class GymDetailsModel {
  final int id;
  final String providerName;
  final String name;
  final String description;
  final String phoneNumber;
  final String openingTime;
  final String closingTime;
  final String city;
  final String address;
  final LatLng location;
  final String branchLogo;
  final List<String> images;
  final List<GymAmenity> amenities;
  final List<GymPlan> plans;
  final double rating;
  final int totalReviews;
  final bool isOpenNow;
  final CrowdLevel currentCrowdLevel;
  final Map<String, String> weeklyHours;
  final List<GymReview> reviews;

  static final Logger _logger = Logger('GymDetailsModel');

  const GymDetailsModel({
    required this.id,
    required this.providerName,
    required this.name,
    required this.description,
    required this.phoneNumber,
    required this.openingTime,
    required this.closingTime,
    required this.city,
    required this.address,
    required this.location,
    required this.branchLogo,
    required this.images,
    required this.amenities,
    required this.plans,
    required this.rating,
    required this.totalReviews,
    required this.isOpenNow,
    required this.currentCrowdLevel,
    required this.weeklyHours,
    required this.reviews,
  });

  factory GymDetailsModel.fromJson(Map<String, dynamic> json) {
    try {
      String safeImageUrl(String? url) {
        if (url == null || url.isEmpty) return '';
        // Automatically formats localhost URLs for Android Emulator
        return url.contains('localhost')
            ? url.replaceAll('localhost', '10.0.2.2')
            : url;
      }

      final List<dynamic> imagesList = json['images'] as List? ?? [];
      final List<dynamic> amenitiesList = json['amenities'] as List? ?? [];
      final List<dynamic> plansList = json['plans'] as List? ?? [];
      final List<dynamic> reviewsList = json['reviews'] as List? ?? [];

      CrowdLevel parsedCrowdLevel = CrowdLevel.low;
      final String crowdString = (json['crowd_level']?.toString() ?? 'low')
          .toLowerCase();
      if (crowdString == 'high') parsedCrowdLevel = CrowdLevel.high;
      if (crowdString == 'medium') parsedCrowdLevel = CrowdLevel.medium;

      return GymDetailsModel(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        providerName: json['provider_name']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        openingTime: json['opening_time']?.toString() ?? '',
        closingTime: json['closing_time']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        location: LatLng(
          double.tryParse(json['lat']?.toString() ?? '0.0') ?? 0.0,
          double.tryParse(json['lng']?.toString() ?? '0.0') ?? 0.0,
        ),
        branchLogo: safeImageUrl(json['branch_logo'] as String?),
        images: imagesList.map((img) => safeImageUrl(img as String?)).toList(),
        amenities: amenitiesList
            .map((a) => GymAmenity.fromJson(a as Map<String, dynamic>))
            .toList(),
        plans: plansList
            .map((p) => GymPlan.fromJson(p as Map<String, dynamic>))
            .toList(),
        rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
        totalReviews:
            int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
        isOpenNow: json['is_open_now'] as bool? ?? false,
        currentCrowdLevel: parsedCrowdLevel,
        weeklyHours: json['weekly_hours'] != null
            ? Map<String, String>.from(json['weekly_hours'])
            : {},
        reviews: reviewsList
            .map((r) => GymReview.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to parse GymDetailsModel from JSON',
        e,
        stackTrace,
      );
      throw Exception('Data format error');
    }
  }
}
