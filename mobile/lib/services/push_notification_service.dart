import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/city_config.dart';

/// Push Notification Service for Austin Food Club Flutter App
/// Handles Firebase Cloud Messaging and local notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      _isInitialized = true;
      print('✅ Push notification service initialized');
    } catch (error) {
      print('❌ Error initializing push notifications: $error');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('❌ Push notification permission denied');
      return;
    }

    print('✅ Push notification permission granted');

    // Get FCM token
    _fcmToken = await _fcm.getToken();
    if (_fcmToken != null) {
      print('📱 FCM Token obtained');
      await _sendTokenToServer(_fcmToken!);
    }

    // Token refresh listener
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _sendTokenToServer(token);
    });

    // Message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Handle background message tap
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground message received: ${message.messageId}');
    
    // Show local notification when app is in foreground
    _showLocalNotification(
      title: message.notification?.title ?? 'Austin Food Club',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📱 Message opened app: ${message.messageId}');
    _handleNotificationData(message.data);
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'austin_food_club',
      'Austin Food Club',
      channelDescription: 'Austin Food Club notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF20b2aa),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationData(data);
      } catch (error) {
        print('❌ Error parsing notification payload: $error');
      }
    }
  }

  /// Handle notification data and navigation
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'weekly_announcement':
      case 'rsvp_reminder':
        // Navigate to restaurant screen
        if (data['restaurantId'] != null) {
          // TODO: Navigate to restaurant details
          print('🍽️ Navigate to restaurant: ${data['restaurantId']}');
        }
        break;
        
      case 'friend_activity':
        // Navigate to friends screen
        print('👥 Navigate to friends screen');
        break;
        
      case 'visit_reminder':
        // Navigate to verify visit screen
        if (data['restaurantId'] != null) {
          print('📸 Navigate to verify visit: ${data['restaurantId']}');
        }
        break;
        
      default:
        // Navigate to home
        print('🏠 Navigate to home');
    }
  }

  /// Send FCM token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      final headers = CityService.getApiHeaders();
      headers['Authorization'] = 'Bearer ${await _getAuthToken()}';
      
      final deviceInfo = {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'osVersion': Platform.operatingSystemVersion,
        'model': Platform.isIOS ? 'iOS Device' : 'Android Device',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${CityService.getApiBaseUrl()}/api/notifications/subscribe'),
        headers: headers,
        body: jsonEncode({
          'subscription': {'fcmToken': token},
          'platform': Platform.isIOS ? 'ios' : 'android',
          'deviceInfo': deviceInfo,
        }),
      );

      if (response.statusCode == 201) {
        print('✅ FCM token sent to server successfully');
      } else {
        print('❌ Failed to send FCM token: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error sending FCM token to server: $error');
    }
  }

  /// Get user auth token (implement based on your auth system)
  Future<String> _getAuthToken() async {
    // TODO: Implement based on your authentication system
    // For now, return empty string (you'll need to integrate with your auth provider)
    return '';
  }

  /// Subscribe to push notifications
  Future<bool> subscribeToPushNotifications() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_fcmToken == null) {
        _fcmToken = await _fcm.getToken();
        if (_fcmToken != null) {
          await _sendTokenToServer(_fcmToken!);
        }
      }

      return _fcmToken != null;
    } catch (error) {
      print('❌ Error subscribing to push notifications: $error');
      return false;
    }
  }

  /// Unsubscribe from push notifications
  Future<bool> unsubscribeFromPushNotifications() async {
    try {
      await _fcm.deleteToken();
      
      // Notify server
      final headers = CityService.getApiHeaders();
      headers['Authorization'] = 'Bearer ${await _getAuthToken()}';
      
      await http.delete(
        Uri.parse('${CityService.getApiBaseUrl()}/api/notifications/unsubscribe'),
        headers: headers,
      );

      _fcmToken = null;
      print('✅ Unsubscribed from push notifications');
      return true;
    } catch (error) {
      print('❌ Error unsubscribing from push notifications: $error');
      return false;
    }
  }

  /// Check if push notifications are enabled
  Future<bool> isPushEnabled() async {
    try {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized && _fcmToken != null;
    } catch (error) {
      return false;
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      final headers = CityService.getApiHeaders();
      headers['Authorization'] = 'Bearer ${await _getAuthToken()}';
      
      final response = await http.post(
        Uri.parse('${CityService.getApiBaseUrl()}/api/notifications/test'),
        headers: headers,
        body: jsonEncode({'platform': Platform.isIOS ? 'ios' : 'android'}),
      );

      if (response.statusCode == 200) {
        print('✅ Test notification sent');
      } else {
        print('❌ Failed to send test notification: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Error sending test notification: $error');
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final headers = CityService.getApiHeaders();
      headers['Authorization'] = 'Bearer ${await _getAuthToken()}';
      
      final response = await http.get(
        Uri.parse('${CityService.getApiBaseUrl()}/api/notifications/preferences'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['preferences'];
      }
    } catch (error) {
      print('❌ Error getting preferences: $error');
    }
    return null;
  }

  /// Update notification preferences
  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final headers = CityService.getApiHeaders();
      headers['Authorization'] = 'Bearer ${await _getAuthToken()}';
      
      final response = await http.put(
        Uri.parse('${CityService.getApiBaseUrl()}/api/notifications/preferences'),
        headers: headers,
        body: jsonEncode(preferences),
      );

      if (response.statusCode == 200) {
        print('✅ Preferences updated successfully');
        return true;
      }
    } catch (error) {
      print('❌ Error updating preferences: $error');
    }
    return false;
  }

  /// Get FCM token (for debugging)
  String? get fcmToken => _fcmToken;
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}

/// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  
  // Handle background message if needed
  // This runs when the app is in background or terminated
}
