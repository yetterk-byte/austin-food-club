// Offline Functionality Implementation Examples
// This file demonstrates how to use the offline system

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_provider.dart';
import '../services/offline_service.dart';
import '../services/offline_api_service.dart';
import '../services/database_service.dart';
import '../widgets/offline/offline_banner.dart';

class OfflineExamples {
  // Basic offline service usage
  static Future<void> basicOfflineExamples() async {
    final offlineService = OfflineService();
    
    // Initialize the service
    await offlineService.initialize();
    
    // Check connectivity
    final isOnline = offlineService.isOnline;
    print('Is online: $isOnline');
    
    // Cache data
    await offlineService.cacheData('key', {'data': 'value'});
    
    // Get cached data
    final cachedData = await offlineService.getCachedData<Map<String, dynamic>>('key');
    print('Cached data: $cachedData');
    
    // Check cache validity
    final isValid = await offlineService.isCacheValid('key');
    print('Cache valid: $isValid');
    
    // Sync pending changes
    await offlineService.syncPendingChanges();
    
    // Get cache statistics
    final stats = await offlineService.getCacheStatistics();
    print('Cache items: ${stats.cacheItemCount}');
    print('Database size: ${stats.formattedDatabaseSize}');
    print('Pending sync: ${stats.pendingSyncItems}');
  }

  // Database service examples
  static Future<void> databaseExamples() async {
    final databaseService = DatabaseService();
    
    // Insert restaurant
    // await databaseService.insertRestaurant(restaurant);
    
    // Get restaurants
    final restaurants = await databaseService.getRestaurants();
    print('Local restaurants: ${restaurants.length}');
    
    // Get current restaurant
    final currentRestaurant = await databaseService.getCurrentRestaurant();
    print('Current restaurant: ${currentRestaurant?.name}');
    
    // Get sync queue
    final syncQueue = await databaseService.getSyncQueue();
    print('Pending sync items: ${syncQueue.length}');
    
    // Add to sync queue
    await databaseService.addToSyncQueue(
      tableName: 'restaurants',
      recordId: 'restaurant_123',
      operation: 'create',
      data: {'name': 'Test Restaurant'},
    );
  }

  // Offline API service examples
  static Future<void> offlineApiExamples() async {
    final apiService = OfflineApiService();
    apiService.initialize();
    
    // Get current restaurant (offline-first)
    final currentRestaurant = await apiService.getCurrentRestaurant();
    print('Current restaurant: ${currentRestaurant?.name}');
    
    // Get all restaurants (offline-first)
    final allRestaurants = await apiService.getAllRestaurants();
    print('All restaurants: ${allRestaurants.length}');
    
    // Create RSVP (works offline)
    final rsvp = await apiService.createRSVP(
      restaurantId: 'restaurant_123',
      day: 'monday',
      userId: 'user_123',
    );
    print('RSVP created: ${rsvp?.id}');
    
    // Check if data is available offline
    final hasOfflineData = await apiService.isDataAvailableOffline(
      'current_restaurant',
    );
    print('Has offline data: $hasOfflineData');
    
    // Preload essential data
    await apiService.preloadEssentialData('user_123');
  }

  // Provider usage examples
  static Future<void> providerExamples(OfflineProvider provider) async {
    // Initialize provider
    await provider.initialize();
    
    // Check connection status
    final isOnline = provider.isOnline;
    final isSyncing = provider.isSyncing;
    print('Online: $isOnline, Syncing: $isSyncing');
    
    // Cache data
    await provider.cacheData('test_key', {'test': 'data'});
    
    // Get cached data
    final cachedData = await provider.getCachedData<Map<String, dynamic>>('test_key');
    print('Cached data: $cachedData');
    
    // Manage settings
    await provider.setOfflineModeEnabled(true);
    final offlineModeEnabled = provider.offlineModeEnabled;
    print('Offline mode enabled: $offlineModeEnabled');
    
    // Trigger manual sync
    await provider.syncNow();
    
    // Get status information
    final statusText = provider.getConnectionStatusText();
    final statusColor = provider.getConnectionStatusColor();
    final statusIcon = provider.getConnectionStatusIcon();
    print('Status: $statusText');
    
    // Cache specific data types
    await provider.cacheRestaurants([]);
    await provider.cacheUserProfile({'id': 'user_123'});
    await provider.cacheRSVPs([]);
    await provider.cacheVerifiedVisits([]);
  }
}

// Example widget showing offline functionality integration
class OfflineExampleWidget extends StatefulWidget {
  const OfflineExampleWidget({super.key});

  @override
  State<OfflineExampleWidget> createState() => _OfflineExampleWidgetState();
}

class _OfflineExampleWidgetState extends State<OfflineExampleWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Examples'),
        actions: [
          // Offline indicator in app bar
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: OfflineIndicator(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          const OfflineBanner(),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Connection status section
                _buildSection(
                  'Connection Status',
                  [
                    Consumer<OfflineProvider>(
                      builder: (context, offlineProvider, child) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      offlineProvider.getConnectionStatusIcon(),
                                      color: offlineProvider.getConnectionStatusColor(),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      offlineProvider.getConnectionStatusText(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(offlineProvider.getSyncStatusText()),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Cache management section
                _buildSection(
                  'Cache Management',
                  [
                    ElevatedButton(
                      onPressed: _cacheTestData,
                      child: const Text('Cache Test Data'),
                    ),
                    ElevatedButton(
                      onPressed: _getCachedData,
                      child: const Text('Get Cached Data'),
                    ),
                    ElevatedButton(
                      onPressed: _clearCache,
                      child: const Text('Clear Cache'),
                    ),
                  ],
                ),
                
                // Sync management section
                _buildSection(
                  'Sync Management',
                  [
                    Consumer<OfflineProvider>(
                      builder: (context, offlineProvider, child) {
                        return ElevatedButton(
                          onPressed: offlineProvider.isOnline && !offlineProvider.isSyncing
                              ? () => offlineProvider.syncNow()
                              : null,
                          child: Text(
                            offlineProvider.isSyncing ? 'Syncing...' : 'Sync Now',
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: _showSyncQueue,
                      child: const Text('Show Sync Queue'),
                    ),
                  ],
                ),
                
                // Settings section
                _buildSection(
                  'Settings',
                  [
                    Consumer<OfflineProvider>(
                      builder: (context, offlineProvider, child) {
                        return SwitchListTile(
                          title: const Text('Offline Mode'),
                          subtitle: const Text('Enable offline functionality'),
                          value: offlineProvider.offlineModeEnabled,
                          onChanged: (value) {
                            offlineProvider.setOfflineModeEnabled(value);
                          },
                          activeColor: Colors.orange,
                        );
                      },
                    ),
                  ],
                ),
                
                // Statistics section
                _buildSection(
                  'Cache Statistics',
                  [
                    Consumer<OfflineProvider>(
                      builder: (context, offlineProvider, child) {
                        final stats = offlineProvider.cacheStatistics;
                        
                        if (stats == null) {
                          return const CircularProgressIndicator();
                        }
                        
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cache Items: ${stats.cacheItemCount}'),
                                Text('Database Size: ${stats.formattedDatabaseSize}'),
                                Text('Pending Sync: ${stats.pendingSyncItems}'),
                                if (stats.lastSyncTime != null)
                                  Text('Last Sync: ${stats.lastSyncTime}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
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

  Future<void> _cacheTestData() async {
    final provider = context.read<OfflineProvider>();
    await provider.cacheData('test_data', {
      'message': 'Hello from cache!',
      'timestamp': DateTime.now().toIso8601String(),
    });
    _showSnackBar('Test data cached');
  }

  Future<void> _getCachedData() async {
    final provider = context.read<OfflineProvider>();
    final data = await provider.getCachedData<Map<String, dynamic>>('test_data');
    
    if (data != null) {
      _showSnackBar('Cached data: ${data['message']}');
    } else {
      _showSnackBar('No cached data found');
    }
  }

  Future<void> _clearCache() async {
    final provider = context.read<OfflineProvider>();
    await provider.clearAllCache();
    _showSnackBar('Cache cleared');
  }

  Future<void> _showSyncQueue() async {
    final databaseService = DatabaseService();
    final syncQueue = await databaseService.getSyncQueue();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Queue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${syncQueue.length} items pending sync'),
            const SizedBox(height: 8),
            ...syncQueue.take(5).map((item) => Text(
              '${item['operation']} ${item['table_name']}',
              style: const TextStyle(fontSize: 12),
            )),
            if (syncQueue.length > 5)
              Text('... and ${syncQueue.length - 5} more'),
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
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// Example of offline-aware screen
class OfflineAwareScreenExample extends StatefulWidget {
  const OfflineAwareScreenExample({super.key});

  @override
  State<OfflineAwareScreenExample> createState() => _OfflineAwareScreenExampleState();
}

class _OfflineAwareScreenExampleState extends State<OfflineAwareScreenExample> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = false;
  bool _isDataCached = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline-Aware Screen'),
        actions: [
          const OfflineIndicator(),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          const OfflineBanner(),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _restaurants[index];
          return CachedDataIndicator(
            isCached: _isDataCached,
            child: ListTile(
              title: Text(restaurant['name']),
              subtitle: Text(restaurant['area']),
              trailing: _isDataCached
                  ? const Icon(Icons.offline_bolt, color: Colors.orange)
                  : const Icon(Icons.wifi, color: Colors.green),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offlineProvider = context.read<OfflineProvider>();
      
      // Try to get fresh data if online
      if (offlineProvider.isOnline) {
        // Simulate API call
        await Future.delayed(const Duration(seconds: 1));
        _restaurants = [
          {'name': 'Franklin Barbecue', 'area': 'East Austin'},
          {'name': 'La Barbecue', 'area': 'East Austin'},
        ];
        
        // Cache the data
        await offlineProvider.cacheRestaurants(_restaurants);
        _isDataCached = false;
      } else {
        // Get cached data
        final cachedRestaurants = await offlineProvider.getCachedRestaurants();
        _restaurants = List<Map<String, dynamic>>.from(cachedRestaurants ?? []);
        _isDataCached = true;
      }
    } catch (e) {
      // Fallback to cached data
      final offlineProvider = context.read<OfflineProvider>();
      final cachedRestaurants = await offlineProvider.getCachedRestaurants();
      _restaurants = List<Map<String, dynamic>>.from(cachedRestaurants ?? []);
      _isDataCached = true;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadRestaurants();
  }
}

// Complete offline example app
class OfflineExampleApp extends StatelessWidget {
  const OfflineExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Examples',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
      ),
      home: ChangeNotifierProvider(
        create: (_) => OfflineProvider(),
        child: const OfflineExampleWidget(),
      ),
    );
  }
}

// Integration patterns for existing screens
class OfflineIntegrationPatterns {
  // Pattern 1: Simple offline-first data loading
  static Future<List<T>> loadDataOfflineFirst<T>({
    required BuildContext context,
    required String cacheKey,
    required Future<List<T>> Function() apiCall,
    required Future<List<T>> Function() cacheCall,
  }) async {
    final offlineProvider = context.read<OfflineProvider>();
    
    try {
      if (offlineProvider.isOnline) {
        // Try API first
        final apiData = await apiCall();
        await offlineProvider.cacheData(cacheKey, apiData);
        return apiData;
      }
    } catch (e) {
      debugPrint('API call failed, falling back to cache: $e');
    }
    
    // Fallback to cache
    return await cacheCall();
  }

  // Pattern 2: Offline-aware write operations
  static Future<bool> saveDataOfflineAware({
    required BuildContext context,
    required String type,
    required String id,
    required Map<String, dynamic> data,
    required Future<bool> Function() apiCall,
  }) async {
    final offlineProvider = context.read<OfflineProvider>();
    
    if (offlineProvider.isOnline) {
      try {
        // Try API first
        final success = await apiCall();
        if (success) return true;
      } catch (e) {
        debugPrint('API call failed, saving offline: $e');
      }
    }
    
    // Save offline
    await offlineProvider.saveDataOffline(
      type: type,
      id: id,
      data: data,
    );
    
    return true; // Always return true for offline saves
  }

  // Pattern 3: Conditional feature availability
  static Widget buildOfflineAwareFeature({
    required BuildContext context,
    required Widget onlineWidget,
    required Widget offlineWidget,
    String? offlineMessage,
  }) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, child) {
        if (offlineProvider.isOnline) {
          return onlineWidget;
        } else {
          return Column(
            children: [
              if (offlineMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          offlineMessage,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              offlineWidget,
            ],
          );
        }
      },
    );
  }
}

