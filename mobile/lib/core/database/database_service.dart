import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_service.g.dart';

class DatabaseService {
  static final Logger _logger = Logger('DatabaseService');
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitzone_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incremented version to apply architectural fixes
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _ensureTablesExist,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    _logger.info('Creating SQLite database tables...');
    await _executeTableCreations(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    _logger.info(
      'Upgrading SQLite database from $oldVersion to $newVersion...',
    );
    // ARCHITECTURE FIX: Drop the old loyalty table as it is now user-specific API driven
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS loyalty_milestones');
    }
    await _executeTableCreations(db);
  }

  Future<void> _ensureTablesExist(Database db) async {
    _logger.info('Ensuring all static tables exist (Fail-safe check)...');
    await _executeTableCreations(db);
  }

  Future<void> _executeTableCreations(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS metadata (
        key TEXT PRIMARY KEY,
        value REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_types (
        id TEXT PRIMARY KEY,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cities (
        id TEXT PRIMARY KEY,
        name TEXT,
        lat REAL,
        lng REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sports (
        id INTEGER PRIMARY KEY,
        name TEXT,
        image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS amenities (
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

  // --- Batch Inserts ---

  Future<void> insertServiceTypes(List<dynamic> data) async =>
      _insertBatch('service_types', data);
  Future<void> insertCities(List<dynamic> data) async =>
      _insertBatch('cities', data);
  Future<void> insertSports(List<dynamic> data) async =>
      _insertBatch('sports', data);
  Future<void> insertAmenities(List<dynamic> data) async =>
      _insertBatch('amenities', data);

  Future<void> _insertBatch(String table, List<dynamic> data) async {
    final Database db = await database;
    final Batch batch = db.batch();
    batch.delete(table);
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

@Riverpod(keepAlive: true)
DatabaseService databaseService(Ref ref) {
  return DatabaseService();
}
