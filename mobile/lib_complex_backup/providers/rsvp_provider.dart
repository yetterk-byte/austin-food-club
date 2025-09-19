import 'package:flutter/material.dart';
import '../models/rsvp.dart';
import '../services/api_service.dart';

class RSVPProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<RSVP> _userRSVPs = [];
  Map<String, int> _rsvpCounts = {};
  String? _selectedDay;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<RSVP> get userRSVPs => _userRSVPs;
  Map<String, int> get rsvpCounts => _rsvpCounts;
  String? get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize RSVP provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      await _fetchUserRSVPs();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize RSVPs: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create RSVP
  Future<void> createRSVP(String restaurantId, String day) async {
    try {
      _setLoading(true);
      _clearError();
      
      final rsvp = await _apiService.createRSVP(restaurantId, day);
      
      // Add to local list
      _userRSVPs.add(rsvp);
      
      // Update counts
      await _fetchRSVPCounts(restaurantId);
      
      // Set selected day
      _selectedDay = day;
    } catch (e) {
      _setError('Failed to create RSVP: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cancel RSVP
  Future<void> cancelRSVP(String rsvpId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _apiService.cancelRSVP(rsvpId);
      
      // Remove from local list
      final rsvp = _userRSVPs.firstWhere((r) => r.id == rsvpId);
      _userRSVPs.removeWhere((r) => r.id == rsvpId);
      
      // Update counts for the restaurant
      await _fetchRSVPCounts(rsvp.restaurantId);
      
      // Clear selected day if it was this RSVP
      if (_selectedDay == rsvp.day) {
        _selectedDay = null;
      }
    } catch (e) {
      _setError('Failed to cancel RSVP: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch user's RSVPs
  Future<void> fetchUserRSVPs() async {
    try {
      _setLoading(true);
      _clearError();
      
      final rsvps = await _apiService.getUserRSVPs();
      _userRSVPs = rsvps;
    } catch (e) {
      _setError('Failed to fetch RSVPs: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch RSVP counts for a restaurant
  Future<void> fetchRSVPCounts(String restaurantId) async {
    try {
      _clearError();
      await _fetchRSVPCounts(restaurantId);
    } catch (e) {
      _setError('Failed to fetch RSVP counts: $e');
    }
  }

  // Get RSVP count for a specific day
  int getRSVPCount(String day) {
    return _rsvpCounts[day] ?? 0;
  }

  // Check if user has RSVP for a specific day
  bool hasRSVPForDay(String restaurantId, String day) {
    return _userRSVPs.any((rsvp) => 
      rsvp.restaurantId == restaurantId && 
      rsvp.day == day && 
      rsvp.status == 'going'
    );
  }

  // Get user's RSVP for a specific restaurant and day
  RSVP? getRSVPForDay(String restaurantId, String day) {
    try {
      return _userRSVPs.firstWhere((rsvp) => 
        rsvp.restaurantId == restaurantId && 
        rsvp.day == day
      );
    } catch (e) {
      return null;
    }
  }

  // Get all RSVPs for a specific restaurant
  List<RSVP> getRSVPsForRestaurant(String restaurantId) {
    return _userRSVPs.where((rsvp) => rsvp.restaurantId == restaurantId).toList();
  }

  // Get RSVPs by status
  List<RSVP> getRSVPsByStatus(String status) {
    return _userRSVPs.where((rsvp) => rsvp.status == status).toList();
  }

  // Get upcoming RSVPs (future dates)
  List<RSVP> getUpcomingRSVPs() {
    final now = DateTime.now();
    return _userRSVPs.where((rsvp) {
      // Assuming day is stored as a string like "Monday", "Tuesday", etc.
      // You might need to adjust this based on your actual data structure
      return rsvp.status == 'going';
    }).toList();
  }

  // Get past RSVPs
  List<RSVP> getPastRSVPs() {
    final now = DateTime.now();
    return _userRSVPs.where((rsvp) {
      // Assuming you have a date field or can determine if it's past
      return rsvp.status == 'went' || rsvp.status == 'cancelled';
    }).toList();
  }

  // Set selected day
  void setSelectedDay(String? day) {
    _selectedDay = day;
    notifyListeners();
  }

  // Clear selected day
  void clearSelectedDay() {
    _selectedDay = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _fetchUserRSVPs();
    } catch (e) {
      _setError('Failed to refresh RSVPs: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  Future<void> _fetchUserRSVPs() async {
    try {
      final rsvps = await _apiService.getUserRSVPs();
      _userRSVPs = rsvps;
    } catch (e) {
      print('Error fetching user RSVPs: $e');
    }
  }

  Future<void> _fetchRSVPCounts(String restaurantId) async {
    try {
      final counts = await _apiService.getRSVPCounts(restaurantId);
      _rsvpCounts = counts;
    } catch (e) {
      print('Error fetching RSVP counts: $e');
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