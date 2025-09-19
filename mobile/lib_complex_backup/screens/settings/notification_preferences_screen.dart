import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/notification_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/navigation_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPreferences();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await NotificationService().getNotificationPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _preferences = NotificationPreferences.defaultPreferences();
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load preferences');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => NavigationService.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.orange,
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 32),
                
                // Notification settings
                _buildNotificationSettings(),
                
                const SizedBox(height: 32),
                
                // Save button
                _buildSaveButton(),
                
                const SizedBox(height: 24),
                
                // Test notification button
                _buildTestButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Preferences',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which notifications you\'d like to receive',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      children: [
        _buildNotificationTile(
          icon: Icons.restaurant,
          title: 'New Restaurant of the Week',
          subtitle: 'Get notified when a new featured restaurant is available',
          value: _preferences!.newRestaurant,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(newRestaurant: value);
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        _buildNotificationTile(
          icon: Icons.event,
          title: 'RSVP Reminders',
          subtitle: 'Reminders about your upcoming restaurant visits',
          value: _preferences!.rsvpReminders,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(rsvpReminders: value);
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        _buildNotificationTile(
          icon: Icons.people,
          title: 'Friend RSVPs',
          subtitle: 'When friends RSVP to the same restaurant as you',
          value: _preferences!.friendRsvps,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(friendRsvps: value);
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        _buildNotificationTile(
          icon: Icons.verified,
          title: 'Visit Verification Reminders',
          subtitle: 'Reminders to verify your restaurant visits',
          value: _preferences!.verifyVisitReminders,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(verifyVisitReminders: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? Colors.orange.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value 
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? Colors.orange : Colors.grey.shade400,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: Colors.orange,
            activeTrackColor: Colors.orange.withOpacity(0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: 'Save Preferences',
      fullWidth: true,
      size: ButtonSize.large,
      isLoading: _isSaving,
      onPressed: _savePreferences,
      gradient: const LinearGradient(
        colors: [Colors.orange, Colors.deepOrange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  Widget _buildTestButton() {
    return CustomButton(
      text: 'Send Test Notification',
      fullWidth: true,
      size: ButtonSize.medium,
      type: ButtonType.outline,
      borderColor: Colors.grey.shade600,
      textColor: Colors.grey.shade300,
      onPressed: _sendTestNotification,
    );
  }

  Future<void> _savePreferences() async {
    if (_isSaving || _preferences == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await NotificationService().saveNotificationPreferences(_preferences!);
      _showSuccessSnackBar('Preferences saved successfully');
      
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          NavigationService.pop();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to save preferences');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final notificationService = NotificationService();
      
      await notificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Test Notification',
        body: 'This is a test notification from Austin Food Club!',
        scheduledDate: DateTime.now().add(const Duration(seconds: 2)),
        type: 'test',
        data: {
          'type': 'test',
          'message': 'Test notification',
        },
      );
      
      _showSuccessSnackBar('Test notification scheduled');
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Failed to send test notification');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

