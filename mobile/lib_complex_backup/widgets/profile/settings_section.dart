import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final VoidCallback onSignOut;
  final VoidCallback onNotificationSettings;
  final VoidCallback onPrivacySettings;
  final VoidCallback onAccountManagement;

  const SettingsSection({
    super.key,
    required this.onSignOut,
    required this.onNotificationSettings,
    required this.onPrivacySettings,
    required this.onAccountManagement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Settings list
          Expanded(
            child: ListView(
              children: [
                // Account Section
                _buildSectionHeader(context, 'Account'),
                _buildSettingsItem(
                  context,
                  icon: Icons.person,
                  title: 'Profile Settings',
                  subtitle: 'Edit your profile information',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Navigate to profile settings
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.security,
                  title: 'Privacy Settings',
                  subtitle: 'Control your privacy and data',
                  onTap: onPrivacySettings,
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.account_circle,
                  title: 'Account Management',
                  subtitle: 'Manage your account settings',
                  onTap: onAccountManagement,
                ),
                
                const SizedBox(height: 24),
                
                // Notifications Section
                _buildSectionHeader(context, 'Notifications'),
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications,
                  title: 'Push Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: onNotificationSettings,
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.email,
                  title: 'Email Notifications',
                  subtitle: 'Control email updates',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Navigate to email settings
                  },
                ),
                
                const SizedBox(height: 24),
                
                // App Section
                _buildSectionHeader(context, 'App'),
                _buildSettingsItem(
                  context,
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: 'Choose your preferred theme',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show theme picker
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Select your language',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show language picker
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.storage,
                  title: 'Storage',
                  subtitle: 'Manage app storage and cache',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show storage management
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Support Section
                _buildSectionHeader(context, 'Support'),
                _buildSettingsItem(
                  context,
                  icon: Icons.help,
                  title: 'Help Center',
                  subtitle: 'Get help and support',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Navigate to help center
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.feedback,
                  title: 'Send Feedback',
                  subtitle: 'Share your thoughts with us',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Open feedback form
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Show about dialog
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Sign Out Section
                _buildSectionHeader(context, 'Account'),
                _buildDangerousItem(
                  context,
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  onTap: onSignOut,
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.orange.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDangerousItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.red.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.red.shade600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

