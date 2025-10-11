import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';
import '../models/restaurant.dart';

class WishlistService {
  static const String baseUrl = 'https://api.austinfoodclub.com/api';

  static Future<List<Restaurant>> getMyFavorites({int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/wishlist');
      final token = await AuthStorage.getToken();
      final bearer = (token != null && token.isNotEmpty) ? token : 'mock-token-consistent';
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $bearer',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = (data['wishlist'] ?? data['data'] ?? []) as List<dynamic>;
        final List<Restaurant> favorites = [];
        for (final item in items) {
          final rest = (item['restaurant'] ?? item) as Map<String, dynamic>;
          favorites.add(Restaurant.fromJson(rest));
        }
        return favorites;
      } else {
        print('❌ WishlistService: HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ WishlistService: Error fetching favorites: $e');
      return [];
    }
  }
}

