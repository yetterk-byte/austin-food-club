import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/restaurant.dart';

class RestaurantService {
  static const String baseUrl = 'http://localhost:3001/api';
  
  static Future<Restaurant?> getFeaturedRestaurant({String? citySlug}) async {
    try {
      final service = RestaurantService();
      // Default to Austin if no city specified (backward compatibility)
      final effectiveCitySlug = citySlug ?? 'austin';
      return await service.getCurrentRestaurant(citySlug: effectiveCitySlug);
    } catch (e) {
      print('❌ RestaurantService: Failed to get featured restaurant: $e');
      return null;
    }
  }
  
  Future<Restaurant> getCurrentRestaurant({String? citySlug}) async {
    try {
      // Build URL with city context if provided
      String url = '$baseUrl/restaurants/current';
      if (citySlug != null) {
        url += '?citySlug=$citySlug';
      }
      
      print('🔍 RestaurantService: Attempting to fetch from $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('🔍 RestaurantService: Response status: ${response.statusCode}');
      print('🔍 RestaurantService: Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('✅ RestaurantService: Successfully fetched restaurant data');
        print('🔍 RestaurantService: Response body length: ${response.body.length}');
        
        final data = json.decode(response.body);
        print('🔍 RestaurantService: Restaurant name: ${data['name']}');
        print('🔍 RestaurantService: Restaurant address: ${data['address']}');
        print('🔍 RestaurantService: Categories: ${data['categories']}');
        
        try {
          final restaurant = Restaurant.fromJson(data);
          print('✅ RestaurantService: Restaurant parsing successful');
          return restaurant;
        } catch (parseError) {
          print('❌ RestaurantService: Parsing error: $parseError');
          throw Exception('Failed to parse restaurant data: $parseError');
        }
      } else if (response.statusCode == 404) {
        throw Exception('No featured restaurant this week');
      } else {
        print('❌ RestaurantService: HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Failed to load restaurant');
      }
    } catch (e) {
      print('❌ RestaurantService: Exception: $e');
      throw Exception('Error fetching restaurant: $e');
    }
  }
  
  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/search?name=$query'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search restaurants');
      }
    } catch (e) {
      throw Exception('Error searching restaurants: $e');
    }
  }
}
