import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/offline_provider.dart';

class OfflineBanner extends StatefulWidget {
  final bool showWhenOnline;
  final bool showSyncProgress;

  const OfflineBanner({
    super.key,
    this.showWhenOnline = false,
    this.showSyncProgress = true,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        final shouldShow = _shouldShowBanner(offlineProvider);
        
        if (shouldShow) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            if (_animationController.value == 0.0 && !shouldShow) {
              return const SizedBox.shrink();
            }

            return Transform.translate(
              offset: Offset(0, 60 * _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildBanner(offlineProvider),
              ),
            );
          },
        );
      },
    );
  }

  bool _shouldShowBanner(OfflineProvider offlineProvider) {
    if (widget.showWhenOnline) return true;
    return offlineProvider.shouldShowOfflineIndicator();
  }

  Widget _buildBanner(OfflineProvider offlineProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: offlineProvider.getConnectionStatusColor(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Status icon
            _buildStatusIcon(offlineProvider),
            
            const SizedBox(width: 12),
            
            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    offlineProvider.getConnectionStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.showSyncProgress && offlineProvider.isSyncing) ...[
                    const SizedBox(height: 4),
                    Text(
                      offlineProvider.getSyncStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Progress indicator
            if (widget.showSyncProgress && offlineProvider.isSyncing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: offlineProvider.syncProgress,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white.withOpacity(0.3),
                ),
              ),
            
            // Action button
            if (!offlineProvider.isOnline && !offlineProvider.isSyncing)
              TextButton(
                onPressed: () => _showOfflineHelp(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Help',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(OfflineProvider offlineProvider) {
    if (offlineProvider.isSyncing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Icon(
      offlineProvider.getConnectionStatusIcon(),
      color: Colors.white,
      size: 16,
    );
  }

  void _showOfflineHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Mode'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You\'re currently offline. Here\'s what you can do:'),
            SizedBox(height: 12),
            Text('✓ View cached restaurants'),
            Text('✓ Browse your profile'),
            Text('✓ View saved visits'),
            SizedBox(height: 12),
            Text('Your changes will be saved and synced when you\'re back online.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Compact offline indicator for app bars
class OfflineIndicator extends StatelessWidget {
  final bool showText;

  const OfflineIndicator({
    super.key,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        if (offlineProvider.isOnline && !offlineProvider.isSyncing) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: offlineProvider.getConnectionStatusColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                offlineProvider.getConnectionStatusIcon(),
                color: Colors.white,
                size: 14,
              ),
              if (showText) ...[
                const SizedBox(width: 6),
                Text(
                  offlineProvider.getConnectionStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Cached data indicator
class CachedDataIndicator extends StatelessWidget {
  final Widget child;
  final bool isCached;
  final DateTime? cachedAt;

  const CachedDataIndicator({
    super.key,
    required this.child,
    required this.isCached,
    this.cachedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isCached)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.offline_bolt,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cached',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Sync progress widget
class SyncProgressWidget extends StatelessWidget {
  final bool showDetails;

  const SyncProgressWidget({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        if (!offlineProvider.isSyncing) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Text(
                      'Syncing data...',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  Text(
                    '${(offlineProvider.syncProgress * 100).round()}%',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              if (showDetails && offlineProvider.currentSyncItem != null) ...[
                const SizedBox(height: 8),
                Text(
                  offlineProvider.currentSyncItem!,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              LinearProgressIndicator(
                value: offlineProvider.syncProgress,
                backgroundColor: Colors.blue.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
        );
      },
    );
  }
}

