// Push Notification Implementation Examples
// This file demonstrates how to use the notification system

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../providers/notification_provider.dart';
import '../widgets/notifications/notification_permission_dialog.dart';
import '../widgets/notifications/notification_badge.dart';

class NotificationExamples {
  // Basic notification service usage
  static Future<void> basicNotificationExamples() async {
    final notificationService = NotificationService();
    
    // Initialize the service
    await notificationService.initialize();
    
    // Get FCM token
    final token = notificationService.fcmToken;
    print('FCM Token: $token');
    
    // Schedule a local notification
    await notificationService.scheduleNotification(
      id: 1,
      title: 'Test Notification',
      body: 'This is a test notification',
      scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
      type: 'test',
      data: {
        'type': 'test',
        'message': 'Test notification data',
      },
    );
    
    // Cancel a notification
    await notificationService.cancelNotification(1);
    
    // Cancel all notifications
    await notificationService.cancelAllNotifications();
  }

  // Notification preferences examples
  static Future<void> preferencesExamples() async {
    final notificationService = NotificationService();
    
    // Get current preferences
    final preferences = await notificationService.getNotificationPreferences();
    print('Current preferences: ${preferences.toMap()}');
    
    // Update preferences
    final updatedPreferences = preferences.copyWith(
      newRestaurant: false,
      rsvpReminders: true,
    );
    
    await notificationService.saveNotificationPreferences(updatedPreferences);
  }

  // Restaurant-specific notification examples
  static Future<void> restaurantNotificationExamples() async {
    // Schedule RSVP reminder
    await NotificationService.scheduleRSVPReminder(
      restaurantName: 'Franklin Barbecue',
      visitDate: DateTime.now().add(const Duration(days: 1)),
      restaurantId: 'restaurant_123',
    );
    
    // Schedule verify visit reminder
    await NotificationService.scheduleVerifyVisitReminder(
      restaurantName: 'Franklin Barbecue',
      visitDate: DateTime.now().subtract(const Duration(days: 1)),
      rsvpId: 'rsvp_123',
    );
  }

  // Provider usage examples
  static Future<void> providerExamples(NotificationProvider provider) async {
    // Initialize provider
    await provider.initialize();
    
    // Update specific preference
    await provider.updatePreference(newRestaurant: false);
    
    // Schedule notifications through provider
    await provider.scheduleRSVPReminder(
      restaurantName: 'Franklin Barbecue',
      visitDate: DateTime.now().add(const Duration(hours: 2)),
      restaurantId: 'restaurant_123',
    );
    
    // Send test notification
    await provider.sendTestNotification();
    
    // Check if notification is enabled
    final isEnabled = provider.isNotificationEnabled('rsvp_reminder');
    print('RSVP reminders enabled: $isEnabled');
    
    // Get notification summary
    final summary = provider.getNotificationSummary();
    print('Notification summary: $summary');
  }
}

// Example widget showing notification integration
class NotificationExampleWidget extends StatefulWidget {
  const NotificationExampleWidget({super.key});

  @override
  State<NotificationExampleWidget> createState() => _NotificationExampleWidgetState();
}

class _NotificationExampleWidgetState extends State<NotificationExampleWidget> {
  int _notificationCount = 3;
  bool _permissionGranted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Examples'),
        actions: [
          // Notification badge example
          NotificationBadge(
            count: _notificationCount,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _notificationCount = 0;
                });
              },
              icon: const Icon(Icons.notifications),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Permission section
          _buildSection(
            'Permission Management',
            [
              ElevatedButton(
                onPressed: _showPermissionDialog,
                child: const Text('Show Permission Dialog'),
              ),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Request Permissions'),
              ),
            ],
          ),
          
          // Badge examples
          _buildSection(
            'Notification Badges',
            [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  NotificationBadgeVariants.red(
                    count: 5,
                    child: const Icon(Icons.mail, size: 32),
                  ),
                  NotificationBadgeVariants.orange(
                    count: 12,
                    child: const Icon(Icons.restaurant, size: 32),
                  ),
                  NotificationBadgeVariants.green(
                    count: 99,
                    child: const Icon(Icons.verified, size: 32),
                  ),
                  NotificationBadgeVariants.small(
                    count: 3,
                    child: const Icon(Icons.person, size: 24),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _notificationCount = (_notificationCount + 1) % 10;
                  });
                },
                child: const Text('Increment Badge Count'),
              ),
            ],
          ),
          
          // Notification scheduling
          _buildSection(
            'Schedule Notifications',
            [
              ElevatedButton(
                onPressed: _scheduleTestNotification,
                child: const Text('Schedule Test Notification (5s)'),
              ),
              ElevatedButton(
                onPressed: _scheduleRSVPReminder,
                child: const Text('Schedule RSVP Reminder'),
              ),
              ElevatedButton(
                onPressed: _scheduleVerifyReminder,
                child: const Text('Schedule Verify Reminder'),
              ),
            ],
          ),
          
          // Notification management
          _buildSection(
            'Notification Management',
            [
              ElevatedButton(
                onPressed: _openPreferences,
                child: const Text('Open Preferences'),
              ),
              ElevatedButton(
                onPressed: _cancelAllNotifications,
                child: const Text('Cancel All Notifications'),
              ),
              ElevatedButton(
                onPressed: _getNotificationInfo,
                child: const Text('Get Notification Info'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: child,
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _showPermissionDialog() async {
    await NotificationPermissionDialog.show(
      context,
      onPermissionGranted: () {
        setState(() {
          _permissionGranted = true;
        });
        _showSnackBar('Notifications enabled!', Colors.green);
      },
      onPermissionDenied: () {
        setState(() {
          _permissionGranted = false;
        });
        _showSnackBar('Notifications disabled', Colors.orange);
      },
    );
  }

  Future<void> _requestPermissions() async {
    try {
      await NotificationService().initialize();
      _showSnackBar('Permissions requested', Colors.blue);
    } catch (e) {
      _showSnackBar('Failed to request permissions: $e', Colors.red);
    }
  }

  Future<void> _scheduleTestNotification() async {
    try {
      final notificationService = NotificationService();
      await notificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Test Notification',
        body: 'This is a test notification scheduled for 5 seconds!',
        scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
        type: 'test',
        data: {
          'type': 'test',
          'message': 'Test notification from examples',
        },
      );
      _showSnackBar('Test notification scheduled for 5 seconds', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to schedule notification: $e', Colors.red);
    }
  }

  Future<void> _scheduleRSVPReminder() async {
    try {
      await NotificationService.scheduleRSVPReminder(
        restaurantName: 'Franklin Barbecue',
        visitDate: DateTime.now().add(const Duration(seconds: 10)),
        restaurantId: 'restaurant_demo',
      );
      _showSnackBar('RSVP reminder scheduled for 10 seconds', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to schedule RSVP reminder: $e', Colors.red);
    }
  }

  Future<void> _scheduleVerifyReminder() async {
    try {
      await NotificationService.scheduleVerifyVisitReminder(
        restaurantName: 'Franklin Barbecue',
        visitDate: DateTime.now().subtract(const Duration(days: 1)),
        rsvpId: 'rsvp_demo',
      );
      _showSnackBar('Verify reminder scheduled for 15 seconds', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to schedule verify reminder: $e', Colors.red);
    }
  }

  Future<void> _openPreferences() async {
    // This would navigate to the notification preferences screen
    _showSnackBar('Opening notification preferences...', Colors.blue);
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await NotificationService().cancelAllNotifications();
      _showSnackBar('All notifications cancelled', Colors.orange);
    } catch (e) {
      _showSnackBar('Failed to cancel notifications: $e', Colors.red);
    }
  }

  Future<void> _getNotificationInfo() async {
    try {
      final notificationService = NotificationService();
      final preferences = await notificationService.getNotificationPreferences();
      final token = notificationService.fcmToken;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FCM Token: ${token?.substring(0, 20)}...'),
              const SizedBox(height: 8),
              Text('New Restaurant: ${preferences.newRestaurant}'),
              Text('RSVP Reminders: ${preferences.rsvpReminders}'),
              Text('Friend RSVPs: ${preferences.friendRsvps}'),
              Text('Verify Reminders: ${preferences.verifyVisitReminders}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Failed to get notification info: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

