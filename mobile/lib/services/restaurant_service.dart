import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/restaurant.dart';

class RestaurantService {
  static const String baseUrl = 'http://localhost:3001/api';
  
  Future<Restaurant> getCurrentRestaurant() async {
    try {
      print('🔍 RestaurantService: Attempting to fetch from $baseUrl/restaurants/current');
      
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/current'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('🔍 RestaurantService: Response status: ${response.statusCode}');
      print('🔍 RestaurantService: Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('✅ RestaurantService: Successfully fetched restaurant data');
        final data = json.decode(response.body);
        print('🔍 RestaurantService: Restaurant name: ${data['name']}');
        return Restaurant.fromJson(data);
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
