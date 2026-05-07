import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:logging/logging.dart';

import 'database_service.dart';

part 'local_data_provider.g.dart';

/// A wrapper class to hold all static data required for the app.
class AppStaticData {
  final List<Map<String, dynamic>> serviceTypes;
  final List<Map<String, dynamic>> cities;
  final List<Map<String, dynamic>> sports;
  final List<Map<String, dynamic>> amenities;

  AppStaticData({
    required this.serviceTypes,
    required this.cities,
    required this.sports,
    required this.amenities,
  });
}

/// Fetches and bundles all static data from SQLite.
@riverpod
Future<AppStaticData> appStaticData(Ref ref) async {
  final DatabaseService dbService = ref.watch(databaseServiceProvider);
  final Logger logger = Logger('AppStaticDataProvider');

  try {
    final results = await Future.wait([
      dbService.getServiceTypes(),
      dbService.getCities(),
      dbService.getSports(),
      dbService.getAmenities(),
    ]);

    logger.info('Successfully loaded all static data from local DB.');

    return AppStaticData(
      serviceTypes: results[0],
      cities: results[1],
      sports: results[2],
      amenities: results[3],
    );
  } catch (e, stackTrace) {
    logger.severe('Failed to load static data', e, stackTrace);
    return AppStaticData(
      serviceTypes: [],
      cities: [],
      sports: [],
      amenities: [],
    );
  }
}
