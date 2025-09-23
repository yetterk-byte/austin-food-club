import '../models/friend.dart';
import 'api_service.dart';

class SocialService {
  static Future<List<Friend>> getFriends(String userId) async {
    try {
      final data = await ApiService.getFriends(userId);
      return data.map((json) => Friend.fromJson(json)).toList();
    } catch (e) {
      print('❌ SocialService: Error getting friends: $e');
      // Return empty list on error
      return [];
    }
  }

  static Future<List<SocialFeedItem>> getSocialFeed(String userId) async {
    try {
      final data = await ApiService.getSocialFeed(userId);
      return data.map((json) => SocialFeedItem.fromJson(json)).toList();
    } catch (e) {
      print('❌ SocialService: Error getting social feed: $e');
      // Return empty list on error
      return [];
    }
  }

  static Future<List<SocialFeedItem>> getCityActivity(String userId) async {
    try {
      final data = await ApiService.getCityActivity(userId);
      return data.map((json) => SocialFeedItem.fromJson(json)).toList();
    } catch (e) {
      print('❌ SocialService: Error getting city activity: $e');
      // Return empty list on error
      return [];
    }
  }

  static Future<bool> addFriend(String userId, String friendId) async {
    try {
      // This would need to be implemented in the backend
      print('✅ SocialService: Adding friend $friendId for user $userId');
      return true;
    } catch (e) {
      print('❌ SocialService: Error adding friend: $e');
      return false;
    }
  }

  static Future<bool> removeFriend(String userId, String friendId) async {
    try {
      // This would need to be implemented in the backend
      print('✅ SocialService: Removing friend $friendId for user $userId');
      return true;
    } catch (e) {
      print('❌ SocialService: Error removing friend: $e');
      return false;
    }
  }
}