import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';

import 'database_service.dart';
import '../../features/loyalty/data/models/loyalty_models.dart';

part 'local_data_provider.g.dart';

/// A wrapper class to hold all static data required for the app.
class AppStaticData {
  final List<Map<String, dynamic>> serviceTypes;
  final List<Map<String, dynamic>> cities;
  final List<Map<String, dynamic>> sports;
  final List<Map<String, dynamic>> amenities;
  final List<LoyaltyMilestone> loyaltyRoadmap;

  AppStaticData({
    required this.serviceTypes,
    required this.cities,
    required this.sports,
    required this.amenities,
    required this.loyaltyRoadmap,
  });
}

/// Fetches and bundles all static data from SQLite.
@riverpod
Future<AppStaticData> appStaticData(Ref ref) async {
  final DatabaseService dbService = ref.watch(databaseServiceProvider);
  final Logger logger = Logger('AppStaticDataProvider');

  try {
    // Fetch all data concurrently for maximum performance
    final results = await Future.wait([
      dbService.getServiceTypes(),
      dbService.getCities(),
      dbService.getSports(),
      dbService.getAmenities(),
      dbService.getLoyaltyMilestones(), // Fetching the flattened milestones
    ]);

    // Parse the raw SQLite Maps into strongly typed Dart Objects
    final List<Map<String, dynamic>> rawMilestones = results[4];
    final List<LoyaltyMilestone> parsedMilestones = rawMilestones
        .map((map) => LoyaltyMilestone.fromDbMap(map))
        .toList();

    logger.info(
      'Successfully loaded all static data and loyalty roadmap from local DB.',
    );

    return AppStaticData(
      serviceTypes: results[0],
      cities: results[1],
      sports: results[2],
      amenities: results[3],
      loyaltyRoadmap: parsedMilestones,
    );
  } catch (e, stackTrace) {
    logger.severe('Failed to load static data', e, stackTrace);
    // Return empty data to prevent app crash if DB fails
    return AppStaticData(
      serviceTypes: [],
      cities: [],
      sports: [],
      amenities: [],
      loyaltyRoadmap: [],
    );
  }
}
