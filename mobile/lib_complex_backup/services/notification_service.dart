import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/navigation_service.dart';

// Top-level function for background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService._handleBackgroundMessage(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _tokenKey = 'fcm_token';
  static const String _preferencesKey = 'notification_preferences';

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  String? _fcmToken;
  bool _isInitialized = false;

  // Notification channels
  static const AndroidNotificationChannel _restaurantChannel = AndroidNotificationChannel(
    'restaurant_channel',
    'Restaurant Updates',
    description: 'Notifications about new restaurants and updates',
    importance: Importance.high,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _rsvpChannel = AndroidNotificationChannel(
    'rsvp_channel',
    'RSVP Reminders',
    description: 'Reminders about your RSVPs and visits',
    importance: Importance.high,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _socialChannel = AndroidNotificationChannel(
    'social_channel',
    'Social Updates',
    description: 'Notifications about friends and social activities',
    importance: Importance.defaultImportance,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _verificationChannel = AndroidNotificationChannel(
    'verification_channel',
    'Visit Verification',
    description: 'Reminders to verify your restaurant visits',
    importance: Importance.high,
    enableVibration: true,
  );

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;

      // Initialize local notifications
      _localNotifications = FlutterLocalNotificationsPlugin();
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      // Create notification channels
      await _createNotificationChannels();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications!.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    // Request Firebase messaging permission
    final messagingSettings = await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Request local notification permission (Android 13+)
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted && messagingSettings.authorizationStatus == AuthorizationStatus.authorized;
    }

    return messagingSettings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging!.getToken();
      if (_fcmToken != null) {
        await _saveTokenToPrefs(_fcmToken!);
        debugPrint('FCM Token: $_fcmToken');
      }

      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToPrefs(newToken);
        _sendTokenToServer(newToken);
      });
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  // Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    _handleAppLaunchedFromNotification();

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Create notification channels (Android)
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      await _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_restaurantChannel);

      await _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_rsvpChannel);

      await _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_socialChannel);

      await _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_verificationChannel);
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');
    
    final preferences = await getNotificationPreferences();
    if (!_shouldShowNotification(message, preferences)) return;

    await _showLocalNotification(message);
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Handling background message: ${message.messageId}');
    // Background processing can be done here
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.data}');
    await _navigateFromNotification(message.data);
  }

  // Handle app launched from notification
  Future<void> _handleAppLaunchedFromNotification() async {
    final initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      await _navigateFromNotification(initialMessage.data);
    }
  }

  // Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateFromNotification(data);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _getChannelId(message.data['type']),
      _getChannelName(message.data['type']),
      channelDescription: _getChannelDescription(message.data['type']),
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF6B35), // Orange color
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications!.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Navigate from notification
  Future<void> _navigateFromNotification(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'new_restaurant':
        NavigationService.goToCurrent();
        break;
      case 'rsvp_reminder':
        final restaurantId = data['restaurant_id'] as String?;
        if (restaurantId != null) {
          NavigationService.goToRestaurantDetails(restaurantId: restaurantId);
        }
        break;
      case 'friend_rsvp':
        final restaurantId = data['restaurant_id'] as String?;
        if (restaurantId != null) {
          NavigationService.goToRestaurantDetails(restaurantId: restaurantId);
        }
        break;
      case 'verify_visit':
        NavigationService.goToProfile();
        break;
      default:
        NavigationService.goToCurrent();
        break;
    }
  }

  // Schedule local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications!.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  // Cancel scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications!.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications!.cancelAll();
  }

  // Get notification preferences
  Future<NotificationPreferences> getNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsString = prefs.getString(_preferencesKey);
    
    if (prefsString != null) {
      final prefsMap = jsonDecode(prefsString);
      return NotificationPreferences.fromMap(prefsMap);
    }
    
    return NotificationPreferences.defaultPreferences();
  }

  // Save notification preferences
  Future<void> saveNotificationPreferences(NotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKey, jsonEncode(preferences.toMap()));
  }

  // Send token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      // Implement API call to send token to your server
      debugPrint('Sending FCM token to server: $token');
      // await ApiService.sendFCMToken(token);
    } catch (e) {
      debugPrint('Failed to send FCM token to server: $e');
    }
  }

  // Save token to preferences
  Future<void> _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Check if notification should be shown based on preferences
  bool _shouldShowNotification(RemoteMessage message, NotificationPreferences preferences) {
    final type = message.data['type'] as String?;
    
    switch (type) {
      case 'new_restaurant':
        return preferences.newRestaurant;
      case 'rsvp_reminder':
        return preferences.rsvpReminders;
      case 'friend_rsvp':
        return preferences.friendRsvps;
      case 'verify_visit':
        return preferences.verifyVisitReminders;
      default:
        return true;
    }
  }

  // Helper methods for channel information
  String _getChannelId(String? type) {
    switch (type) {
      case 'new_restaurant':
        return _restaurantChannel.id;
      case 'rsvp_reminder':
        return _rsvpChannel.id;
      case 'friend_rsvp':
        return _socialChannel.id;
      case 'verify_visit':
        return _verificationChannel.id;
      default:
        return _restaurantChannel.id;
    }
  }

  String _getChannelName(String? type) {
    switch (type) {
      case 'new_restaurant':
        return _restaurantChannel.name;
      case 'rsvp_reminder':
        return _rsvpChannel.name;
      case 'friend_rsvp':
        return _socialChannel.name;
      case 'verify_visit':
        return _verificationChannel.name;
      default:
        return _restaurantChannel.name;
    }
  }

  String _getChannelDescription(String? type) {
    switch (type) {
      case 'new_restaurant':
        return _restaurantChannel.description ?? '';
      case 'rsvp_reminder':
        return _rsvpChannel.description ?? '';
      case 'friend_rsvp':
        return _socialChannel.description ?? '';
      case 'verify_visit':
        return _verificationChannel.description ?? '';
      default:
        return _restaurantChannel.description ?? '';
    }
  }

  // Notification helper methods
  static Future<void> scheduleRSVPReminder({
    required String restaurantName,
    required DateTime visitDate,
    required String restaurantId,
  }) async {
    final service = NotificationService();
    
    // Schedule reminder 2 hours before visit
    final reminderTime = visitDate.subtract(const Duration(hours: 2));
    
    if (reminderTime.isAfter(DateTime.now())) {
      await service.scheduleNotification(
        id: restaurantId.hashCode,
        title: 'RSVP Reminder',
        body: 'Don\'t forget about your visit to $restaurantName today!',
        scheduledDate: reminderTime,
        type: 'rsvp_reminder',
        data: {
          'type': 'rsvp_reminder',
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantName,
        },
      );
    }
  }

  static Future<void> scheduleVerifyVisitReminder({
    required String restaurantName,
    required DateTime visitDate,
    required String rsvpId,
  }) async {
    final service = NotificationService();
    
    // Schedule reminder 1 day after visit
    final reminderTime = visitDate.add(const Duration(days: 1));
    
    if (reminderTime.isAfter(DateTime.now())) {
      await service.scheduleNotification(
        id: rsvpId.hashCode,
        title: 'Verify Your Visit',
        body: 'How was your experience at $restaurantName? Verify your visit now!',
        scheduledDate: reminderTime,
        type: 'verify_visit',
        data: {
          'type': 'verify_visit',
          'rsvp_id': rsvpId,
          'restaurant_name': restaurantName,
        },
      );
    }
  }
}

// Notification preferences model
class NotificationPreferences {
  final bool newRestaurant;
  final bool rsvpReminders;
  final bool friendRsvps;
  final bool verifyVisitReminders;

  const NotificationPreferences({
    required this.newRestaurant,
    required this.rsvpReminders,
    required this.friendRsvps,
    required this.verifyVisitReminders,
  });

  factory NotificationPreferences.defaultPreferences() {
    return const NotificationPreferences(
      newRestaurant: true,
      rsvpReminders: true,
      friendRsvps: true,
      verifyVisitReminders: true,
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      newRestaurant: map['newRestaurant'] ?? true,
      rsvpReminders: map['rsvpReminders'] ?? true,
      friendRsvps: map['friendRsvps'] ?? true,
      verifyVisitReminders: map['verifyVisitReminders'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'newRestaurant': newRestaurant,
      'rsvpReminders': rsvpReminders,
      'friendRsvps': friendRsvps,
      'verifyVisitReminders': verifyVisitReminders,
    };
  }

  NotificationPreferences copyWith({
    bool? newRestaurant,
    bool? rsvpReminders,
    bool? friendRsvps,
    bool? verifyVisitReminders,
  }) {
    return NotificationPreferences(
      newRestaurant: newRestaurant ?? this.newRestaurant,
      rsvpReminders: rsvpReminders ?? this.rsvpReminders,
      friendRsvps: friendRsvps ?? this.friendRsvps,
      verifyVisitReminders: verifyVisitReminders ?? this.verifyVisitReminders,
    );
  }
}

