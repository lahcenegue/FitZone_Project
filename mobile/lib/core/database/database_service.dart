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

    // ARCHITECTURE FIX: We use onOpen to guarantee table creation even if onUpgrade fails or is bypassed
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _ensureTablesExist, // The ultimate fail-safe
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
    await _executeTableCreations(db);
  }

  Future<void> _ensureTablesExist(Database db) async {
    _logger.info('Ensuring all tables exist (Fail-safe check)...');
    await _executeTableCreations(db);
  }

  /// Extracts the creation logic to be reused in onCreate, onUpgrade, and onOpen safely
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

    // This is the table that was throwing the error
    await db.execute('''
      CREATE TABLE IF NOT EXISTS loyalty_milestones (
        id INTEGER PRIMARY KEY,
        title TEXT,
        required_lifetime_points INTEGER,
        reward_id INTEGER,
        reward_name TEXT,
        reward_action_type TEXT,
        reward_action_value REAL,
        description TEXT
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

  Future<void> insertLoyaltyMilestones(List<dynamic> data) async {
    final Database db = await database;
    final Batch batch = db.batch();

    batch.delete('loyalty_milestones');

    for (final dynamic item in data) {
      final Map<String, dynamic> map = item as Map<String, dynamic>;
      final Map<String, dynamic> reward =
          map['reward'] as Map<String, dynamic>? ?? {};

      batch.insert('loyalty_milestones', {
        'id': map['id'],
        'title': map['title']?.toString(),
        'required_lifetime_points': map['required_lifetime_points'],
        'reward_id': reward['id'],
        'reward_name': reward['name']?.toString(),
        'reward_action_type': reward['action_type']?.toString(),
        'reward_action_value': reward['action_value'],
        'description': map['description']?.toString(),
      });
    }

    await batch.commit(noResult: true);
    _logger.info(
      'Successfully inserted ${data.length} records into loyalty_milestones',
    );
  }

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

  Future<List<Map<String, dynamic>>> getLoyaltyMilestones() async {
    final Database db = await database;
    return await db.query(
      'loyalty_milestones',
      orderBy: 'required_lifetime_points ASC',
    );
  }
}

@Riverpod(keepAlive: true)
DatabaseService databaseService(Ref ref) {
  return DatabaseService();
}
