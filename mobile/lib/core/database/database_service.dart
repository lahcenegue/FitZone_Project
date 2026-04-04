import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_service.g.dart';

/// Core service for managing the local SQLite database.
/// Used strictly for structured, relational static data (Cities, Sports, etc.).
class DatabaseService {
  static final Logger _logger = Logger('DatabaseService');
  static Database? _database;

  /// Retrieves the active database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitzone_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    _logger.info('Creating SQLite database tables...');

    await db.execute('''
      CREATE TABLE metadata (
        key TEXT PRIMARY KEY,
        value REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE service_types (
        id TEXT PRIMARY KEY,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cities (
        id TEXT PRIMARY KEY,
        name TEXT,
        lat REAL,
        lng REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE sports (
        id INTEGER PRIMARY KEY,
        name TEXT,
        image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE amenities (
        id INTEGER PRIMARY KEY,
        name TEXT,
        icon_image TEXT
      )
    ''');
  }

  // --- Metadata (Version Control) ---

  Future<double> getVersion(String key) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return (maps.first['value'] as num).toDouble();
    }
    return 0.0;
  }

  Future<void> setVersion(String key, double version) async {
    final Database db = await database;
    await db.insert('metadata', {
      'key': key,
      'value': version,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Batch Inserts (High Performance) ---

  Future<void> insertServiceTypes(List<dynamic> data) async =>
      _insertBatch('service_types', data);
  Future<void> insertCities(List<dynamic> data) async =>
      _insertBatch('cities', data);
  Future<void> insertSports(List<dynamic> data) async =>
      _insertBatch('sports', data);
  Future<void> insertAmenities(List<dynamic> data) async =>
      _insertBatch('amenities', data);

  /// Helper method to perform atomic batch inserts.
  Future<void> _insertBatch(String table, List<dynamic> data) async {
    final Database db = await database;
    final Batch batch = db.batch();

    // Clear old data to prevent stale records
    batch.delete(table);

    // Insert fresh data
    for (final dynamic item in data) {
      batch.insert(table, Map<String, dynamic>.from(item as Map));
    }

    await batch.commit(noResult: true);
    _logger.info('Successfully inserted ${data.length} records into $table');
  }

  // --- Data Retrieval ---

  Future<List<Map<String, dynamic>>> getServiceTypes() async =>
      (await database).query('service_types');
  Future<List<Map<String, dynamic>>> getCities() async =>
      (await database).query('cities');
  Future<List<Map<String, dynamic>>> getSports() async =>
      (await database).query('sports');
  Future<List<Map<String, dynamic>>> getAmenities() async =>
      (await database).query('amenities');
}

/// Global provider for the SQLite Database Service.
@Riverpod(keepAlive: true)
DatabaseService databaseService(Ref ref) {
  return DatabaseService();
}
