import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:3001/api';
  
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
        Uri.parse('$baseUrl/rsvps'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'restaurantId': restaurantId,
          'day': day,
          'userId': 'demo-user-123', // Using demo user for now
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

  static Future<List<Map<String, dynamic>>> getRSVPCounts(String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rsvps/restaurant/$restaurantId/counts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to get RSVP counts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting RSVP counts: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getVerifiedVisits(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verified-visits/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
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
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to get friends: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting friends: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSocialFeed(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/social-feed/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to get social feed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting social feed: $e');
      return [];
    }
  }
}