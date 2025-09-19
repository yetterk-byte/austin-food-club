import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/offline_service.dart';

class OfflineProvider extends ChangeNotifier {
  final OfflineService _offlineService = OfflineService();
  
  bool _isOnline = true;
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String? _syncError;
  String? _currentSyncItem;
  CacheStatistics? _cacheStatistics;
  bool _offlineModeEnabled = true;
  
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncProgress>? _syncSubscription;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String? get syncError => _syncError;
  String? get currentSyncItem => _currentSyncItem;
  CacheStatistics? get cacheStatistics => _cacheStatistics;
  bool get offlineModeEnabled => _offlineModeEnabled;
  bool get isOffline => !_isOnline;

  // Initialize
  Future<void> initialize() async {
    try {
      await _offlineService.initialize();
      
      // Load settings
      _offlineModeEnabled = await _offlineService.getOfflineModeEnabled();
      
      // Subscribe to connectivity changes
      _connectivitySubscription = _offlineService.connectivityStream.listen(
        _onConnectivityChanged,
      );
      
      // Subscribe to sync progress
      _syncSubscription = _offlineService.syncStream.listen(
        _onSyncProgressChanged,
      );
      
      // Load cache statistics
      await loadCacheStatistics();
      
      debugPrint('OfflineProvider initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OfflineProvider: $e');
    }
  }

  // Connectivity handling
  void _onConnectivityChanged(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
      
      if (isOnline) {
        _onBackOnline();
      } else {
        _onGoOffline();
      }
    }
  }

  void _onBackOnline() {
    debugPrint('Back online - triggering sync');
    _clearSyncError();
    
    // Trigger sync after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (_offlineModeEnabled) {
        syncNow();
      }
    });
  }

  void _onGoOffline() {
    debugPrint('Gone offline');
    _isSyncing = false;
    notifyListeners();
  }

  // Sync handling
  void _onSyncProgressChanged(SyncProgress progress) {
    _isSyncing = progress.isActive;
    _syncProgress = progress.progress;
    _currentSyncItem = progress.currentItem;
    _syncError = progress.error;
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (!_isOnline || !_offlineModeEnabled) {
      debugPrint('Cannot sync - offline or offline mode disabled');
      return;
    }

    try {
      await _offlineService.syncPendingChanges();
      await loadCacheStatistics();
    } catch (e) {
      debugPrint('Manual sync failed: $e');
    }
  }

  // Cache management
  Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    await _offlineService.cacheData(key, data, expiry: expiry);
    await loadCacheStatistics();
  }

  Future<T?> getCachedData<T>(String key) async {
    return await _offlineService.getCachedData<T>(key);
  }

  Future<bool> isCacheValid(String key) async {
    return await _offlineService.isCacheValid(key);
  }

  Future<void> invalidateCache(String key) async {
    await _offlineService.invalidateCache(key);
    await loadCacheStatistics();
  }

  Future<void> clearAllCache() async {
    await _offlineService.clearAllCache();
    await loadCacheStatistics();
    notifyListeners();
  }

  // Settings
  Future<void> setOfflineModeEnabled(bool enabled) async {
    _offlineModeEnabled = enabled;
    await _offlineService.setOfflineModeEnabled(enabled);
    notifyListeners();
    
    if (enabled && _isOnline && !_isSyncing) {
      syncNow();
    }
  }

  // Statistics
  Future<void> loadCacheStatistics() async {
    try {
      _cacheStatistics = await _offlineService.getCacheStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load cache statistics: $e');
    }
  }

  // Offline data operations
  Future<void> saveDataOffline({
    required String type,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    switch (type) {
      case 'restaurant':
        await _offlineService.saveRestaurantOffline(data);
        break;
      case 'rsvp':
        await _offlineService.saveRSVPOffline(data);
        break;
      case 'verified_visit':
        await _offlineService.saveVerifiedVisitOffline(data);
        break;
    }
    
    await loadCacheStatistics();
    notifyListeners();
  }

  // Helper methods
  String getConnectionStatusText() {
    if (_isSyncing) {
      return 'Syncing...';
    } else if (_isOnline) {
      return 'Online';
    } else {
      return 'Offline';
    }
  }

  Color getConnectionStatusColor() {
    if (_isSyncing) {
      return const Color(0xFF2196F3); // Blue
    } else if (_isOnline) {
      return const Color(0xFF4CAF50); // Green
    } else {
      return const Color(0xFFFF9800); // Orange
    }
  }

  IconData getConnectionStatusIcon() {
    if (_isSyncing) {
      return Icons.sync;
    } else if (_isOnline) {
      return Icons.wifi;
    } else {
      return Icons.wifi_off;
    }
  }

  bool shouldShowOfflineIndicator() {
    return !_isOnline || _isSyncing;
  }

  String getSyncStatusText() {
    if (_syncError != null) {
      return 'Sync failed: $_syncError';
    } else if (_isSyncing) {
      final percentage = (_syncProgress * 100).round();
      return _currentSyncItem != null 
          ? 'Syncing $_currentSyncItem ($percentage%)'
          : 'Syncing... ($percentage%)';
    } else if (!_isOnline) {
      return 'Offline - changes will sync when connected';
    } else {
      return 'All changes synced';
    }
  }

  void _clearSyncError() {
    _syncError = null;
    notifyListeners();
  }

  // Cache helpers for specific data types
  Future<void> cacheRestaurants(List restaurants) async {
    await cacheData('restaurants', restaurants, expiry: const Duration(hours: 6));
  }

  Future<List?> getCachedRestaurants() async {
    return await getCachedData<List>('restaurants');
  }

  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    await cacheData('user_profile', profile, expiry: const Duration(hours: 24));
  }

  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    return await getCachedData<Map<String, dynamic>>('user_profile');
  }

  Future<void> cacheRSVPs(List rsvps) async {
    await cacheData('rsvps', rsvps, expiry: const Duration(hours: 1));
  }

  Future<List?> getCachedRSVPs() async {
    return await getCachedData<List>('rsvps');
  }

  Future<void> cacheVerifiedVisits(List visits) async {
    await cacheData('verified_visits', visits, expiry: const Duration(hours: 12));
  }

  Future<List?> getCachedVerifiedVisits() async {
    return await getCachedData<List>('verified_visits');
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncSubscription?.cancel();
    _offlineService.dispose();
    super.dispose();
  }
}

