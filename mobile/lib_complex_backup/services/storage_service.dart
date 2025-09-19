import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/restaurant.dart';
import '../models/rsvp.dart';
import '../models/verified_visit.dart';
import '../models/wishlist.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic storage methods
  Future<void> _setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<String?> _getString(String key) async {
    return _prefs?.getString(key);
  }

  Future<void> _setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  Future<bool?> _getBool(String key) async {
    return _prefs?.getBool(key);
  }

  Future<void> _setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<int?> _getInt(String key) async {
    return _prefs?.getInt(key);
  }

  Future<void> _setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  Future<double?> _getDouble(String key) async {
    return _prefs?.getDouble(key);
  }

  Future<void> _setStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  Future<List<String>?> _getStringList(String key) async {
    return _prefs?.getStringList(key);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Remove specific key
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  // User preferences
  Future<void> setUserPreference(String key, dynamic value) async {
    final userKey = 'user_pref_$key';
    if (value is String) {
      await _setString(userKey, value);
    } else if (value is bool) {
      await _setBool(userKey, value);
    } else if (value is int) {
      await _setInt(userKey, value);
    } else if (value is double) {
      await _setDouble(userKey, value);
    } else if (value is List<String>) {
      await _setStringList(userKey, value);
    }
  }

  Future<T?> getUserPreference<T>(String key) async {
    final userKey = 'user_pref_$key';
    if (T == String) {
      return _getString(userKey) as T?;
    } else if (T == bool) {
      return _getBool(userKey) as T?;
    } else if (T == int) {
      return _getInt(userKey) as T?;
    } else if (T == double) {
      return _getDouble(userKey) as T?;
    } else if (T == List<String>) {
      return _getStringList(userKey) as T?;
    }
    return null;
  }

  // App settings
  Future<void> setAppSetting(String key, dynamic value) async {
    final settingKey = 'app_setting_$key';
    if (value is String) {
      await _setString(settingKey, value);
    } else if (value is bool) {
      await _setBool(settingKey, value);
    } else if (value is int) {
      await _setInt(settingKey, value);
    } else if (value is double) {
      await _setDouble(settingKey, value);
    }
  }

  Future<T?> getAppSetting<T>(String key) async {
    final settingKey = 'app_setting_$key';
    if (T == String) {
      return _getString(settingKey) as T?;
    } else if (T == bool) {
      return _getBool(settingKey) as T?;
    } else if (T == int) {
      return _getInt(settingKey) as T?;
    } else if (T == double) {
      return _getDouble(settingKey) as T?;
    }
    return null;
  }

  // Cache management
  Future<void> setCacheData(String key, Map<String, dynamic> data) async {
    final cacheKey = 'cache_$key';
    await _setString(cacheKey, jsonEncode(data));
    await _setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>?> getCacheData(String key, {Duration? maxAge}) async {
    final cacheKey = 'cache_$key';
    final data = await _getString(cacheKey);
    final timestamp = await _getInt('${cacheKey}_timestamp');
    
    if (data == null || timestamp == null) return null;
    
    if (maxAge != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > maxAge) {
        await remove(cacheKey);
        await remove('${cacheKey}_timestamp');
        return null;
      }
    }
    
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await remove(key);
      }
    }
  }

  // Restaurant cache
  Future<void> cacheRestaurants(List<Restaurant> restaurants) async {
    final data = restaurants.map((r) => r.toJson()).toList();
    await setCacheData('restaurants', {'restaurants': data});
  }

  Future<List<Restaurant>?> getCachedRestaurants() async {
    final data = await getCacheData('restaurants', maxAge: const Duration(hours: 1));
    if (data == null) return null;
    
    try {
      final List<dynamic> restaurants = data['restaurants'] ?? [];
      return restaurants.map((json) => Restaurant.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheCurrentRestaurant(Restaurant restaurant) async {
    await setCacheData('current_restaurant', restaurant.toJson());
  }

  Future<Restaurant?> getCachedCurrentRestaurant() async {
    final data = await getCacheData('current_restaurant', maxAge: const Duration(minutes: 30));
    if (data == null) return null;
    
    try {
      return Restaurant.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // RSVP cache
  Future<void> cacheRSVPs(List<RSVP> rsvps) async {
    final data = rsvps.map((r) => r.toJson()).toList();
    await setCacheData('rsvps', {'rsvps': data});
  }

  Future<List<RSVP>?> getCachedRSVPs() async {
    final data = await getCacheData('rsvps', maxAge: const Duration(minutes: 15));
    if (data == null) return null;
    
    try {
      final List<dynamic> rsvps = data['rsvps'] ?? [];
      return rsvps.map((json) => RSVP.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // Verified visits cache
  Future<void> cacheVerifiedVisits(List<VerifiedVisit> visits) async {
    final data = visits.map((v) => v.toJson()).toList();
    await setCacheData('verified_visits', {'verifiedVisits': data});
  }

  Future<List<VerifiedVisit>?> getCachedVerifiedVisits() async {
    final data = await getCacheData('verified_visits', maxAge: const Duration(hours: 2));
    if (data == null) return null;
    
    try {
      final List<dynamic> visits = data['verifiedVisits'] ?? [];
      return visits.map((json) => VerifiedVisit.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // Wishlist cache
  Future<void> cacheWishlist(List<WishlistItem> wishlist) async {
    final data = wishlist.map((w) => w.toJson()).toList();
    await setCacheData('wishlist', {'wishlist': data});
  }

  Future<List<WishlistItem>?> getCachedWishlist() async {
    final data = await getCacheData('wishlist', maxAge: const Duration(hours: 1));
    if (data == null) return null;
    
    try {
      final List<dynamic> wishlist = data['wishlist'] ?? [];
      return wishlist.map((json) => WishlistItem.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // Offline data management
  Future<void> setOfflineMode(bool enabled) async {
    await _setBool('offline_mode', enabled);
  }

  Future<bool> isOfflineMode() async {
    return await _getBool('offline_mode') ?? false;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _setInt('last_sync', time.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastSyncTime() async {
    final timestamp = await _getInt('last_sync');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Search history
  Future<void> addSearchHistory(String query) async {
    final history = await getSearchHistory();
    history.remove(query); // Remove if exists
    history.insert(0, query); // Add to beginning
    if (history.length > 20) {
      history.removeRange(20, history.length); // Keep only 20 items
    }
    await _setStringList('search_history', history);
  }

  Future<List<String>> getSearchHistory() async {
    return await _getStringList('search_history') ?? [];
  }

  Future<void> clearSearchHistory() async {
    await remove('search_history');
  }

  // Favorites
  Future<void> addFavorite(String restaurantId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(restaurantId)) {
      favorites.add(restaurantId);
      await _setStringList('favorites', favorites);
    }
  }

  Future<void> removeFavorite(String restaurantId) async {
    final favorites = await getFavorites();
    favorites.remove(restaurantId);
    await _setStringList('favorites', favorites);
  }

  Future<List<String>> getFavorites() async {
    return await _getStringList('favorites') ?? [];
  }

  Future<bool> isFavorite(String restaurantId) async {
    final favorites = await getFavorites();
    return favorites.contains(restaurantId);
  }

  // App state
  Future<void> setAppState(Map<String, dynamic> state) async {
    await _setString('app_state', jsonEncode(state));
  }

  Future<Map<String, dynamic>?> getAppState() async {
    final data = await _getString('app_state');
    if (data == null) return null;
    
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Debug info
  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'totalKeys': _prefs?.getKeys().length ?? 0,
      'cacheKeys': _prefs?.getKeys().where((k) => k.startsWith('cache_')).length ?? 0,
      'userPrefKeys': _prefs?.getKeys().where((k) => k.startsWith('user_pref_')).length ?? 0,
      'appSettingKeys': _prefs?.getKeys().where((k) => k.startsWith('app_setting_')).length ?? 0,
      'lastSync': await getLastSyncTime(),
      'offlineMode': await isOfflineMode(),
    };
  }
}

