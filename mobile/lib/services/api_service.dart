import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/rsvp.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3001/api';
  static const String apiBaseUrl = 'http://localhost:3001/api/v1';
  static const String mockToken = 'mock-token-consistent';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $mockToken',
  };

  /// Get featured restaurant
  static Future<Restaurant> getFeaturedRestaurant() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/restaurants/featured'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Restaurant.fromJson(data['data']);
      } else {
        throw Exception('Failed to load featured restaurant');
      }
    } catch (e) {
      print('Error fetching featured restaurant: $e');
      rethrow;
    }
  }

  /// Get all restaurants
  static Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/restaurants'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final restaurantsJson = data['data']['restaurants'] as List;
        return restaurantsJson.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load restaurants');
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  /// Get RSVP counts
  static Future<Map<String, int>> getRSVPCounts(String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rsvp/counts?restaurantId=$restaurantId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, int>.from(data['data'] ?? {});
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching RSVP counts: $e');
      return {};
    }
  }

  /// Create RSVP
  static Future<bool> createRSVP(String restaurantId, String day) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/users/rsvps'), // Correct endpoint
        headers: headers,
        body: jsonEncode({
          'restaurantId': restaurantId,
          'day': day,
          'status': 'going',
        }),
      );
      
      print('RSVP Response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating RSVP: $e');
      return false;
    }
  }

  /// Submit verified visit
  static Future<bool> submitVerifiedVisit({
    required String restaurantId,
    required String photo,
    required double rating,
    DateTime? visitDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verified-visits'),
        headers: headers,
        body: jsonEncode({
          'restaurantId': restaurantId,
          'photo': photo,
          'rating': rating,
          'visitDate': (visitDate ?? DateTime.now()).toIso8601String(),
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error submitting verified visit: $e');
      return false;
    }
  }

  /// Get verified visits
  static Future<List<Map<String, dynamic>>> getVerifiedVisits() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verified-visits'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching verified visits: $e');
      return [];
    }
  }

  /// Test API connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error testing API connection: $e');
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic details;

  ApiException({
    required this.message,
    required this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}