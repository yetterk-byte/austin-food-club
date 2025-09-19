import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/restaurant.dart';
import '../models/rsvp.dart';
import '../models/verified_visit.dart';
import '../models/wishlist.dart';
import '../models/user.dart';

// Custom Exception Classes
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message, {int? statusCode, String? errorCode}) 
      : super(message, statusCode: statusCode, errorCode: errorCode);
}

class ParsingException extends ApiException {
  ParsingException(String message) : super(message);
}

class AuthException extends ApiException {
  AuthException(String message) : super(message);
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _authToken;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.addAll([
      // Auth interceptor
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          handler.next(options);
        },
      ),
      
      // Logging interceptor
      if (kDebugMode)
        InterceptorsWrapper(
          onRequest: (options, handler) {
            print('🚀 API Request: ${options.method} ${options.uri}');
            print('📤 Headers: ${options.headers}');
            if (options.data != null) {
              print('📤 Data: ${options.data}');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            print('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
            print('📥 Data: ${response.data}');
            handler.next(response);
          },
          onError: (error, handler) {
            print('❌ API Error: ${error.response?.statusCode} ${error.requestOptions.uri}');
            print('📥 Error Data: ${error.response?.data}');
            handler.next(error);
          },
        ),
      
      // Retry interceptor
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    ]);
  }

  bool _shouldRetry(DioException error) {
    // Retry on network errors or 5xx server errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    
    if (error.response?.statusCode != null) {
      final statusCode = error.response!.statusCode!;
      return statusCode >= 500 && statusCode < 600;
    }
    
    return false;
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // Caching methods
  void _setCache(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  dynamic _getCache(String key, {Duration? ttl}) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;
    
    if (ttl != null && DateTime.now().difference(timestamp) > ttl) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _cache[key];
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Authentication methods
  Future<User> login(String phoneNumber) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phoneNumber': phoneNumber,
      });
      
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      });
      
      if (response.data['success'] == true) {
        final token = response.data['token'] as String?;
        if (token != null) {
          setAuthToken(token);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      // Continue with logout even if server call fails
      print('Logout server call failed: ${e.message}');
    } finally {
      clearAuthToken();
      clearCache();
    }
  }

  // Restaurant endpoints
  Future<List<Restaurant>> getAllRestaurants() async {
    const cacheKey = 'all_restaurants';
    const cacheTtl = Duration(minutes: 5);
    
    // Check cache first
    final cachedData = _getCache(cacheKey, ttl: cacheTtl);
    if (cachedData != null) {
      return (cachedData as List).map((json) => Restaurant.fromJson(json)).toList();
    }
    
    try {
      final response = await _dio.get(AppConstants.restaurantsEndpoint);
      final List<dynamic> data = response.data['restaurants'] ?? response.data;
      final restaurants = data.map((json) => Restaurant.fromJson(json)).toList();
      
      // Cache the result
      _setCache(cacheKey, data, ttl: cacheTtl);
      
      return restaurants;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Restaurant> getRestaurantById(String id) async {
    final cacheKey = 'restaurant_$id';
    const cacheTtl = Duration(minutes: 10);
    
    // Check cache first
    final cachedData = _getCache(cacheKey, ttl: cacheTtl);
    if (cachedData != null) {
      return Restaurant.fromJson(cachedData);
    }
    
    try {
      final response = await _dio.get('${AppConstants.restaurantsEndpoint}/$id');
      final restaurant = Restaurant.fromJson(response.data);
      
      // Cache the result
      _setCache(cacheKey, response.data, ttl: cacheTtl);
      
      return restaurant;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Restaurant> getCurrentRestaurant() async {
    const cacheKey = 'current_restaurant';
    const cacheTtl = Duration(minutes: 15);
    
    // Check cache first
    final cachedData = _getCache(cacheKey, ttl: cacheTtl);
    if (cachedData != null) {
      return Restaurant.fromJson(cachedData);
    }
    
    try {
      final response = await _dio.get('${AppConstants.restaurantsEndpoint}/current');
      final restaurant = Restaurant.fromJson(response.data);
      
      // Cache the result
      _setCache(cacheKey, response.data, ttl: cacheTtl);
      
      return restaurant;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // RSVP endpoints
  Future<RSVP> createRSVP(String restaurantId, String day) async {
    try {
      final response = await _dio.post(AppConstants.rsvpEndpoint, data: {
        'restaurantId': restaurantId,
        'dayOfWeek': day,
        'status': 'going',
      });
      
      // Clear related cache
      _clearRSVPCache();
      
      return RSVP.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<RSVP>> getUserRSVPs(String userId) async {
    final cacheKey = 'user_rsvps_$userId';
    const cacheTtl = Duration(minutes: 2);
    
    // Check cache first
    final cachedData = _getCache(cacheKey, ttl: cacheTtl);
    if (cachedData != null) {
      return (cachedData as List).map((json) => RSVP.fromJson(json)).toList();
    }
    
    try {
      final response = await _dio.get('${AppConstants.rsvpEndpoint}/user/$userId');
      final List<dynamic> data = response.data['rsvps'] ?? response.data;
      final rsvps = data.map((json) => RSVP.fromJson(json)).toList();
      
      // Cache the result
      _setCache(cacheKey, data, ttl: cacheTtl);
      
      return rsvps;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> cancelRSVP(String rsvpId) async {
    try {
      await _dio.delete('${AppConstants.rsvpEndpoint}/$rsvpId');
      
      // Clear related cache
      _clearRSVPCache();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, int>> getRSVPCounts(String restaurantId) async {
    try {
      final response = await _dio.get('${AppConstants.rsvpEndpoint}/counts', queryParameters: {
        'restaurantId': restaurantId,
      });
      return Map<String, int>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  void _clearRSVPCache() {
    _cache.removeWhere((key, value) => key.startsWith('user_rsvps_'));
  }

  // Wishlist endpoints
  Future<List<Restaurant>> getWishlist(String userId) async {
    final cacheKey = 'wishlist_$userId';
    const cacheTtl = Duration(minutes: 5);
    
    // Check cache first
    final cachedData = _getCache(cacheKey, ttl: cacheTtl);
    if (cachedData != null) {
      return (cachedData as List).map((json) => Restaurant.fromJson(json)).toList();
    }
    
    try {
      final response = await _dio.get('${AppConstants.wishlistEndpoint}/$userId');
      final List<dynamic> data = response.data['wishlist'] ?? response.data;
      final restaurants = data.map((json) => Restaurant.fromJson(json)).toList();
      
      // Cache the result
      _setCache(cacheKey, data, ttl: cacheTtl);
      
      return restaurants;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addToWishlist(String restaurantId) async {
    try {
      await _dio.post(AppConstants.wishlistEndpoint, data: {
        'restaurantId': restaurantId,
      });
      
      // Clear wishlist cache
      _clearWishlistCache();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeFromWishlist(String restaurantId) async {
    try {
      await _dio.delete('${AppConstants.wishlistEndpoint}/$restaurantId');
      
      // Clear wishlist cache
      _clearWishlistCache();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  void _clearWishlistCache() {
    _cache.removeWhere((key, value) => key.startsWith('wishlist_'));
  }

  // Verified Visits endpoints
  Future<VerifiedVisit> verifyVisit({
    required String restaurantId,
    required String photoPath,
    required int rating,
    String? review,
  }) async {
    try {
      // Upload photo first
      final photoUrl = await _uploadPhoto(photoPath);
      
      final response = await _dio.post(AppConstants.verifiedVisitsEndpoint, data: {
        'restaurantId': restaurantId,
        'photoUrl': photoUrl,
        'rating': rating,
        'review': review,
        'visitDate': DateTime.now().toIso8601String(),
      });
      
      // Clear verified visits cache
      _clearVerifiedVisitsCache();
      
      return VerifiedVisit.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<VerifiedVisit>> getVerifiedVisits(String userId) async {
    final cacheKey = 'verified_visits_$userId';
    const cacheTtl = Duration(minutes: 10);
    
    // Check cache first
    final cachedData = _getCache(cacheKey, ttl: cacheTtl);
    if (cachedData != null) {
      return (cachedData as List).map((json) => VerifiedVisit.fromJson(json)).toList();
    }
    
    try {
      final response = await _dio.get('${AppConstants.verifiedVisitsEndpoint}/$userId');
      final List<dynamic> data = response.data['verifiedVisits'] ?? response.data;
      final visits = data.map((json) => VerifiedVisit.fromJson(json)).toList();
      
      // Cache the result
      _setCache(cacheKey, data, ttl: cacheTtl);
      
      return visits;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  void _clearVerifiedVisitsCache() {
    _cache.removeWhere((key, value) => key.startsWith('verified_visits_'));
  }

  Future<String> _uploadPhoto(String photoPath) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photoPath),
      });

      final response = await _dio.post('/upload/photo', data: formData);
      return response.data['photoUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<RSVP> updateRSVP({
    required String rsvpId,
    required String dayOfWeek,
    required String status,
  }) async {
    try {
      final response = await _dio.put('${AppConstants.rsvpEndpoint}/$rsvpId', data: {
        'dayOfWeek': dayOfWeek,
        'status': status,
      });
      return RSVP.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteRSVP(String rsvpId) async {
    try {
      await _dio.delete('${AppConstants.rsvpEndpoint}/$rsvpId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<RSVP>> getUserRSVPs() async {
    try {
      final response = await _dio.get('${AppConstants.rsvpEndpoint}/user');
      final List<dynamic> data = response.data['rsvps'] ?? response.data;
      return data.map((json) => RSVP.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Verified visits endpoints
  Future<List<VerifiedVisit>> getVerifiedVisits() async {
    try {
      final response = await _dio.get(AppConstants.verifiedVisitsEndpoint);
      final List<dynamic> data = response.data['verifiedVisits'] ?? response.data;
      return data.map((json) => VerifiedVisit.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<VerifiedVisit> createVerifiedVisit({
    required String restaurantId,
    required String photoUrl,
    required int rating,
    String? review,
    required DateTime visitDate,
  }) async {
    try {
      final response = await _dio.post(AppConstants.verifiedVisitsEndpoint, data: {
        'restaurantId': restaurantId,
        'photoUrl': photoUrl,
        'rating': rating,
        'review': review,
        'visitDate': visitDate.toIso8601String(),
      });
      return VerifiedVisit.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteVerifiedVisit(String visitId) async {
    try {
      await _dio.delete('${AppConstants.verifiedVisitsEndpoint}/$visitId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Wishlist endpoints
  Future<List<WishlistItem>> getWishlist() async {
    try {
      final response = await _dio.get(AppConstants.wishlistEndpoint);
      final List<dynamic> data = response.data['wishlist'] ?? response.data;
      return data.map((json) => WishlistItem.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<WishlistItem> addToWishlist(String restaurantId) async {
    try {
      final response = await _dio.post(AppConstants.wishlistEndpoint, data: {
        'restaurantId': restaurantId,
      });
      return WishlistItem.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeFromWishlist(String wishlistId) async {
    try {
      await _dio.delete('${AppConstants.wishlistEndpoint}/$wishlistId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<WishlistItem> updateWishlistItem({
    required String wishlistId,
    bool? isFavorited,
  }) async {
    try {
      final response = await _dio.put('${AppConstants.wishlistEndpoint}/$wishlistId', data: {
        if (isFavorited != null) 'isFavorited': isFavorited,
      });
      return WishlistItem.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Photo upload endpoint
  Future<String> uploadPhoto({
    required String filePath,
    required String userId,
    required String restaurantId,
    Function(int, int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
        'userId': userId,
        'restaurantId': restaurantId,
      });

      final response = await _dio.post(
        '/upload/photo',
        data: formData,
        onSendProgress: onProgress,
      );

      return response.data['photoUrl'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  Exception _handleError(DioException error) {
    String message = 'An error occurred';
    int? statusCode;
    String? errorCode;
    
    if (error.response != null) {
      statusCode = error.response!.statusCode;
      final data = error.response!.data;
      
      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
        errorCode = data['errorCode'] as String?;
      } else {
        switch (statusCode) {
          case 400:
            message = 'Bad request';
            break;
          case 401:
            return AuthException('Unauthorized - Please login again');
          case 403:
            message = 'Forbidden - You do not have permission';
            break;
          case 404:
            message = 'Resource not found';
            break;
          case 422:
            message = 'Validation error';
            break;
          case 429:
            message = 'Too many requests - Please try again later';
            break;
          case 500:
            message = 'Server error - Please try again later';
            break;
          case 502:
          case 503:
          case 504:
            message = 'Service temporarily unavailable';
            break;
          default:
            message = 'Request failed with status $statusCode';
        }
      }
      
      // Return appropriate exception type
      if (statusCode! >= 400 && statusCode < 500) {
        return ServerException(message, statusCode: statusCode, errorCode: errorCode);
      } else if (statusCode >= 500) {
        return ServerException(message, statusCode: statusCode, errorCode: errorCode);
      }
    } else {
      // Handle network errors
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          message = 'Connection timeout - Please check your internet connection';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'Request timeout - Please try again';
          break;
        case DioExceptionType.connectionError:
          message = 'Connection error - Please check your internet connection';
          break;
        case DioExceptionType.sendTimeout:
          message = 'Send timeout - Please try again';
          break;
        case DioExceptionType.badResponse:
          message = 'Invalid response from server';
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled';
          break;
        case DioExceptionType.unknown:
          message = 'Unknown error occurred';
          break;
      }
      return NetworkException(message);
    }

    return ApiException(message, statusCode: statusCode, errorCode: errorCode);
  }
}
