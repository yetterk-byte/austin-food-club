import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'database_service.dart';

enum SyncStatus {
  synced,
  pending,
  failed,
  syncing,
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final Connectivity _connectivity = Connectivity();
  
  late Box _cacheBox;
  late Box _settingsBox;
  
  bool _isOnline = true;
  bool _isInitialized = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Cache settings
  static const Duration defaultCacheExpiry = Duration(hours: 24);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(minutes: 5);

  // Getters
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;

  // Stream controllers
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final StreamController<SyncProgress> _syncController = StreamController<SyncProgress>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<SyncProgress> get syncStream => _syncController.stream;

  // Initialize offline service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();
      _cacheBox = await Hive.openBox('cache');
      _settingsBox = await Hive.openBox('settings');

      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      // Start periodic sync when online
      if (_isOnline) {
        _startPeriodicSync();
      }

      // Clear expired cache
      await _clearExpiredCache();

      _isInitialized = true;
      debugPrint('OfflineService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OfflineService: $e');
    }
  }

  // Connectivity handling
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    debugPrint('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
    _connectivityController.add(_isOnline);

    if (!wasOnline && _isOnline) {
      // Just came back online
      _onBackOnline();
    }
  }

  Future<void> _onBackOnline() async {
    debugPrint('Back online - starting sync');
    await syncPendingChanges();
  }

  // Cache management
  Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    try {
      final cacheItem = {
        'data': data,
        'cached_at': DateTime.now().toIso8601String(),
        'expires_at': (expiry != null 
            ? DateTime.now().add(expiry) 
            : DateTime.now().add(defaultCacheExpiry)).toIso8601String(),
      };
      
      await _cacheBox.put(key, cacheItem);
      debugPrint('Cached data for key: $key');
    } catch (e) {
      debugPrint('Failed to cache data for key $key: $e');
    }
  }

  Future<T?> getCachedData<T>(String key) async {
    try {
      final cacheItem = _cacheBox.get(key);
      if (cacheItem == null) return null;

      final expiresAt = DateTime.parse(cacheItem['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        // Cache expired
        await _cacheBox.delete(key);
        return null;
      }

      return cacheItem['data'] as T;
    } catch (e) {
      debugPrint('Failed to get cached data for key $key: $e');
      return null;
    }
  }

  Future<bool> isCacheValid(String key) async {
    try {
      final cacheItem = _cacheBox.get(key);
      if (cacheItem == null) return false;

      final expiresAt = DateTime.parse(cacheItem['expires_at']);
      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      return false;
    }
  }

  Future<void> invalidateCache(String key) async {
    await _cacheBox.delete(key);
  }

  Future<void> clearAllCache() async {
    await _cacheBox.clear();
    await _databaseService.clearAllData();
  }

  Future<void> _clearExpiredCache() async {
    try {
      final keys = _cacheBox.keys.toList();
      for (final key in keys) {
        final isValid = await isCacheValid(key);
        if (!isValid) {
          await _cacheBox.delete(key);
        }
      }
      
      await _databaseService.clearExpiredCache();
    } catch (e) {
      debugPrint('Failed to clear expired cache: $e');
    }
  }

  // Sync operations
  Future<void> syncPendingChanges() async {
    if (!_isOnline) {
      debugPrint('Cannot sync - offline');
      return;
    }

    try {
      _syncController.add(SyncProgress(isActive: true, progress: 0.0));

      final syncQueue = await _databaseService.getSyncQueue();
      if (syncQueue.isEmpty) {
        _syncController.add(SyncProgress(isActive: false, progress: 1.0));
        return;
      }

      debugPrint('Syncing ${syncQueue.length} pending changes');

      for (int i = 0; i < syncQueue.length; i++) {
        final item = syncQueue[i];
        final progress = (i + 1) / syncQueue.length;
        
        _syncController.add(SyncProgress(
          isActive: true,
          progress: progress,
          currentItem: '${item['table_name']} - ${item['operation']}',
        ));

        try {
          await _syncQueueItem(item);
          await _databaseService.removeSyncQueueItem(item['id']);
        } catch (e) {
          debugPrint('Failed to sync item ${item['id']}: $e');
          await _databaseService.updateSyncQueueRetry(item['id']);
        }

        // Small delay between sync operations
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _syncController.add(SyncProgress(isActive: false, progress: 1.0));
      debugPrint('Sync completed');
    } catch (e) {
      debugPrint('Sync failed: $e');
      _syncController.add(SyncProgress(
        isActive: false,
        progress: 0.0,
        error: e.toString(),
      ));
    }
  }

  Future<void> _syncQueueItem(Map<String, dynamic> item) async {
    final tableName = item['table_name'] as String;
    final recordId = item['record_id'] as String;
    final operation = item['operation'] as String;
    final data = jsonDecode(item['data'] as String);

    // This would make actual API calls to sync data
    // For now, we'll simulate the sync operation
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint('Synced $operation for $tableName record $recordId');
  }

  void _startPeriodicSync() {
    Timer.periodic(const Duration(minutes: 15), (timer) {
      if (_isOnline) {
        syncPendingChanges();
      }
    });
  }

  // Queue operations for offline
  Future<void> queueOperation({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    await _databaseService.addToSyncQueue(
      tableName: tableName,
      recordId: recordId,
      operation: operation,
      data: data,
    );

    // Mark record as pending sync
    await _databaseService.updateSyncStatus(tableName, recordId, 'pending');

    // Try to sync immediately if online
    if (_isOnline) {
      unawaited(syncPendingChanges());
    }
  }

  // Offline-first data operations
  Future<void> saveRestaurantOffline(Map<String, dynamic> restaurantData) async {
    // Save to local database
    await _databaseService.insertRestaurant(
      Restaurant.fromJson(restaurantData),
    );

    // Queue for sync
    await queueOperation(
      tableName: DatabaseService.restaurantsTable,
      recordId: restaurantData['id'],
      operation: 'create',
      data: restaurantData,
    );
  }

  Future<void> saveRSVPOffline(Map<String, dynamic> rsvpData) async {
    // Save to local database
    await _databaseService.insertRSVP(
      RSVP.fromJson(rsvpData),
    );

    // Queue for sync
    await queueOperation(
      tableName: DatabaseService.rsvpsTable,
      recordId: rsvpData['id'],
      operation: 'create',
      data: rsvpData,
    );
  }

  Future<void> saveVerifiedVisitOffline(Map<String, dynamic> visitData) async {
    // Save to local database
    await _databaseService.insertVerifiedVisit(
      VerifiedVisit.fromJson(visitData),
    );

    // Queue for sync
    await queueOperation(
      tableName: DatabaseService.verifiedVisitsTable,
      recordId: visitData['id'],
      operation: 'create',
      data: visitData,
    );
  }

  // Settings management
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<bool> getOfflineModeEnabled() async {
    return await getSetting('offline_mode_enabled', defaultValue: true) ?? true;
  }

  Future<void> setOfflineModeEnabled(bool enabled) async {
    await setSetting('offline_mode_enabled', enabled);
  }

  // Cache statistics
  Future<CacheStatistics> getCacheStatistics() async {
    final cacheSize = _cacheBox.length;
    final databaseSize = await _databaseService.getDatabaseSize();
    final syncQueueSize = (await _databaseService.getSyncQueue()).length;
    
    return CacheStatistics(
      cacheItemCount: cacheSize,
      databaseSizeBytes: databaseSize,
      pendingSyncItems: syncQueueSize,
      lastSyncTime: await getSetting('last_sync_time'),
    );
  }

  // Cleanup
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _connectivityController.close();
    await _syncController.close();
    await _cacheBox.close();
    await _settingsBox.close();
    await _databaseService.close();
  }
}

// Sync progress model
class SyncProgress {
  final bool isActive;
  final double progress;
  final String? currentItem;
  final String? error;

  const SyncProgress({
    required this.isActive,
    required this.progress,
    this.currentItem,
    this.error,
  });
}

// Cache statistics model
class CacheStatistics {
  final int cacheItemCount;
  final int databaseSizeBytes;
  final int pendingSyncItems;
  final DateTime? lastSyncTime;

  const CacheStatistics({
    required this.cacheItemCount,
    required this.databaseSizeBytes,
    required this.pendingSyncItems,
    this.lastSyncTime,
  });

  String get formattedDatabaseSize {
    if (databaseSizeBytes < 1024) {
      return '$databaseSizeBytes B';
    } else if (databaseSizeBytes < 1024 * 1024) {
      return '${(databaseSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(databaseSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

