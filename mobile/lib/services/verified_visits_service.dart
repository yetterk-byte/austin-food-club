import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/verified_visit.dart';

class VerifiedVisitsService {
  static const String baseUrl = 'http://localhost:3001/api';

  /// Get verified visits for a user
  static Future<List<VerifiedVisit>> getUserVisits(int userId) async {
    try {
      print('🔍 VerifiedVisitsService: Getting visits for user $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/verified-visits/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('🔍 VerifiedVisitsService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['visits'] != null) {
          final List<dynamic> visitsData = data['visits'];
          final visits = visitsData.map((json) => VerifiedVisit.fromJson(json)).toList();
          
          print('✅ VerifiedVisitsService: Found ${visits.length} visits for user $userId');
          return visits;
        } else {
          print('❌ VerifiedVisitsService: API returned unsuccessful response');
          return [];
        }
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
    required int userId,
    required String restaurantId,
    required String restaurantName,
    required String restaurantAddress,
    required int rating,
    String? imageUrl,
    String citySlug = 'austin',
  }) async {
    try {
      print('🔍 VerifiedVisitsService: Creating visit for user $userId at $restaurantName');
      
      final response = await http.post(
        Uri.parse('$baseUrl/verified-visits'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'restaurantId': restaurantId,
          'restaurantName': restaurantName,
          'restaurantAddress': restaurantAddress,
          'rating': rating,
          'imageUrl': imageUrl,
          'citySlug': citySlug,
        }),
      );
      
      print('🔍 VerifiedVisitsService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['visit'] != null) {
          final visit = VerifiedVisit.fromJson(data['visit']);
          print('✅ VerifiedVisitsService: Created visit ${visit.id} for $restaurantName');
          return visit;
        } else {
          print('❌ VerifiedVisitsService: API returned unsuccessful response');
          return null;
        }
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
