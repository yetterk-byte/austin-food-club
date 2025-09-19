import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/friend.dart';

class SocialService {
  static final SocialService _instance = SocialService._internal();
  factory SocialService() => _instance;
  SocialService._internal();

  final Dio _dio = Dio();
  static const String baseUrl = 'https://api.austinfoodclub.com';

  // Friends Management
  Future<List<Friend>> searchFriends(String query) async {
    try {
      final response = await _dio.get(
        '$baseUrl/friends/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['friends'];
        return data.map((json) => Friend.fromJson(json)).toList();
      }
      throw Exception('Failed to search friends');
    } catch (e) {
      debugPrint('Error searching friends: $e');
      return _mockSearchFriends(query);
    }
  }

  Future<List<Friend>> getFriends() async {
    try {
      final response = await _dio.get('$baseUrl/friends');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['friends'];
        return data.map((json) => Friend.fromJson(json)).toList();
      }
      throw Exception('Failed to get friends');
    } catch (e) {
      debugPrint('Error getting friends: $e');
      return _mockGetFriends();
    }
  }

  Future<bool> sendFriendRequest(String userId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/friends/request',
        data: {'userId': userId},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return true; // Mock success
    }
  }

  Future<List<FriendRequest>> getFriendRequests() async {
    try {
      final response = await _dio.get('$baseUrl/friends/requests');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['requests'];
        return data.map((json) => FriendRequest.fromJson(json)).toList();
      }
      throw Exception('Failed to get friend requests');
    } catch (e) {
      debugPrint('Error getting friend requests: $e');
      return _mockGetFriendRequests();
    }
  }

  Future<bool> respondToFriendRequest(String requestId, bool accept) async {
    try {
      final response = await _dio.put(
        '$baseUrl/friends/request/$requestId',
        data: {'accept': accept},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error responding to friend request: $e');
      return true; // Mock success
    }
  }

  Future<bool> removeFriend(String friendId) async {
    try {
      final response = await _dio.delete('$baseUrl/friends/$friendId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return true; // Mock success
    }
  }

  // Social Feed
  Future<List<SocialFeedItem>> getSocialFeed({int page = 0, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/social/feed',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['items'];
        return data.map((json) => SocialFeedItem.fromJson(json)).toList();
      }
      throw Exception('Failed to get social feed');
    } catch (e) {
      debugPrint('Error getting social feed: $e');
      return _mockGetSocialFeed();
    }
  }

  Future<List<SocialFeedItem>> getTrendingRestaurants() async {
    try {
      final response = await _dio.get('$baseUrl/social/trending');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['items'];
        return data.map((json) => SocialFeedItem.fromJson(json)).toList();
      }
      throw Exception('Failed to get trending restaurants');
    } catch (e) {
      debugPrint('Error getting trending restaurants: $e');
      return _mockGetTrendingRestaurants();
    }
  }

  Future<bool> likeFeedItem(String itemId) async {
    try {
      final response = await _dio.post('$baseUrl/social/like/$itemId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error liking feed item: $e');
      return true; // Mock success
    }
  }

  Future<bool> unlikeFeedItem(String itemId) async {
    try {
      final response = await _dio.delete('$baseUrl/social/like/$itemId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error unliking feed item: $e');
      return true; // Mock success
    }
  }

  // Achievements
  Future<List<Achievement>> getAchievements() async {
    try {
      final response = await _dio.get('$baseUrl/achievements');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['achievements'];
        return data.map((json) => Achievement.fromJson(json)).toList();
      }
      throw Exception('Failed to get achievements');
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return _mockGetAchievements();
    }
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    try {
      final response = await _dio.get('$baseUrl/achievements/unlocked');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['achievements'];
        return data.map((json) => Achievement.fromJson(json)).toList();
      }
      throw Exception('Failed to get unlocked achievements');
    } catch (e) {
      debugPrint('Error getting unlocked achievements: $e');
      return _mockGetUnlockedAchievements();
    }
  }

  Future<UserStats> getUserStats() async {
    try {
      final response = await _dio.get('$baseUrl/user/stats');

      if (response.statusCode == 200) {
        return UserStats.fromJson(response.data['stats']);
      }
      throw Exception('Failed to get user stats');
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return _mockGetUserStats();
    }
  }

  Future<UserStats> getFriendStats(String friendId) async {
    try {
      final response = await _dio.get('$baseUrl/user/$friendId/stats');

      if (response.statusCode == 200) {
        return UserStats.fromJson(response.data['stats']);
      }
      throw Exception('Failed to get friend stats');
    } catch (e) {
      debugPrint('Error getting friend stats: $e');
      return _mockGetUserStats();
    }
  }

  // Sharing
  Future<bool> shareRestaurant({
    required String restaurantName,
    required String restaurantAddress,
    String? imageUrl,
  }) async {
    try {
      final text = 'Check out $restaurantName at $restaurantAddress! 🍽️ #AustinFoodClub';
      
      if (imageUrl != null) {
        // Download image and share with it
        final imageFile = await _downloadImage(imageUrl);
        if (imageFile != null) {
          await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: text,
          );
          return true;
        }
      }
      
      await Share.share(text);
      return true;
    } catch (e) {
      debugPrint('Error sharing restaurant: $e');
      return false;
    }
  }

  Future<bool> shareVerifiedVisit({
    required String restaurantName,
    required double rating,
    required String photoUrl,
    String? reviewText,
  }) async {
    try {
      final starsText = '⭐' * rating.round();
      final text = reviewText != null
          ? 'Just visited $restaurantName! $starsText\n\n"$reviewText"\n\n#AustinFoodClub'
          : 'Just visited $restaurantName! $starsText\n\n#AustinFoodClub';
      
      final imageFile = await _downloadImage(photoUrl);
      if (imageFile != null) {
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: text,
        );
        return true;
      }
      
      await Share.share(text);
      return true;
    } catch (e) {
      debugPrint('Error sharing verified visit: $e');
      return false;
    }
  }

  Future<File?> generateInstagramStory({
    required String restaurantName,
    required String photoUrl,
    required double rating,
    String? reviewText,
  }) async {
    try {
      // This would generate a custom Instagram story format
      // For now, return the original photo
      return await _downloadImage(photoUrl);
    } catch (e) {
      debugPrint('Error generating Instagram story: $e');
      return null;
    }
  }

  // Helper methods
  Future<File?> _downloadImage(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final directory = await getTemporaryDirectory();
      final fileName = 'shared_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(response.data);
      return file;
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }

  // Mock data methods
  List<Friend> _mockSearchFriends(String query) {
    return [
      Friend(
        id: '1',
        name: 'John Doe',
        phoneNumber: '+1234567890',
        profileImageUrl: 'https://picsum.photos/100/100?random=1',
        joinedDate: DateTime.now().subtract(const Duration(days: 30)),
        totalVisits: 15,
        averageRating: 4.2,
        favoriteCuisines: ['BBQ', 'Tacos'],
        currentStreak: 3,
      ),
      Friend(
        id: '2',
        name: 'Jane Smith',
        phoneNumber: '+1987654321',
        profileImageUrl: 'https://picsum.photos/100/100?random=2',
        joinedDate: DateTime.now().subtract(const Duration(days: 60)),
        totalVisits: 22,
        averageRating: 4.5,
        favoriteCuisines: ['Asian', 'Italian'],
        currentStreak: 5,
      ),
    ];
  }

  List<Friend> _mockGetFriends() {
    return [
      Friend(
        id: '1',
        name: 'John Doe',
        phoneNumber: '+1234567890',
        profileImageUrl: 'https://picsum.photos/100/100?random=1',
        joinedDate: DateTime.now().subtract(const Duration(days: 30)),
        totalVisits: 15,
        averageRating: 4.2,
        favoriteCuisines: ['BBQ', 'Tacos'],
        currentStreak: 3,
      ),
      Friend(
        id: '2',
        name: 'Jane Smith',
        phoneNumber: '+1987654321',
        profileImageUrl: 'https://picsum.photos/100/100?random=2',
        joinedDate: DateTime.now().subtract(const Duration(days: 60)),
        totalVisits: 22,
        averageRating: 4.5,
        favoriteCuisines: ['Asian', 'Italian'],
        currentStreak: 5,
      ),
      Friend(
        id: '3',
        name: 'Mike Johnson',
        phoneNumber: '+1555666777',
        profileImageUrl: 'https://picsum.photos/100/100?random=3',
        joinedDate: DateTime.now().subtract(const Duration(days: 90)),
        totalVisits: 8,
        averageRating: 3.8,
        favoriteCuisines: ['American'],
        currentStreak: 1,
      ),
    ];
  }

  List<FriendRequest> _mockGetFriendRequests() {
    return [
      FriendRequest(
        id: '1',
        fromUserId: '4',
        toUserId: 'current_user',
        fromUserName: 'Sarah Wilson',
        fromUserProfileImage: 'https://picsum.photos/100/100?random=4',
        fromUserPhone: '+1444555666',
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  List<SocialFeedItem> _mockGetSocialFeed() {
    return [
      SocialFeedItem(
        id: '1',
        userId: '1',
        userName: 'John Doe',
        userProfileImage: 'https://picsum.photos/100/100?random=1',
        type: SocialFeedItemType.verifiedVisit,
        restaurantId: 'restaurant_1',
        restaurantName: 'Franklin Barbecue',
        restaurantImageUrl: 'https://picsum.photos/400/300?random=10',
        rating: 5.0,
        reviewText: 'Amazing brisket! Worth the wait.',
        visitPhotoUrl: 'https://picsum.photos/400/300?random=11',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 12,
        isLikedByCurrentUser: false,
      ),
      SocialFeedItem(
        id: '2',
        userId: '2',
        userName: 'Jane Smith',
        userProfileImage: 'https://picsum.photos/100/100?random=2',
        type: SocialFeedItemType.achievement,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        likesCount: 8,
        isLikedByCurrentUser: true,
      ),
    ];
  }

  List<SocialFeedItem> _mockGetTrendingRestaurants() {
    return [
      SocialFeedItem(
        id: 'trending_1',
        userId: 'system',
        userName: 'Austin Food Club',
        type: SocialFeedItemType.verifiedVisit,
        restaurantId: 'restaurant_trending_1',
        restaurantName: 'La Barbecue',
        restaurantImageUrl: 'https://picsum.photos/400/300?random=20',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likesCount: 45,
        isLikedByCurrentUser: false,
      ),
    ];
  }

  List<Achievement> _mockGetAchievements() {
    return [
      Achievement(
        id: 'first_visit',
        name: 'First Bite',
        description: 'Verify your first restaurant visit',
        iconUrl: '🍽️',
        type: AchievementType.visits,
        targetValue: 1,
        badgeColor: '#FFD700',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 10)),
        currentProgress: 1,
      ),
      Achievement(
        id: 'five_visits',
        name: 'Food Explorer',
        description: 'Verify 5 restaurant visits',
        iconUrl: '🗺️',
        type: AchievementType.visits,
        targetValue: 5,
        badgeColor: '#FF6B35',
        isUnlocked: false,
        currentProgress: 3,
      ),
      Achievement(
        id: 'all_cuisines',
        name: 'Culinary Master',
        description: 'Try all available cuisines',
        iconUrl: '👨‍🍳',
        type: AchievementType.cuisines,
        targetValue: 8,
        badgeColor: '#8A2BE2',
        isUnlocked: false,
        currentProgress: 4,
      ),
    ];
  }

  List<Achievement> _mockGetUnlockedAchievements() {
    return [
      Achievement(
        id: 'first_visit',
        name: 'First Bite',
        description: 'Verify your first restaurant visit',
        iconUrl: '🍽️',
        type: AchievementType.visits,
        targetValue: 1,
        badgeColor: '#FFD700',
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 10)),
        currentProgress: 1,
      ),
    ];
  }

  UserStats _mockGetUserStats() {
    return UserStats(
      totalVisits: 12,
      averageRating: 4.3,
      currentStreak: 3,
      maxStreak: 7,
      cuisinesTried: ['BBQ', 'Tacos', 'Asian', 'Italian'],
      friendsCount: 8,
      achievementsUnlocked: 3,
      lastVisitDate: DateTime.now().subtract(const Duration(days: 2)),
      favoriteCuisine: 'BBQ',
      favoriteRestaurant: 'Franklin Barbecue',
    );
  }
}

