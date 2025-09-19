import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';
import '../models/rsvp.dart';
import '../models/verified_visit.dart';
import '../models/user.dart';
import 'database_service.dart';
import 'offline_service.dart';

class OfflineApiService {
  static final OfflineApiService _instance = OfflineApiService._internal();
  factory OfflineApiService() => _instance;
  OfflineApiService._internal();

  final Dio _dio = Dio();
  final DatabaseService _databaseService = DatabaseService();
  final OfflineService _offlineService = OfflineService();

  static const String baseUrl = 'https://api.austinfoodclub.com';

  // Initialize with interceptors
  void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth headers if available
          // options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle offline errors
          if (_isNetworkError(error)) {
            debugPrint('Network error detected - using offline mode');
          }
          handler.next(error);
        },
      ),
    );
  }

  // Restaurant operations
  Future<Restaurant?> getCurrentRestaurant() async {
    const cacheKey = 'current_restaurant';
    
    try {
      if (_offlineService.isOnline) {
        // Try to fetch from API
        final response = await _dio.get('$baseUrl/restaurants/current');
        
        if (response.statusCode == 200) {
          final restaurant = Restaurant.fromJson(response.data['restaurant']);
          
          // Cache the result
          await _offlineService.cacheData(cacheKey, restaurant.toJson());
          await _databaseService.insertRestaurant(restaurant);
          
          return restaurant;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch current restaurant from API: $e');
    }

    // Fallback to cached data
    try {
      final cachedData = await _offlineService.getCachedData<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return Restaurant.fromJson(cachedData);
      }

      // Fallback to database
      return await _databaseService.getCurrentRestaurant();
    } catch (e) {
      debugPrint('Failed to get cached current restaurant: $e');
      return null;
    }
  }

  Future<List<Restaurant>> getAllRestaurants() async {
    const cacheKey = 'all_restaurants';
    
    try {
      if (_offlineService.isOnline) {
        // Try to fetch from API
        final response = await _dio.get('$baseUrl/restaurants');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['restaurants'];
          final restaurants = data.map((json) => Restaurant.fromJson(json)).toList();
          
          // Cache the result
          await _offlineService.cacheData(cacheKey, data);
          await _databaseService.insertRestaurants(restaurants);
          
          return restaurants;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch restaurants from API: $e');
    }

    // Fallback to cached data
    try {
      final cachedData = await _offlineService.getCachedData<List>(cacheKey);
      if (cachedData != null) {
        return cachedData.map((json) => Restaurant.fromJson(json)).toList();
      }

      // Fallback to database
      return await _databaseService.getRestaurants();
    } catch (e) {
      debugPrint('Failed to get cached restaurants: $e');
      return [];
    }
  }

  Future<Restaurant?> getRestaurant(String id) async {
    final cacheKey = 'restaurant_$id';
    
    try {
      if (_offlineService.isOnline) {
        // Try to fetch from API
        final response = await _dio.get('$baseUrl/restaurants/$id');
        
        if (response.statusCode == 200) {
          final restaurant = Restaurant.fromJson(response.data['restaurant']);
          
          // Cache the result
          await _offlineService.cacheData(cacheKey, restaurant.toJson());
          await _databaseService.insertRestaurant(restaurant);
          
          return restaurant;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch restaurant $id from API: $e');
    }

    // Fallback to cached data
    try {
      final cachedData = await _offlineService.getCachedData<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return Restaurant.fromJson(cachedData);
      }

      // Fallback to database
      return await _databaseService.getRestaurant(id);
    } catch (e) {
      debugPrint('Failed to get cached restaurant $id: $e');
      return null;
    }
  }

  // RSVP operations
  Future<RSVP?> createRSVP({
    required String restaurantId,
    required String day,
    required String userId,
  }) async {
    final rsvpData = {
      'id': _generateId(),
      'userId': userId,
      'restaurantId': restaurantId,
      'day': day,
      'status': 'going',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      if (_offlineService.isOnline) {
        // Try to create via API
        final response = await _dio.post(
          '$baseUrl/rsvps',
          data: rsvpData,
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final rsvp = RSVP.fromJson(response.data['rsvp']);
          await _databaseService.insertRSVP(rsvp);
          return rsvp;
        }
      }
    } catch (e) {
      debugPrint('Failed to create RSVP via API: $e');
    }

    // Save offline
    await _offlineService.saveRSVPOffline(rsvpData);
    return RSVP.fromJson(rsvpData);
  }

  Future<List<RSVP>> getUserRSVPs(String userId) async {
    final cacheKey = 'user_rsvps_$userId';
    
    try {
      if (_offlineService.isOnline) {
        // Try to fetch from API
        final response = await _dio.get('$baseUrl/rsvps/user/$userId');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['rsvps'];
          final rsvps = data.map((json) => RSVP.fromJson(json)).toList();
          
          // Cache and store
          await _offlineService.cacheData(cacheKey, data);
          for (final rsvp in rsvps) {
            await _databaseService.insertRSVP(rsvp);
          }
          
          return rsvps;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch RSVPs from API: $e');
    }

    // Fallback to cached data
    try {
      final cachedData = await _offlineService.getCachedData<List>(cacheKey);
      if (cachedData != null) {
        return cachedData.map((json) => RSVP.fromJson(json)).toList();
      }

      // Fallback to database
      return await _databaseService.getRSVPs(userId: userId);
    } catch (e) {
      debugPrint('Failed to get cached RSVPs: $e');
      return [];
    }
  }

  // Verified visits operations
  Future<VerifiedVisit?> createVerifiedVisit({
    required String userId,
    required String restaurantId,
    required DateTime visitDate,
    required int rating,
    String? review,
    String? photoUrl,
  }) async {
    final visitData = {
      'id': _generateId(),
      'userId': userId,
      'restaurantId': restaurantId,
      'visitDate': visitDate.toIso8601String(),
      'rating': rating,
      'review': review,
      'photoUrl': photoUrl,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      if (_offlineService.isOnline) {
        // Try to create via API
        final response = await _dio.post(
          '$baseUrl/verified-visits',
          data: visitData,
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final visit = VerifiedVisit.fromJson(response.data['visit']);
          await _databaseService.insertVerifiedVisit(visit);
          return visit;
        }
      }
    } catch (e) {
      debugPrint('Failed to create verified visit via API: $e');
    }

    // Save offline
    await _offlineService.saveVerifiedVisitOffline(visitData);
    return VerifiedVisit.fromJson(visitData);
  }

  Future<List<VerifiedVisit>> getUserVerifiedVisits(String userId) async {
    final cacheKey = 'user_verified_visits_$userId';
    
    try {
      if (_offlineService.isOnline) {
        // Try to fetch from API
        final response = await _dio.get('$baseUrl/verified-visits/user/$userId');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['visits'];
          final visits = data.map((json) => VerifiedVisit.fromJson(json)).toList();
          
          // Cache and store
          await _offlineService.cacheData(cacheKey, data);
          for (final visit in visits) {
            await _databaseService.insertVerifiedVisit(visit);
          }
          
          return visits;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch verified visits from API: $e');
    }

    // Fallback to cached data
    try {
      final cachedData = await _offlineService.getCachedData<List>(cacheKey);
      if (cachedData != null) {
        return cachedData.map((json) => VerifiedVisit.fromJson(json)).toList();
      }

      // Fallback to database
      return await _databaseService.getVerifiedVisits(userId: userId);
    } catch (e) {
      debugPrint('Failed to get cached verified visits: $e');
      return [];
    }
  }

  // User operations
  Future<User?> getUser(String userId) async {
    final cacheKey = 'user_$userId';
    
    try {
      if (_offlineService.isOnline) {
        // Try to fetch from API
        final response = await _dio.get('$baseUrl/users/$userId');
        
        if (response.statusCode == 200) {
          final user = User.fromJson(response.data['user']);
          
          // Cache and store
          await _offlineService.cacheData(cacheKey, user.toJson());
          await _databaseService.insertUser(user);
          
          return user;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch user from API: $e');
    }

    // Fallback to cached data
    try {
      final cachedData = await _offlineService.getCachedData<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return User.fromJson(cachedData);
      }

      // Fallback to database
      return await _databaseService.getUser(userId);
    } catch (e) {
      debugPrint('Failed to get cached user: $e');
      return null;
    }
  }

  // Helper methods
  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Cache invalidation
  Future<void> invalidateRestaurantCache() async {
    await _offlineService.invalidateCache('current_restaurant');
    await _offlineService.invalidateCache('all_restaurants');
  }

  Future<void> invalidateUserCache(String userId) async {
    await _offlineService.invalidateCache('user_$userId');
    await _offlineService.invalidateCache('user_rsvps_$userId');
    await _offlineService.invalidateCache('user_verified_visits_$userId');
  }

  // Batch operations for better performance
  Future<void> preloadEssentialData(String userId) async {
    if (!_offlineService.isOnline) return;

    try {
      // Preload in parallel
      await Future.wait([
        getCurrentRestaurant(),
        getAllRestaurants(),
        getUserRSVPs(userId),
        getUserVerifiedVisits(userId),
        getUser(userId),
      ]);
      
      debugPrint('Essential data preloaded successfully');
    } catch (e) {
      debugPrint('Failed to preload essential data: $e');
    }
  }

  // Check if data is available offline
  Future<bool> isDataAvailableOffline(String type, {String? userId}) async {
    switch (type) {
      case 'current_restaurant':
        return await _offlineService.isCacheValid('current_restaurant') ||
               await _databaseService.getCurrentRestaurant() != null;
      case 'all_restaurants':
        return await _offlineService.isCacheValid('all_restaurants') ||
               (await _databaseService.getRestaurants()).isNotEmpty;
      case 'user_rsvps':
        return await _offlineService.isCacheValid('user_rsvps_$userId') ||
               (await _databaseService.getRSVPs(userId: userId)).isNotEmpty;
      case 'verified_visits':
        return await _offlineService.isCacheValid('user_verified_visits_$userId') ||
               (await _databaseService.getVerifiedVisits(userId: userId)).isNotEmpty;
      default:
        return false;
    }
  }

  // Get offline-first data with fallback chain
  Future<T?> getOfflineFirstData<T>({
    required String cacheKey,
    required Future<T> Function() apiCall,
    required Future<T?> Function() cacheCall,
    Duration? cacheExpiry,
  }) async {
    try {
      // 1. Try cache first if offline or cache is still valid
      if (!_offlineService.isOnline || await _offlineService.isCacheValid(cacheKey)) {
        final cachedData = await cacheCall();
        if (cachedData != null) {
          return cachedData;
        }
      }

      // 2. Try API if online
      if (_offlineService.isOnline) {
        final apiData = await apiCall();
        
        // Cache the API result
        if (apiData != null) {
          await _offlineService.cacheData(cacheKey, apiData, expiry: cacheExpiry);
        }
        
        return apiData;
      }

      // 3. Fallback to any cached data
      return await cacheCall();
    } catch (e) {
      debugPrint('Error in getOfflineFirstData for $cacheKey: $e');
      
      // Final fallback to cache
      try {
        return await cacheCall();
      } catch (cacheError) {
        debugPrint('Cache fallback failed for $cacheKey: $cacheError');
        return null;
      }
    }
  }

  // Queue operations for offline mode
  Future<void> queueRSVPCreation(Map<String, dynamic> rsvpData) async {
    await _offlineService.queueOperation(
      tableName: DatabaseService.rsvpsTable,
      recordId: rsvpData['id'],
      operation: 'create',
      data: rsvpData,
    );
  }

  Future<void> queueRSVPDeletion(String rsvpId) async {
    await _offlineService.queueOperation(
      tableName: DatabaseService.rsvpsTable,
      recordId: rsvpId,
      operation: 'delete',
      data: {'id': rsvpId},
    );
  }

  Future<void> queueVerifiedVisitCreation(Map<String, dynamic> visitData) async {
    await _offlineService.queueOperation(
      tableName: DatabaseService.verifiedVisitsTable,
      recordId: visitData['id'],
      operation: 'create',
      data: visitData,
    );
  }

  // Sync helpers
  Future<bool> hasPendingChanges() async {
    final syncQueue = await _databaseService.getSyncQueue();
    return syncQueue.isNotEmpty;
  }

  Future<int> getPendingChangesCount() async {
    final syncQueue = await _databaseService.getSyncQueue();
    return syncQueue.length;
  }

  Future<List<String>> getPendingChangesSummary() async {
    final syncQueue = await _databaseService.getSyncQueue();
    return syncQueue.map((item) => 
        '${item['operation']} ${item['table_name']}').toList();
  }
}

