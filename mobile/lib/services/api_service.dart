import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_storage.dart';

class ApiService {
  static const String baseUrl = 'https://api.austinfoodclub.com/api';
  
  static Future<Map<String, String>> _headers({ bool auth = false, String? contentType }) async {
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    if (auth) {
      final token = await AuthStorage.getToken();
      final bearer = (token != null && token.isNotEmpty) ? token : 'mock-token-consistent';
      headers['Authorization'] = 'Bearer $bearer';
    }
    return headers;
  }
  
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/current'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      print('❌ ApiService: Connection test failed: $e');
      return false;
    }
  }

  static Future<bool> createRSVP(String restaurantId, String day) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rsvp'),
        headers: await _headers(auth: true, contentType: 'application/json'),
        body: json.encode({
          'restaurantId': restaurantId,
          'day': day,
          'status': 'going',
        }),
      );
      
      if (response.statusCode == 201) {
        print('✅ RSVP created successfully for $day');
        return true;
      } else {
        print('❌ Failed to create RSVP: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating RSVP: $e');
      return false;
    }
  }

  static Future<Map<String, int>> getRSVPCounts(String restaurantId) async {
    try {
      final uri = Uri.parse('$baseUrl/rsvp/counts').replace(queryParameters: {
        'restaurantId': restaurantId,
      });
      final response = await http.get(
        uri,
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> counts = (data['data']?['dayCounts'] ?? data['dayCounts'] ?? {}) as Map<String, dynamic>;
        return counts.map((k, v) => MapEntry(k, (v as num).toInt()));
      } else {
        print('❌ Failed to get RSVP counts: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('❌ Error getting RSVP counts: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getVerifiedVisits(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verified-visits/user/$userId'),
        headers: await _headers(auth: true, contentType: 'application/json'),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Handle standardized API response format
        if (responseData['success'] == true && responseData['data'] != null) {
          final Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
          if (data['visits'] != null) {
            final List<dynamic> visits = data['visits'] as List<dynamic>;
            return visits.cast<Map<String, dynamic>>();
          }
        }
        
        // Fallback to old format for backward compatibility
        if (responseData is List) {
          return (responseData as List<dynamic>).cast<Map<String, dynamic>>();
        }
        
        print('❌ Unexpected response format for verified visits');
        return [];
      } else {
        print('❌ Failed to get verified visits: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting verified visits: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    // TODO: Implement friends endpoint on backend
    // For now, return empty list to prevent 422 errors
    print('⚠️ Friends endpoint not implemented, returning empty list');
    return [];
  }

  static Future<List<Map<String, dynamic>>> getSocialFeed(String userId) async {
    // TODO: Implement social feed endpoint on backend
    // For now, return empty list to prevent 422 errors
    print('⚠️ Social feed endpoint not implemented, returning empty list');
    return [];
  }

  static Future<List<Map<String, dynamic>>> getCityActivity(String userId) async {
    // TODO: Implement city activity endpoint on backend
    // For now, return empty list to prevent 422 errors
    print('⚠️ City activity endpoint not implemented, returning empty list');
    return [];
  }
}