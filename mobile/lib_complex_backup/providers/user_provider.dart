import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/verified_visit.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  List<VerifiedVisit> _verifiedVisits = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  List<VerifiedVisit> get verifiedVisits => _verifiedVisits;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize user provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      await _fetchUserProfile();
      await _fetchVerifiedVisits();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch user profile
  Future<void> fetchUserProfile() async {
    try {
      _setLoading(true);
      _clearError();
      
      final user = await _apiService.getUserProfile();
      _currentUser = user;
    } catch (e) {
      _setError('Failed to fetch user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch verified visits
  Future<void> fetchVerifiedVisits() async {
    try {
      _setLoading(true);
      _clearError();
      
      final visits = await _apiService.getVerifiedVisits();
      _verifiedVisits = visits;
    } catch (e) {
      _setError('Failed to fetch verified visits: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Submit verification
  Future<void> submitVerification({
    required String restaurantId,
    required String photoUrl,
    required int rating,
    String? review,
    required DateTime visitDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final verification = await _apiService.submitVerification(
        restaurantId: restaurantId,
        photoUrl: photoUrl,
        rating: rating,
        review: review,
        visitDate: visitDate,
      );
      
      // Add to local list
      _verifiedVisits.insert(0, verification);
      
      // Update user stats
      _updateUserStats();
    } catch (e) {
      _setError('Failed to submit verification: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete verification
  Future<void> deleteVerification(String visitId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _apiService.deleteVerification(visitId);
      
      // Remove from local list
      _verifiedVisits.removeWhere((visit) => visit.id == visitId);
      
      // Update user stats
      _updateUserStats();
    } catch (e) {
      _setError('Failed to delete verification: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get verified visits by restaurant
  List<VerifiedVisit> getVerifiedVisitsByRestaurant(String restaurantId) {
    return _verifiedVisits.where((visit) => visit.restaurantId == restaurantId).toList();
  }

  // Get verified visits by rating
  List<VerifiedVisit> getVerifiedVisitsByRating(int rating) {
    return _verifiedVisits.where((visit) => visit.rating == rating).toList();
  }

  // Get recent verified visits (last 30 days)
  List<VerifiedVisit> getRecentVerifiedVisits() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _verifiedVisits.where((visit) => 
      visit.visitDate.isAfter(thirtyDaysAgo)
    ).toList();
  }

  // Get user statistics
  Map<String, dynamic> getUserStats() {
    if (_currentUser == null) return {};

    return {
      'totalVisits': _verifiedVisits.length,
      'averageRating': _calculateAverageRating(),
      'favoriteCuisine': _getFavoriteCuisine(),
      'thisMonthVisits': _getThisMonthVisits(),
      'totalRestaurants': _getUniqueRestaurants().length,
    };
  }

  // Calculate average rating
  double _calculateAverageRating() {
    if (_verifiedVisits.isEmpty) return 0.0;
    
    final totalRating = _verifiedVisits.fold(0, (sum, visit) => sum + visit.rating);
    return totalRating / _verifiedVisits.length;
  }

  // Get favorite cuisine type
  String _getFavoriteCuisine() {
    if (_verifiedVisits.isEmpty) return 'None';
    
    final cuisineCount = <String, int>{};
    for (final visit in _verifiedVisits) {
      // Assuming restaurant has cuisine type
      final cuisine = visit.restaurant?.cuisineType ?? 'Unknown';
      cuisineCount[cuisine] = (cuisineCount[cuisine] ?? 0) + 1;
    }
    
    if (cuisineCount.isEmpty) return 'None';
    
    return cuisineCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get visits this month
  int _getThisMonthVisits() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    
    return _verifiedVisits.where((visit) {
      final visitMonth = DateTime(visit.visitDate.year, visit.visitDate.month);
      return visitMonth.isAtSameMomentAs(thisMonth);
    }).length;
  }

  // Get unique restaurants visited
  List<String> _getUniqueRestaurants() {
    return _verifiedVisits.map((visit) => visit.restaurantId).toSet().toList();
  }

  // Update user stats
  void _updateUserStats() {
    if (_currentUser == null) return;
    
    final stats = getUserStats();
    _currentUser = _currentUser!.copyWith(
      totalVisits: stats['totalVisits'] as int,
      averageRating: stats['averageRating'] as double,
    );
  }

  // Refresh all data
  Future<void> refresh() async {
    try {
      _setLoading(true);
      _clearError();
      
      await Future.wait([
        _fetchUserProfile(),
        _fetchVerifiedVisits(),
      ]);
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  Future<void> _fetchUserProfile() async {
    try {
      final user = await _apiService.getUserProfile();
      _currentUser = user;
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchVerifiedVisits() async {
    try {
      final visits = await _apiService.getVerifiedVisits();
      _verifiedVisits = visits;
    } catch (e) {
      print('Error fetching verified visits: $e');
    }
  }

  // Error Management
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}