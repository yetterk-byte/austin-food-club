import 'dart:async';
import 'dart:io';
import 'package:austin_food_club_flutter/services/auth_service.dart';
import 'package:austin_food_club_flutter/services/api_service.dart';
import 'package:austin_food_club_flutter/services/photo_service.dart';
import 'package:austin_food_club_flutter/services/notification_service.dart';
import 'package:austin_food_club_flutter/services/social_service.dart';
import 'package:austin_food_club_flutter/models/restaurant.dart';
import 'package:austin_food_club_flutter/models/rsvp.dart';
import 'package:austin_food_club_flutter/models/verified_visit.dart';
import 'package:austin_food_club_flutter/models/user.dart';
import 'package:austin_food_club_flutter/models/friend.dart';

class MockAuthService implements AuthService {
  bool _isAuthenticated = false;
  User? _currentUser;
  String? _lastError;

  @override
  Future<void> signInWithPhone(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (phoneNumber.isEmpty || !phoneNumber.startsWith('+')) {
      throw Exception('Invalid phone number');
    }
    
    // Simulate successful OTP send
  }

  @override
  Future<User> verifyPhoneOTP(String phone, String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (token != '123456') {
      throw Exception('Invalid OTP code');
    }
    
    _currentUser = User(
      id: 'mock_user_123',
      name: 'Test User',
      phone: phone,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _isAuthenticated = true;
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _isAuthenticated = false;
    _currentUser = null;
  }

  @override
  User? getCurrentUser() => _currentUser;

  @override
  Stream<AuthState> authStateChanges() {
    return Stream.value(_isAuthenticated ? AuthState.authenticated : AuthState.unauthenticated);
  }

  @override
  Future<String?> getAccessToken() async {
    return _isAuthenticated ? 'mock_token_123' : null;
  }

  // Mock implementation methods
  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
  }

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  void setError(String? error) {
    _lastError = error;
  }
}

class MockApiService implements ApiService {
  final List<Restaurant> _restaurants = [];
  final List<RSVP> _rsvps = [];
  final List<VerifiedVisit> _verifiedVisits = [];
  final Map<String, int> _rsvpCounts = {};
  
  bool _shouldFail = false;
  String? _failureMessage;

  @override
  Future<Restaurant?> getCurrentRestaurant() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Mock API failure');
    }
    
    return _restaurants.isNotEmpty ? _restaurants.first : null;
  }

  @override
  Future<List<Restaurant>> getAllRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Mock API failure');
    }
    
    return List.from(_restaurants);
  }

  @override
  Future<RSVP?> createRSVP({
    required String restaurantId,
    required String day,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Mock API failure');
    }
    
    final rsvp = RSVP(
      id: 'mock_rsvp_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'mock_user_123',
      restaurantId: restaurantId,
      day: day,
      status: RSVPStatus.going,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _rsvps.add(rsvp);
    _rsvpCounts[day] = (_rsvpCounts[day] ?? 0) + 1;
    
    return rsvp;
  }

  @override
  Future<bool> cancelRSVP(String rsvpId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Mock API failure');
    }
    
    final rsvpIndex = _rsvps.indexWhere((rsvp) => rsvp.id == rsvpId);
    if (rsvpIndex != -1) {
      final rsvp = _rsvps.removeAt(rsvpIndex);
      _rsvpCounts[rsvp.day] = (_rsvpCounts[rsvp.day] ?? 1) - 1;
      return true;
    }
    
    return false;
  }

  @override
  Future<Map<String, int>> getRSVPCounts(String restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Mock API failure');
    }
    
    return Map.from(_rsvpCounts);
  }

  @override
  Future<VerifiedVisit?> submitVerification({
    required String restaurantId,
    required int rating,
    String? review,
    String? photoUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Mock API failure');
    }
    
    final visit = VerifiedVisit(
      id: 'mock_visit_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'mock_user_123',
      restaurantId: restaurantId,
      visitDate: DateTime.now(),
      rating: rating,
      review: review,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _verifiedVisits.add(visit);
    return visit;
  }

  @override
  Future<List<VerifiedVisit>> getVerifiedVisits(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Mock API failure');
    }
    
    return _verifiedVisits.where((visit) => visit.userId == userId).toList();
  }

  // Mock control methods
  void addMockRestaurant(Restaurant restaurant) {
    _restaurants.add(restaurant);
  }

  void addMockRSVP(RSVP rsvp) {
    _rsvps.add(rsvp);
    _rsvpCounts[rsvp.day] = (_rsvpCounts[rsvp.day] ?? 0) + 1;
  }

  void setMockRSVPCounts(Map<String, int> counts) {
    _rsvpCounts.clear();
    _rsvpCounts.addAll(counts);
  }

  void setShouldFail(bool shouldFail, {String? message}) {
    _shouldFail = shouldFail;
    _failureMessage = message;
  }

  void reset() {
    _restaurants.clear();
    _rsvps.clear();
    _verifiedVisits.clear();
    _rsvpCounts.clear();
    _shouldFail = false;
    _failureMessage = null;
  }
}

// class MockPhotoService implements PhotoService { // Temporarily disabled
  final List<File> _capturedPhotos = [];
  bool _shouldFail = false;
  String? _failureMessage;

  @override
  Future<File?> takePicture() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Camera not available');
    }
    
    // Create mock photo file
    final mockFile = File('mock_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    _capturedPhotos.add(mockFile);
    return mockFile;
  }

  @override
  Future<File?> pickFromGallery() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Gallery not available');
    }
    
    // Create mock photo file
    final mockFile = File('gallery_photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    _capturedPhotos.add(mockFile);
    return mockFile;
  }

  @override
  Future<File> compressImage(File image, {int quality = 70}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (_shouldFail) {
      throw Exception(_failureMessage ?? 'Compression failed');
    }
    
    // Return mock compressed file
    return File('compressed_${image.path}');
  }

  @override
  Future<bool> validateImage(File image) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Mock validation logic
    return image.path.contains('.jpg') || 
           image.path.contains('.png') || 
           image.path.contains('.jpeg');
  }

  @override
  Stream<double> uploadProgress() {
    return Stream.periodic(const Duration(milliseconds: 100), (count) {
      return (count * 0.1).clamp(0.0, 1.0);
    }).take(11);
  }

  // Mock control methods
  void setShouldFail(bool shouldFail, {String? message}) {
    _shouldFail = shouldFail;
    _failureMessage = message;
  }

  List<File> getCapturedPhotos() => List.from(_capturedPhotos);

  void reset() {
    _capturedPhotos.clear();
    _shouldFail = false;
    _failureMessage = null;
  }
}

class MockSocialService implements SocialService {
  final List<Friend> _friends = [];
  final List<FriendRequest> _friendRequests = [];
  final List<SocialFeedItem> _socialFeed = [];
  final List<Achievement> _achievements = [];
  
  bool _shouldFail = false;

  @override
  Future<List<Friend>> searchFriends(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_shouldFail) {
      throw Exception('Search failed');
    }
    
    return _friends.where((friend) => 
        friend.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Future<List<Friend>> getFriends() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (_shouldFail) {
      throw Exception('Failed to get friends');
    }
    
    return List.from(_friends);
  }

  @override
  Future<bool> sendFriendRequest(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_shouldFail) {
      return false;
    }
    
    final request = FriendRequest(
      id: 'request_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: 'mock_user_123',
      toUserId: userId,
      fromUserName: 'Test User',
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );
    
    _friendRequests.add(request);
    return true;
  }

  @override
  Future<List<SocialFeedItem>> getSocialFeed({int page = 0, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (_shouldFail) {
      throw Exception('Failed to get social feed');
    }
    
    return List.from(_socialFeed);
  }

  // Mock control methods
  void addMockFriend(Friend friend) {
    _friends.add(friend);
  }

  void addMockFeedItem(SocialFeedItem item) {
    _socialFeed.add(item);
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  void reset() {
    _friends.clear();
    _friendRequests.clear();
    _socialFeed.clear();
    _achievements.clear();
    _shouldFail = false;
  }
}

// Mock provider extensions for testing
extension MockAuthProvider on AuthProvider {
  void setAuthenticated(bool authenticated) {
    // This would set the internal state for testing
  }

  void setCurrentUser(User? user) {
    // This would set the current user for testing
  }

  void setLoading(bool loading) {
    // This would set the loading state for testing
  }

  void setError(String? error) {
    // This would set the error state for testing
  }
}

extension MockRestaurantProvider on RestaurantProvider {
  void setCurrentRestaurant(Restaurant? restaurant) {
    // This would set the current restaurant for testing
  }

  void setAllRestaurants(List<Restaurant> restaurants) {
    // This would set the restaurants list for testing
  }

  void setLoading(bool loading) {
    // This would set the loading state for testing
  }

  void setError(String? error) {
    // This would set the error state for testing
  }
}

extension MockRSVPProvider on RSVPProvider {
  void setUserRSVPs(List<RSVP> rsvps) {
    // This would set the user RSVPs for testing
  }

  void setRSVPCounts(Map<String, int> counts) {
    // This would set the RSVP counts for testing
  }

  void setLoading(bool loading) {
    // This would set the loading state for testing
  }

  void setError(String? error) {
    // This would set the error state for testing
  }

  void setSuccess(bool success) {
    // This would set the success state for testing
  }
}

extension MockOfflineProvider on OfflineProvider {
  void setOffline() {
    // This would set offline state for testing
  }

  void setOnline() {
    // This would set online state for testing
  }

  void setSyncing(bool syncing) {
    // This would set syncing state for testing
  }

  void setSyncProgress(double progress) {
    // This would set sync progress for testing
  }
}

