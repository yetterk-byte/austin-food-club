import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/restaurant.dart';

class SearchService {
  static const String baseUrl = 'http://localhost:3001/api';
  
  /// Search restaurants using Yelp API
  static Future<List<Restaurant>> searchRestaurants({
    required String query,
    String location = 'Austin, TX',
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/search').replace(
          queryParameters: {
            'term': query,
            'location': location,
            'limit': limit.toString(),
            'sort_by': 'rating',
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['restaurants'] != null) {
          final List<dynamic> restaurantsData = data['restaurants'];
          return restaurantsData.map((json) => Restaurant.fromJson(json)).toList();
        } else {
          print('❌ SearchService: API returned unsuccessful response');
          return [];
        }
      } else {
        print('❌ SearchService: HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ SearchService: Error searching restaurants: $e');
      return [];
    }
  }
  
  /// Search restaurants with debouncing
  static Future<List<Restaurant>> searchRestaurantsDebounced({
    required String query,
    String location = 'Austin, TX',
    int limit = 10,
    Duration debounceDelay = const Duration(milliseconds: 300),
  }) async {
    // Simple debouncing by waiting
    await Future.delayed(debounceDelay);
    
    return searchRestaurants(
      query: query,
      location: location,
      limit: limit,
    );
  }
}
