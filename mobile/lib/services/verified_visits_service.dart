import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/verified_visit.dart';

class VerifiedVisitsService {
  static const String baseUrl = 'https://api.austinfoodclub.com/api';

  static final RegExp _cuidPattern = RegExp(r'^c[a-z0-9]{24,}$');

  /// Ensure we have a database restaurantId. If only Yelp data is present, sync it first.
  static Future<String?> ensureRestaurantId(Restaurant restaurant) async {
    // If it already looks like a Prisma cuid, use it as-is
    if (restaurant.id.isNotEmpty && _cuidPattern.hasMatch(restaurant.id)) {
      return restaurant.id;
    }
    // Try to sync using Yelp ID
    if ((restaurant.yelpId).isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/restaurants/sync'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer mock-token-consistent',
          },
          body: json.encode({ 'yelpId': restaurant.yelpId }),
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final synced = (data['restaurant'] ?? data['data']) as Map<String, dynamic>?;
          final dbId = synced != null ? (synced['id'] ?? '').toString() : '';
          if (dbId.isNotEmpty) return dbId;
        } else {
          print('❌ ensureRestaurantId: sync failed ${res.statusCode} ${res.body}');
        }
      } catch (e) {
        print('❌ ensureRestaurantId error: $e');
      }
    }
    return null;
  }

  /// Get current user's verified visits (uses mock auth token in dev)
  static Future<List<VerifiedVisit>> getMyVisits({int limit = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/verified-visits').replace(queryParameters: {
        'limit': limit.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer mock-token-consistent',
        },
      );
      
      print('🔍 VerifiedVisitsService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Standardized paginated format
        final List<dynamic> items = (responseData['data'] ?? responseData['visits'] ?? []) as List<dynamic>;
        final visits = <VerifiedVisit>[];
        for (var i = 0; i < items.length; i++) {
          final item = items[i] as Map<String, dynamic>;
          final restaurant = (item['restaurant'] ?? {}) as Map<String, dynamic>;
          visits.add(
            VerifiedVisit(
              id: i + 1,
              userId: 0,
              restaurantId: (restaurant['id'] ?? item['restaurantId'] ?? '').toString(),
              restaurantName: (restaurant['name'] ?? '').toString(),
              restaurantAddress: (restaurant['address'] ?? '').toString(),
              rating: (item['rating'] ?? 0) is int ? item['rating'] : int.tryParse('${item['rating']}') ?? 0,
              imageUrl: (item['photoUrl'] ?? item['imageUrl'])?.toString(),
              verifiedAt: DateTime.tryParse(item['visitDate']?.toString() ?? '') ?? DateTime.now(),
              citySlug: (restaurant['city'] ?? 'austin').toString(),
            ),
          );
        }
        print('✅ VerifiedVisitsService: Found ${visits.length} visits');
        return visits;
      } else {
        print('❌ VerifiedVisitsService: HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ VerifiedVisitsService: Error getting user visits: $e');
      return [];
    }
  }

  /// Create a new verified visit
  static Future<VerifiedVisit?> createVerifiedVisit({
    required String restaurantId,
    required String restaurantName,
    required String restaurantAddress,
    required int rating,
    required String photoUrl,
    String citySlug = 'austin',
  }) async {
    try {
      print('🔍 VerifiedVisitsService: Creating visit for $restaurantName');
      
      final response = await http.post(
        Uri.parse('$baseUrl/verified-visits'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer mock-token-consistent',
        },
        body: json.encode({
          'restaurantId': restaurantId,
          'rating': rating,
          'photoUrl': photoUrl,
          'review': null,
          'visitDate': DateTime.now().toIso8601String(),
        }),
      );
      
      print('🔍 VerifiedVisitsService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final item = (data['data'] ?? data['visit'] ?? {}) as Map<String, dynamic>;
        final restaurant = (item['restaurant'] ?? {}) as Map<String, dynamic>;
        final visit = VerifiedVisit(
          id: 1,
          userId: 0,
          restaurantId: (restaurant['id'] ?? restaurantId).toString(),
          restaurantName: (restaurant['name'] ?? restaurantName).toString(),
          restaurantAddress: (restaurant['address'] ?? restaurantAddress).toString(),
          rating: (item['rating'] ?? rating) is int ? (item['rating'] ?? rating) : int.tryParse('${item['rating']}') ?? rating,
          imageUrl: (item['photoUrl'] ?? photoUrl).toString(),
          verifiedAt: DateTime.tryParse(item['visitDate']?.toString() ?? '') ?? DateTime.now(),
          citySlug: (restaurant['city'] ?? citySlug).toString(),
        );
        print('✅ VerifiedVisitsService: Created visit for $restaurantName');
        return visit;
      } else {
        print('❌ VerifiedVisitsService: HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ VerifiedVisitsService: Error creating verified visit: $e');
      return null;
    }
  }
}
