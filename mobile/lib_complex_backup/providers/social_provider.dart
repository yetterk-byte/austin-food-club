import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../services/social_service.dart';

class SocialProvider extends ChangeNotifier {
  final SocialService _socialService = SocialService();

  // Friends
  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<Friend> _searchResults = [];
  
  // Social Feed
  List<SocialFeedItem> _socialFeed = [];
  List<SocialFeedItem> _trendingRestaurants = [];
  
  // Achievements
  List<Achievement> _achievements = [];
  List<Achievement> _unlockedAchievements = [];
  
  // User Stats
  UserStats? _userStats;
  Map<String, UserStats> _friendStats = {};

  // State
  bool _isLoading = false;
  bool _isFriendsLoading = false;
  bool _isFeedLoading = false;
  bool _isAchievementsLoading = false;
  String? _error;

  // Getters
  List<Friend> get friends => _friends;
  List<FriendRequest> get friendRequests => _friendRequests;
  List<Friend> get searchResults => _searchResults;
  List<SocialFeedItem> get socialFeed => _socialFeed;
  List<SocialFeedItem> get trendingRestaurants => _trendingRestaurants;
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _unlockedAchievements;
  UserStats? get userStats => _userStats;
  
  bool get isLoading => _isLoading;
  bool get isFriendsLoading => _isFriendsLoading;
  bool get isFeedLoading => _isFeedLoading;
  bool get isAchievementsLoading => _isAchievementsLoading;
  String? get error => _error;

  // Computed getters
  int get pendingRequestsCount => _friendRequests
      .where((request) => request.status == FriendRequestStatus.pending)
      .length;

  List<Achievement> get recentAchievements => _unlockedAchievements
      .where((achievement) => achievement.unlockedAt != null &&
          achievement.unlockedAt!.isAfter(
              DateTime.now().subtract(const Duration(days: 7))))
      .toList()
    ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

  double get achievementProgress {
    if (_achievements.isEmpty) return 0.0;
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    return unlockedCount / _achievements.length;
  }

  // Initialize
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadFriends(),
        loadSocialFeed(),
        loadAchievements(),
        loadUserStats(),
      ]);
    } catch (e) {
      _setError('Failed to initialize social features: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Friends Management
  Future<void> loadFriends() async {
    _setFriendsLoading(true);
    
    try {
      final friends = await _socialService.getFriends();
      final requests = await _socialService.getFriendRequests();
      
      _friends = friends;
      _friendRequests = requests;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load friends: $e');
    } finally {
      _setFriendsLoading(false);
    }
  }

  Future<void> searchFriends(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      final results = await _socialService.searchFriends(query);
      _searchResults = results;
      notifyListeners();
    } catch (e) {
      _setError('Failed to search friends: $e');
    }
  }

  Future<bool> sendFriendRequest(String userId) async {
    try {
      final success = await _socialService.sendFriendRequest(userId);
      if (success) {
        // Remove from search results
        _searchResults.removeWhere((friend) => friend.id == userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to send friend request: $e');
      return false;
    }
  }

  Future<bool> respondToFriendRequest(String requestId, bool accept) async {
    try {
      final success = await _socialService.respondToFriendRequest(requestId, accept);
      
      if (success) {
        final request = _friendRequests.firstWhere((r) => r.id == requestId);
        
        if (accept) {
          // Add to friends list
          final newFriend = Friend(
            id: request.fromUserId,
            name: request.fromUserName,
            phoneNumber: request.fromUserPhone,
            profileImageUrl: request.fromUserProfileImage,
            joinedDate: DateTime.now(),
          );
          _friends.add(newFriend);
        }
        
        // Remove from requests
        _friendRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError('Failed to respond to friend request: $e');
      return false;
    }
  }

  Future<bool> removeFriend(String friendId) async {
    try {
      final success = await _socialService.removeFriend(friendId);
      
      if (success) {
        _friends.removeWhere((friend) => friend.id == friendId);
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError('Failed to remove friend: $e');
      return false;
    }
  }

  // Social Feed
  Future<void> loadSocialFeed({bool refresh = false}) async {
    if (!refresh && _socialFeed.isNotEmpty) return;
    
    _setFeedLoading(true);
    
    try {
      final feed = await _socialService.getSocialFeed();
      final trending = await _socialService.getTrendingRestaurants();
      
      _socialFeed = feed;
      _trendingRestaurants = trending;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load social feed: $e');
    } finally {
      _setFeedLoading(false);
    }
  }

  Future<void> likeFeedItem(String itemId) async {
    try {
      final success = await _socialService.likeFeedItem(itemId);
      
      if (success) {
        // Update local state
        final index = _socialFeed.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          _socialFeed[index] = _socialFeed[index].copyWith(
            isLikedByCurrentUser: true,
            likesCount: _socialFeed[index].likesCount + 1,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Failed to like feed item: $e');
    }
  }

  Future<void> unlikeFeedItem(String itemId) async {
    try {
      final success = await _socialService.unlikeFeedItem(itemId);
      
      if (success) {
        // Update local state
        final index = _socialFeed.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          _socialFeed[index] = _socialFeed[index].copyWith(
            isLikedByCurrentUser: false,
            likesCount: (_socialFeed[index].likesCount - 1).clamp(0, double.infinity).toInt(),
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Failed to unlike feed item: $e');
    }
  }

  // Achievements
  Future<void> loadAchievements() async {
    _setAchievementsLoading(true);
    
    try {
      final achievements = await _socialService.getAchievements();
      final unlocked = await _socialService.getUnlockedAchievements();
      
      _achievements = achievements;
      _unlockedAchievements = unlocked;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load achievements: $e');
    } finally {
      _setAchievementsLoading(false);
    }
  }

  Achievement? getAchievementById(String id) {
    try {
      return _achievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Achievement> getAchievementsByType(AchievementType type) {
    return _achievements.where((achievement) => achievement.type == type).toList();
  }

  // User Stats
  Future<void> loadUserStats() async {
    try {
      final stats = await _socialService.getUserStats();
      _userStats = stats;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user stats: $e');
    }
  }

  Future<UserStats?> getFriendStats(String friendId) async {
    if (_friendStats.containsKey(friendId)) {
      return _friendStats[friendId];
    }

    try {
      final stats = await _socialService.getFriendStats(friendId);
      _friendStats[friendId] = stats;
      notifyListeners();
      return stats;
    } catch (e) {
      _setError('Failed to load friend stats: $e');
      return null;
    }
  }

  // Sharing
  Future<bool> shareRestaurant({
    required String restaurantName,
    required String restaurantAddress,
    String? imageUrl,
  }) async {
    try {
      return await _socialService.shareRestaurant(
        restaurantName: restaurantName,
        restaurantAddress: restaurantAddress,
        imageUrl: imageUrl,
      );
    } catch (e) {
      _setError('Failed to share restaurant: $e');
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
      return await _socialService.shareVerifiedVisit(
        restaurantName: restaurantName,
        rating: rating,
        photoUrl: photoUrl,
        reviewText: reviewText,
      );
    } catch (e) {
      _setError('Failed to share verified visit: $e');
      return false;
    }
  }

  // Helper methods
  Friend? getFriendById(String friendId) {
    try {
      return _friends.firstWhere((friend) => friend.id == friendId);
    } catch (e) {
      return null;
    }
  }

  bool isFriend(String userId) {
    return _friends.any((friend) => friend.id == userId);
  }

  bool hasPendingRequest(String userId) {
    return _friendRequests.any((request) => 
        request.fromUserId == userId && 
        request.status == FriendRequestStatus.pending);
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // State management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setFriendsLoading(bool loading) {
    _isFriendsLoading = loading;
    notifyListeners();
  }

  void _setFeedLoading(bool loading) {
    _isFeedLoading = loading;
    notifyListeners();
  }

  void _setAchievementsLoading(bool loading) {
    _isAchievementsLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    debugPrint('SocialProvider Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Refresh methods
  Future<void> refresh() async {
    await Future.wait([
      loadFriends(),
      loadSocialFeed(refresh: true),
      loadAchievements(),
      loadUserStats(),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }
}

