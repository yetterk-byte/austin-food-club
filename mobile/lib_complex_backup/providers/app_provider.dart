import 'package:flutter/material.dart';
import 'auth_provider.dart';
import 'restaurant_provider.dart';
import 'rsvp_provider.dart';
import 'user_provider.dart';
import 'notification_provider.dart';
import 'offline_provider.dart';

class AppProvider extends ChangeNotifier {
  final AuthProvider _authProvider = AuthProvider();
  final RestaurantProvider _restaurantProvider = RestaurantProvider();
  final RSVPProvider _rsvpProvider = RSVPProvider();
  final UserProvider _userProvider = UserProvider();
  final NotificationProvider _notificationProvider = NotificationProvider();
  final OfflineProvider _offlineProvider = OfflineProvider();

  // Getters for individual providers
  AuthProvider get auth => _authProvider;
  RestaurantProvider get restaurants => _restaurantProvider;
  RSVPProvider get rsvps => _rsvpProvider;
  UserProvider get user => _userProvider;
  NotificationProvider get notifications => _notificationProvider;
  OfflineProvider get offline => _offlineProvider;

  // Global state
  bool _isInitialized = false;
  String? _globalError;

  bool get isInitialized => _isInitialized;
  String? get globalError => _globalError;

  // Initialize all providers
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setGlobalLoading(true);
      _clearGlobalError();

      // Initialize providers in order
      await _authProvider.initialize();
      
      // Initialize notifications and offline regardless of auth status
      await _notificationProvider.initialize();
      await _offlineProvider.initialize();
      
      // Only initialize other providers if user is authenticated
      if (_authProvider.isAuthenticated) {
        await Future.wait([
          _restaurantProvider.initialize(),
          _rsvpProvider.initialize(),
          _userProvider.initialize(),
        ]);
      }

      _isInitialized = true;
    } catch (e) {
      _setGlobalError('Failed to initialize app: $e');
    } finally {
      _setGlobalLoading(false);
    }
  }

  // Refresh all data
  Future<void> refreshAll() async {
    try {
      _setGlobalLoading(true);
      _clearGlobalError();

      if (_authProvider.isAuthenticated) {
        await Future.wait([
          _restaurantProvider.refresh(),
          _rsvpProvider.refresh(),
          _userProvider.refresh(),
        ]);
      }
    } catch (e) {
      _setGlobalError('Failed to refresh data: $e');
    } finally {
      _setGlobalLoading(false);
    }
  }

  // Handle authentication state changes
  void _handleAuthStateChange() {
    if (_authProvider.isAuthenticated) {
      // User signed in, initialize other providers
      _restaurantProvider.initialize();
      _rsvpProvider.initialize();
      _userProvider.initialize();
    } else {
      // User signed out, clear other providers
      _restaurantProvider.dispose();
      _rsvpProvider.dispose();
      _userProvider.dispose();
    }
    notifyListeners();
  }

  // Global error management
  void clearGlobalError() {
    _globalError = null;
    notifyListeners();
  }

  void _setGlobalError(String error) {
    _globalError = error;
    notifyListeners();
  }

  void _setGlobalLoading(bool loading) {
    // This could be used for global loading states
    notifyListeners();
  }

  // Check if any provider is loading
  bool get isAnyLoading {
    return _authProvider.isLoading ||
           _restaurantProvider.isLoading ||
           _rsvpProvider.isLoading ||
           _userProvider.isLoading ||
           _notificationProvider.isLoading ||
           _offlineProvider.isSyncing;
  }

  // Check if any provider has an error
  bool get hasAnyError {
    return _authProvider.error != null ||
           _restaurantProvider.error != null ||
           _rsvpProvider.error != null ||
           _userProvider.error != null ||
           _notificationProvider.error != null ||
           _globalError != null;
  }

  // Get all errors
  List<String> getAllErrors() {
    final errors = <String>[];
    
    if (_authProvider.error != null) errors.add('Auth: ${_authProvider.error}');
    if (_restaurantProvider.error != null) errors.add('Restaurants: ${_restaurantProvider.error}');
    if (_rsvpProvider.error != null) errors.add('RSVPs: ${_rsvpProvider.error}');
    if (_userProvider.error != null) errors.add('User: ${_userProvider.error}');
    if (_notificationProvider.error != null) errors.add('Notifications: ${_notificationProvider.error}');
    if (_globalError != null) errors.add('Global: $_globalError');
    
    return errors;
  }

  // Clear all errors
  void clearAllErrors() {
    _authProvider.clearError();
    _restaurantProvider.clearError();
    _rsvpProvider.clearError();
    _userProvider.clearError();
    // _notificationProvider doesn't have a clearError method exposed
    clearGlobalError();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _restaurantProvider.dispose();
    _rsvpProvider.dispose();
    _userProvider.dispose();
    _notificationProvider.dispose();
    _offlineProvider.dispose();
    super.dispose();
  }
}
