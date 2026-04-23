import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

enum PlaceCategory { gym, restaurant, trainer, store }

enum CrowdLevel { low, medium, high }

class GymAmenity {
  final int id;
  final String name;
  final String? iconImage;

  const GymAmenity({required this.id, required this.name, this.iconImage});

  factory GymAmenity.fromJson(Map<String, dynamic> json) {
    return GymAmenity(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      iconImage: json['icon_image']?.toString(),
    );
  }
}

class GymSport {
  final int id;
  final String name;
  final String? imageUrl;

  const GymSport({required this.id, required this.name, this.imageUrl});

  factory GymSport.fromJson(Map<String, dynamic> json) {
    return GymSport(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: json['image']?.toString(),
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
  final String city;
  final String address;
  final String gender;
  final LatLng? location;
  final String? branchLogo;
  final List<String> images;
  final List<GymAmenity> amenities;
  final List<GymSport> sports;
  final List<GymPlan> plans;
  final double rating;
  final int totalReviews;
  final bool isOpenNow;
  final bool isTemporarilyClosed;
  final CrowdLevel currentCrowdLevel;
  final Map<String, Map<String, String>> weeklyHours;
  final List<GymReview> reviews;

  static final Logger _logger = Logger('GymDetailsModel');

  const GymDetailsModel({
    required this.id,
    required this.providerName,
    required this.name,
    required this.description,
    required this.phoneNumber,
    required this.city,
    required this.address,
    required this.gender,
    this.location,
    this.branchLogo,
    required this.images,
    required this.amenities,
    required this.sports,
    required this.plans,
    required this.rating,
    required this.totalReviews,
    required this.isOpenNow,
    required this.isTemporarilyClosed,
    required this.currentCrowdLevel,
    required this.weeklyHours,
    required this.reviews,
  });

  factory GymDetailsModel.fromJson(Map<String, dynamic> json) {
    try {
      final List<dynamic> imagesList = json['images'] as List? ?? [];
      final List<dynamic> amenitiesList = json['amenities'] as List? ?? [];
      final List<dynamic> sportsList = json['sports'] as List? ?? [];
      final List<dynamic> plansList = json['plans'] as List? ?? [];
      final List<dynamic> reviewsList = json['reviews'] as List? ?? [];

      CrowdLevel parsedCrowdLevel = CrowdLevel.low;
      final String crowdString = (json['crowd_level']?.toString() ?? 'low')
          .toLowerCase();
      if (crowdString == 'high') parsedCrowdLevel = CrowdLevel.high;
      if (crowdString == 'medium') parsedCrowdLevel = CrowdLevel.medium;

      LatLng? parsedLocation;
      if (json['lat'] != null && json['lng'] != null) {
        final double lat = double.tryParse(json['lat'].toString()) ?? 0.0;
        final double lng = double.tryParse(json['lng'].toString()) ?? 0.0;
        parsedLocation = LatLng(lat, lng);
      }

      Map<String, Map<String, String>> parsedWeeklyHours = {};
      if (json['weekly_hours'] is Map) {
        final Map<String, dynamic> hoursMap =
            json['weekly_hours'] as Map<String, dynamic>;
        hoursMap.forEach((key, value) {
          if (value is Map) {
            parsedWeeklyHours[key] = Map<String, String>.from(value);
          }
        });
      }

      return GymDetailsModel(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        providerName: json['provider_name']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        gender: json['gender']?.toString() ?? 'mixed',
        location: parsedLocation,
        branchLogo: json['branch_logo']?.toString(),
        images: imagesList.map((img) => img.toString()).toList(),
        amenities: amenitiesList
            .map((a) => GymAmenity.fromJson(a as Map<String, dynamic>))
            .toList(),
        sports: sportsList
            .map((s) => GymSport.fromJson(s as Map<String, dynamic>))
            .toList(),
        plans: plansList
            .map((p) => GymPlan.fromJson(p as Map<String, dynamic>))
            .toList(),
        rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
        totalReviews:
            int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
        isOpenNow: json['is_open_now'] as bool? ?? false,
        isTemporarilyClosed: json['is_temporarily_closed'] as bool? ?? false,
        currentCrowdLevel: parsedCrowdLevel,
        weeklyHours: parsedWeeklyHours,
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
