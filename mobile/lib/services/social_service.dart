import '../models/friend.dart';
import '../models/user.dart';
import '../models/restaurant.dart';
import 'mock_data_service.dart';

class SocialService {
  // Mock friends data
  static final List<Friend> _mockFriends = [
    Friend(
      id: 'friend_1',
      userId: '1',
      friendId: '3',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      friendUser: User(
        id: '3',
        email: 'sarah@example.com',
        name: 'Sarah Johnson',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        isVerified: true,
      ),
    ),
    Friend(
      id: 'friend_2',
      userId: '1',
      friendId: '4',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      friendUser: User(
        id: '4',
        email: 'mike@example.com',
        name: 'Mike Chen',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        isVerified: true,
      ),
    ),
    Friend(
      id: 'friend_3',
      userId: '1',
      friendId: '5',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      friendUser: User(
        id: '5',
        email: 'alex@example.com',
        name: 'Alex Rivera',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        isVerified: true,
      ),
    ),
  ];

  /// Get user's friends
  static Future<List<Friend>> getFriends(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockFriends.where((friend) => friend.userId == userId).toList();
  }

  /// Get social feed
  static Future<List<SocialFeedItem>> getSocialFeed(String userId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    
    final restaurants = MockDataService.getAllRestaurantsMock();
    
    return [
      SocialFeedItem(
        id: 'feed_1',
        userId: '3',
        type: 'verified_visit',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        user: User(id: '3', email: 'sarah@example.com', name: 'Sarah Johnson', createdAt: DateTime.now()),
        restaurant: restaurants[0],
        rating: 5.0,
        photoUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
      ),
      SocialFeedItem(
        id: 'feed_2',
        userId: '4',
        type: 'verified_visit',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        user: User(id: '4', email: 'mike@example.com', name: 'Mike Chen', createdAt: DateTime.now()),
        restaurant: restaurants[1],
        rating: 4.5,
        photoUrl: 'https://images.unsplash.com/photo-1558030006-450675393462?w=400&h=300&fit=crop',
      ),
    ];
  }

  /// Search users
  static Future<List<User>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    return [
      User(id: '7', email: 'jessica@example.com', name: 'Jessica Wilson', createdAt: DateTime.now()),
      User(id: '8', email: 'david@example.com', name: 'David Thompson', createdAt: DateTime.now()),
    ].where((user) => user.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  /// Add friend
  static Future<bool> addFriend(String userId, String friendId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    _mockFriends.add(Friend(
      id: 'friend_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      friendId: friendId,
      createdAt: DateTime.now(),
      friendUser: User(id: friendId, email: 'new@example.com', name: 'New Friend', createdAt: DateTime.now()),
    ));
    
    return true;
  }

  /// Remove friend
  static Future<bool> removeFriend(String userId, String friendId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    _mockFriends.removeWhere((f) => 
        (f.userId == userId && f.friendId == friendId) ||
        (f.userId == friendId && f.friendId == userId));
    
    return true;
  }
}