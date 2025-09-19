import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  NotificationPreferences? _preferences;
  String? _fcmToken;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  NotificationPreferences? get preferences => _preferences;
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize notification provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      // Initialize notification service
      await _notificationService.initialize();
      
      // Get FCM token
      _fcmToken = _notificationService.fcmToken;
      
      // Load preferences
      await loadPreferences();
      
      _isInitialized = true;
      debugPrint('NotificationProvider initialized successfully');
    } catch (e) {
      _setError('Failed to initialize notifications: $e');
      debugPrint('NotificationProvider initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load notification preferences
  Future<void> loadPreferences() async {
    try {
      _preferences = await _notificationService.getNotificationPreferences();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notification preferences: $e');
      _preferences = NotificationPreferences.defaultPreferences();
      notifyListeners();
    }
  }

  // Save notification preferences
  Future<void> savePreferences(NotificationPreferences preferences) async {
    _setLoading(true);
    _clearError();

    try {
      await _notificationService.saveNotificationPreferences(preferences);
      _preferences = preferences;
      notifyListeners();
    } catch (e) {
      _setError('Failed to save notification preferences: $e');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Update specific preference
  Future<void> updatePreference({
    bool? newRestaurant,
    bool? rsvpReminders,
    bool? friendRsvps,
    bool? verifyVisitReminders,
  }) async {
    if (_preferences == null) return;

    final updatedPreferences = _preferences!.copyWith(
      newRestaurant: newRestaurant,
      rsvpReminders: rsvpReminders,
      friendRsvps: friendRsvps,
      verifyVisitReminders: verifyVisitReminders,
    );

    await savePreferences(updatedPreferences);
  }

  // Schedule RSVP reminder
  Future<void> scheduleRSVPReminder({
    required String restaurantName,
    required DateTime visitDate,
    required String restaurantId,
  }) async {
    if (_preferences?.rsvpReminders == false) return;

    try {
      await NotificationService.scheduleRSVPReminder(
        restaurantName: restaurantName,
        visitDate: visitDate,
        restaurantId: restaurantId,
      );
    } catch (e) {
      debugPrint('Failed to schedule RSVP reminder: $e');
    }
  }

  // Schedule verify visit reminder
  Future<void> scheduleVerifyVisitReminder({
    required String restaurantName,
    required DateTime visitDate,
    required String rsvpId,
  }) async {
    if (_preferences?.verifyVisitReminders == false) return;

    try {
      await NotificationService.scheduleVerifyVisitReminder(
        restaurantName: restaurantName,
        visitDate: visitDate,
        rsvpId: rsvpId,
      );
    } catch (e) {
      debugPrint('Failed to schedule verify visit reminder: $e');
    }
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationService.cancelNotification(id);
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    try {
      await _notificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Test Notification',
        body: 'This is a test notification from Austin Food Club!',
        scheduledDate: DateTime.now().add(const Duration(seconds: 2)),
        type: 'test',
        data: {
          'type': 'test',
          'message': 'Test notification from Austin Food Club',
        },
      );
    } catch (e) {
      _setError('Failed to send test notification: $e');
      throw e;
    }
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // Re-initialize to request permissions
      await _notificationService.initialize();
      return _notificationService.isInitialized;
    } catch (e) {
      _setError('Failed to request permissions: $e');
      return false;
    }
  }

  // Handle notification types for business logic
  Future<void> handleNewRestaurant({
    required String restaurantName,
    required String restaurantId,
  }) async {
    if (_preferences?.newRestaurant == false) return;
    
    // This would typically be called from the server
    // when a new restaurant is featured
    debugPrint('New restaurant notification: $restaurantName');
  }

  Future<void> handleFriendRSVP({
    required String friendName,
    required String restaurantName,
    required String restaurantId,
  }) async {
    if (_preferences?.friendRsvps == false) return;
    
    // This would typically be called when a friend
    // RSVPs to the same restaurant
    debugPrint('Friend RSVP notification: $friendName -> $restaurantName');
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Check if notifications are enabled for a specific type
  bool isNotificationEnabled(String type) {
    if (_preferences == null) return true;

    switch (type) {
      case 'new_restaurant':
        return _preferences!.newRestaurant;
      case 'rsvp_reminder':
        return _preferences!.rsvpReminders;
      case 'friend_rsvp':
        return _preferences!.friendRsvps;
      case 'verify_visit':
        return _preferences!.verifyVisitReminders;
      default:
        return true;
    }
  }

  // Get notification summary for display
  String getNotificationSummary() {
    if (_preferences == null) return 'Loading...';

    final enabledCount = [
      _preferences!.newRestaurant,
      _preferences!.rsvpReminders,
      _preferences!.friendRsvps,
      _preferences!.verifyVisitReminders,
    ].where((enabled) => enabled).length;

    if (enabledCount == 4) return 'All notifications enabled';
    if (enabledCount == 0) return 'All notifications disabled';
    return '$enabledCount of 4 notifications enabled';
  }

  @override
  void dispose() {
    super.dispose();
  }
}

