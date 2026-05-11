import 'package:logging/logging.dart';

class ResaleSeller {
  final String name;
  final String? avatar;

  const ResaleSeller({required this.name, this.avatar});

  factory ResaleSeller.fromJson(Map<String, dynamic> json) {
    return ResaleSeller(
      name: json['name']?.toString() ?? 'Unknown Seller',
      avatar: json['avatar']?.toString(),
    );
  }
}

class ResaleGym {
  final String brandName;
  final String branchName;
  final String? logo;
  final String genderAllowed;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final double rating;

  const ResaleGym({
    required this.brandName,
    required this.branchName,
    this.logo,
    required this.genderAllowed,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    required this.rating,
  });

  factory ResaleGym.fromJson(Map<String, dynamic> json) {
    return ResaleGym(
      brandName: json['brand_name']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      logo: json['logo']?.toString(),
      genderAllowed: json['gender_allowed']?.toString() ?? 'mixed',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      distanceKm: json['distance_km'] != null
          ? double.tryParse(json['distance_km'].toString())
          : null,
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

class ResalePlan {
  final String name;
  final int daysLeft;

  const ResalePlan({required this.name, required this.daysLeft});

  factory ResalePlan.fromJson(Map<String, dynamic> json) {
    return ResalePlan(
      name: json['name']?.toString() ?? '',
      daysLeft: int.tryParse(json['days_left']?.toString() ?? '0') ?? 0,
    );
  }
}

class ResalePricing {
  final double askingPrice;
  final double fairValue;
  final int discountPercentage;

  const ResalePricing({
    required this.askingPrice,
    required this.fairValue,
    required this.discountPercentage,
  });

  factory ResalePricing.fromJson(Map<String, dynamic> json) {
    return ResalePricing(
      askingPrice:
          double.tryParse(json['asking_price']?.toString() ?? '0.0') ?? 0.0,
      fairValue:
          double.tryParse(json['fair_value']?.toString() ?? '0.0') ?? 0.0,
      discountPercentage:
          int.tryParse(json['discount_percentage']?.toString() ?? '0') ?? 0,
    );
  }
}

class ResaleItem {
  final int id;
  final ResaleSeller seller;
  final ResaleGym gym;
  final ResalePlan plan;
  final ResalePricing pricing;
  final String createdAt;

  const ResaleItem({
    required this.id,
    required this.seller,
    required this.gym,
    required this.plan,
    required this.pricing,
    required this.createdAt,
  });

  factory ResaleItem.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('ResaleItemModel');
    try {
      return ResaleItem(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        seller: ResaleSeller.fromJson(
          json['seller'] as Map<String, dynamic>? ?? {},
        ),
        gym: ResaleGym.fromJson(json['gym'] as Map<String, dynamic>? ?? {}),
        plan: ResalePlan.fromJson(json['plan'] as Map<String, dynamic>? ?? {}),
        pricing: ResalePricing.fromJson(
          json['pricing'] as Map<String, dynamic>? ?? {},
        ),
        createdAt: json['created_at']?.toString() ?? '',
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing ResaleItem', e, stackTrace);
      throw Exception('Failed to parse ResaleItem JSON');
    }
  }
}

class PaginatedResaleItems {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final bool hasNext;
  final bool hasPrevious;
  final List<ResaleItem> results;

  const PaginatedResaleItems({
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.hasNext,
    required this.hasPrevious,
    required this.results,
  });

  factory PaginatedResaleItems.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> meta =
        json['meta'] as Map<String, dynamic>? ?? {};

    return PaginatedResaleItems(
      totalItems: int.tryParse(meta['total_items']?.toString() ?? '0') ?? 0,
      totalPages: int.tryParse(meta['total_pages']?.toString() ?? '0') ?? 0,
      currentPage: int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1,
      hasNext: meta['has_next'] as bool? ?? false,
      hasPrevious: meta['has_previous'] as bool? ?? false,
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => ResaleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
