import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/restaurant.dart';
import '../models/rsvp.dart';
import '../models/verified_visit.dart';
import '../models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const String _databaseName = 'austin_food_club.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String restaurantsTable = 'restaurants';
  static const String rsvpsTable = 'rsvps';
  static const String verifiedVisitsTable = 'verified_visits';
  static const String usersTable = 'users';
  static const String syncQueueTable = 'sync_queue';
  static const String cacheMetadataTable = 'cache_metadata';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Restaurants table
    await db.execute('''
      CREATE TABLE $restaurantsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        address TEXT NOT NULL,
        area TEXT NOT NULL,
        price INTEGER NOT NULL,
        image_url TEXT,
        cuisine_type TEXT,
        hours TEXT,
        phone TEXT,
        website TEXT,
        week_of TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_synced TEXT
      )
    ''');

    // RSVPs table
    await db.execute('''
      CREATE TABLE $rsvpsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        restaurant_id TEXT NOT NULL,
        day TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_synced TEXT
      )
    ''');

    // Verified visits table
    await db.execute('''
      CREATE TABLE $verifiedVisitsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        restaurant_id TEXT NOT NULL,
        visit_date TEXT NOT NULL,
        rating INTEGER NOT NULL,
        review TEXT,
        photo_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_synced TEXT
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE $usersTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        profile_image_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        last_synced TEXT
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE $syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry TEXT
      )
    ''');

    // Cache metadata table
    await db.execute('''
      CREATE TABLE $cacheMetadataTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        expires_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_restaurants_week_of ON $restaurantsTable(week_of)');
    await db.execute('CREATE INDEX idx_rsvps_user_id ON $rsvpsTable(user_id)');
    await db.execute('CREATE INDEX idx_rsvps_restaurant_id ON $rsvpsTable(restaurant_id)');
    await db.execute('CREATE INDEX idx_verified_visits_user_id ON $verifiedVisitsTable(user_id)');
    await db.execute('CREATE INDEX idx_sync_queue_table_name ON $syncQueueTable(table_name)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  // Restaurant operations
  Future<void> insertRestaurant(Restaurant restaurant) async {
    final db = await database;
    await db.insert(
      restaurantsTable,
      _restaurantToMap(restaurant),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertRestaurants(List<Restaurant> restaurants) async {
    final db = await database;
    final batch = db.batch();
    
    for (final restaurant in restaurants) {
      batch.insert(
        restaurantsTable,
        _restaurantToMap(restaurant),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  Future<List<Restaurant>> getRestaurants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(restaurantsTable);
    return maps.map((map) => _restaurantFromMap(map)).toList();
  }

  Future<Restaurant?> getRestaurant(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      restaurantsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return _restaurantFromMap(maps.first);
    }
    return null;
  }

  Future<Restaurant?> getCurrentRestaurant() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      restaurantsTable,
      orderBy: 'week_of DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return _restaurantFromMap(maps.first);
    }
    return null;
  }

  // RSVP operations
  Future<void> insertRSVP(RSVP rsvp) async {
    final db = await database;
    await db.insert(
      rsvpsTable,
      _rsvpToMap(rsvp),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RSVP>> getRSVPs({String? userId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = userId != null
        ? await db.query(
            rsvpsTable,
            where: 'user_id = ?',
            whereArgs: [userId],
          )
        : await db.query(rsvpsTable);
    
    return maps.map((map) => _rsvpFromMap(map)).toList();
  }

  Future<void> deleteRSVP(String id) async {
    final db = await database;
    await db.delete(
      rsvpsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Verified visits operations
  Future<void> insertVerifiedVisit(VerifiedVisit visit) async {
    final db = await database;
    await db.insert(
      verifiedVisitsTable,
      _verifiedVisitToMap(visit),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VerifiedVisit>> getVerifiedVisits({String? userId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = userId != null
        ? await db.query(
            verifiedVisitsTable,
            where: 'user_id = ?',
            whereArgs: [userId],
            orderBy: 'visit_date DESC',
          )
        : await db.query(
            verifiedVisitsTable,
            orderBy: 'visit_date DESC',
          );
    
    return maps.map((map) => _verifiedVisitFromMap(map)).toList();
  }

  // User operations
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      usersTable,
      _userToMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return _userFromMap(maps.first);
    }
    return null;
  }

  // Sync queue operations
  Future<void> addToSyncQueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert(syncQueueTable, {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query(
      syncQueueTable,
      orderBy: 'created_at ASC',
    );
  }

  Future<void> removeSyncQueueItem(int id) async {
    final db = await database;
    await db.delete(
      syncQueueTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSyncQueueRetry(int id) async {
    final db = await database;
    await db.update(
      syncQueueTable,
      {
        'retry_count': 'retry_count + 1',
        'last_retry': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cache metadata operations
  Future<void> setCacheMetadata(String key, String value, {DateTime? expiresAt}) async {
    final db = await database;
    await db.insert(
      cacheMetadataTable,
      {
        'key': key,
        'value': value,
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCacheMetadata(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      cacheMetadataTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (maps.isNotEmpty) {
      final expiresAt = maps.first['expires_at'] as String?;
      if (expiresAt != null) {
        final expiry = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expiry)) {
          // Cache expired, remove it
          await db.delete(
            cacheMetadataTable,
            where: 'key = ?',
            whereArgs: [key],
          );
          return null;
        }
      }
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> clearExpiredCache() async {
    final db = await database;
    await db.delete(
      cacheMetadataTable,
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  // Sync status operations
  Future<void> updateSyncStatus(String tableName, String recordId, String status) async {
    final db = await database;
    await db.update(
      tableName,
      {
        'sync_status': status,
        'last_synced': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String tableName) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
    );
  }

  // Database maintenance
  Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();
    
    batch.delete(restaurantsTable);
    batch.delete(rsvpsTable);
    batch.delete(verifiedVisitsTable);
    batch.delete(usersTable);
    batch.delete(syncQueueTable);
    batch.delete(cacheMetadataTable);
    
    await batch.commit();
  }

  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<int> getDatabaseSize() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA page_count');
    final pageCount = result.first['page_count'] as int;
    final pageSize = 4096; // Default SQLite page size
    return pageCount * pageSize;
  }

  // Helper methods for data conversion
  Map<String, dynamic> _restaurantToMap(Restaurant restaurant) {
    return {
      'id': restaurant.id,
      'name': restaurant.name,
      'description': restaurant.description,
      'address': restaurant.address,
      'area': restaurant.area,
      'price': restaurant.price,
      'image_url': restaurant.imageUrl,
      'cuisine_type': restaurant.cuisineType,
      'hours': restaurant.hours != null ? jsonEncode(restaurant.hours) : null,
      'phone': restaurant.phone,
      'website': restaurant.website,
      'week_of': restaurant.weekOf.toIso8601String(),
      'created_at': restaurant.createdAt.toIso8601String(),
      'updated_at': restaurant.updatedAt.toIso8601String(),
      'sync_status': 'synced',
      'last_synced': DateTime.now().toIso8601String(),
    };
  }

  Restaurant _restaurantFromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      address: map['address'] as String,
      area: map['area'] as String,
      price: map['price'] as int,
      imageUrl: map['image_url'] as String?,
      cuisineType: map['cuisine_type'] as String?,
      hours: map['hours'] != null ? Map<String, String>.from(jsonDecode(map['hours'])) : null,
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      weekOf: DateTime.parse(map['week_of'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> _rsvpToMap(RSVP rsvp) {
    return {
      'id': rsvp.id,
      'user_id': rsvp.userId,
      'restaurant_id': rsvp.restaurantId,
      'day': rsvp.day,
      'status': rsvp.status.name,
      'created_at': rsvp.createdAt.toIso8601String(),
      'updated_at': rsvp.updatedAt.toIso8601String(),
      'sync_status': 'synced',
      'last_synced': DateTime.now().toIso8601String(),
    };
  }

  RSVP _rsvpFromMap(Map<String, dynamic> map) {
    return RSVP(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      restaurantId: map['restaurant_id'] as String,
      day: map['day'] as String,
      status: RSVPStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => RSVPStatus.going,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> _verifiedVisitToMap(VerifiedVisit visit) {
    return {
      'id': visit.id,
      'user_id': visit.userId,
      'restaurant_id': visit.restaurantId,
      'visit_date': visit.visitDate.toIso8601String(),
      'rating': visit.rating,
      'review': visit.review,
      'photo_url': visit.photoUrl,
      'created_at': visit.createdAt.toIso8601String(),
      'updated_at': visit.updatedAt.toIso8601String(),
      'sync_status': 'synced',
      'last_synced': DateTime.now().toIso8601String(),
    };
  }

  VerifiedVisit _verifiedVisitFromMap(Map<String, dynamic> map) {
    return VerifiedVisit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      restaurantId: map['restaurant_id'] as String,
      visitDate: DateTime.parse(map['visit_date'] as String),
      rating: map['rating'] as int,
      review: map['review'] as String?,
      photoUrl: map['photo_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> _userToMap(User user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'profile_image_url': user.profileImageUrl,
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': user.updatedAt.toIso8601String(),
      'sync_status': 'synced',
      'last_synced': DateTime.now().toIso8601String(),
    };
  }

  User _userFromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Cleanup methods
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

