import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/offline_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/offline/offline_banner.dart';
import '../../services/navigation_service.dart';

class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStatistics();
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

  Future<void> _loadStatistics() async {
    await context.read<OfflineProvider>().loadCacheStatistics();
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
          'Offline Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Offline banner
          const OfflineBanner(showWhenOnline: true),
          
          // Settings content
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildContent(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          const SizedBox(height: 32),
          
          // Connection status
          _buildConnectionStatus(),
          
          const SizedBox(height: 24),
          
          // Offline settings
          _buildOfflineSettings(),
          
          const SizedBox(height: 24),
          
          // Cache statistics
          _buildCacheStatistics(),
          
          const SizedBox(height: 24),
          
          // Sync controls
          _buildSyncControls(),
          
          const SizedBox(height: 24),
          
          // Cache management
          _buildCacheManagement(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offline & Sync',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage offline functionality and data synchronization',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: offlineProvider.getConnectionStatusColor().withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: offlineProvider.getConnectionStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  offlineProvider.getConnectionStatusIcon(),
                  color: offlineProvider.getConnectionStatusColor(),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offlineProvider.getSyncStatusText(),
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineSettings() {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offline Mode',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Offline mode toggle
              Row(
                children: [
                  Icon(
                    Icons.offline_bolt,
                    color: offlineProvider.offlineModeEnabled 
                        ? Colors.orange 
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enable Offline Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cache data locally and sync when online',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Switch(
                    value: offlineProvider.offlineModeEnabled,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      offlineProvider.setOfflineModeEnabled(value);
                    },
                    activeColor: Colors.orange,
                    activeTrackColor: Colors.orange.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCacheStatistics() {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        final stats = offlineProvider.cacheStatistics;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Cache Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  IconButton(
                    onPressed: _loadStatistics,
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (stats != null) ...[
                _buildStatRow(
                  'Cached Items',
                  stats.cacheItemCount.toString(),
                  Icons.storage,
                ),
                _buildStatRow(
                  'Database Size',
                  stats.formattedDatabaseSize,
                  Icons.data_usage,
                ),
                _buildStatRow(
                  'Pending Sync',
                  stats.pendingSyncItems.toString(),
                  Icons.sync_problem,
                  valueColor: stats.pendingSyncItems > 0 ? Colors.orange : null,
                ),
                if (stats.lastSyncTime != null)
                  _buildStatRow(
                    'Last Sync',
                    _formatLastSync(stats.lastSyncTime!),
                    Icons.sync,
                  ),
              ] else ...[
                const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade400,
            size: 20,
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
              ),
            ),
          ),
          
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncControls() {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sync Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Manual sync button
              CustomButton(
                text: offlineProvider.isSyncing ? 'Syncing...' : 'Sync Now',
                fullWidth: true,
                isLoading: offlineProvider.isSyncing,
                isDisabled: !offlineProvider.isOnline || !offlineProvider.offlineModeEnabled,
                icon: Icons.sync,
                onPressed: () => offlineProvider.syncNow(),
              ),
              
              const SizedBox(height: 12),
              
              // Sync progress
              if (offlineProvider.isSyncing)
                const SyncProgressWidget(showDetails: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCacheManagement() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cache Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Clear cache button
          CustomButton(
            text: 'Clear All Cache',
            fullWidth: true,
            type: ButtonType.outline,
            borderColor: Colors.red.shade400,
            textColor: Colors.red.shade300,
            icon: Icons.delete_outline,
            onPressed: _showClearCacheDialog,
          ),
          
          const SizedBox(height: 12),
          
          // Info text
          Text(
            'Clearing cache will remove all offline data. You\'ll need to re-download data when online.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: const Text(
          'Clear Cache',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all cached data. Are you sure?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      await context.read<OfflineProvider>().clearAllCache();
      
      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Cache cleared successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to clear cache: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

