// Social Features Implementation Examples
// This file demonstrates how to use the social features

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';
import '../models/friend.dart';
import '../services/social_service.dart';
import '../widgets/social/social_feed_item_widget.dart';
import '../widgets/social/friend_card_widget.dart';
import '../widgets/social/achievement_card_widget.dart';
import '../widgets/notifications/notification_badge.dart';

class SocialExamples {
  // Basic social service usage
  static Future<void> basicSocialServiceExamples() async {
    final socialService = SocialService();
    
    // Search for friends
    final searchResults = await socialService.searchFriends('john');
    print('Search results: ${searchResults.length}');
    
    // Get friends list
    final friends = await socialService.getFriends();
    print('Friends count: ${friends.length}');
    
    // Send friend request
    final success = await socialService.sendFriendRequest('user_123');
    print('Friend request sent: $success');
    
    // Get friend requests
    final requests = await socialService.getFriendRequests();
    print('Pending requests: ${requests.length}');
    
    // Respond to friend request
    await socialService.respondToFriendRequest('request_123', true);
    
    // Get social feed
    final feed = await socialService.getSocialFeed();
    print('Feed items: ${feed.length}');
    
    // Get achievements
    final achievements = await socialService.getAchievements();
    print('Achievements: ${achievements.length}');
    
    // Get user stats
    final stats = await socialService.getUserStats();
    print('User stats: ${stats.totalVisits} visits');
  }

  // Provider usage examples
  static Future<void> providerExamples(SocialProvider provider) async {
    // Initialize social provider
    await provider.initialize();
    
    // Search for friends
    await provider.searchFriends('john doe');
    
    // Send friend request
    await provider.sendFriendRequest('user_123');
    
    // Respond to friend request
    await provider.respondToFriendRequest('request_123', true);
    
    // Like/unlike feed items
    await provider.likeFeedItem('feed_item_123');
    await provider.unlikeFeedItem('feed_item_123');
    
    // Load different data
    await provider.loadFriends();
    await provider.loadSocialFeed(refresh: true);
    await provider.loadAchievements();
    
    // Get specific data
    final friend = provider.getFriendById('friend_123');
    final achievement = provider.getAchievementById('first_visit');
    final isNotificationEnabled = provider.isNotificationEnabled('friend_rsvp');
    
    print('Friend: ${friend?.name}');
    print('Achievement: ${achievement?.name}');
    print('Notifications enabled: $isNotificationEnabled');
  }

  // Sharing examples
  static Future<void> sharingExamples() async {
    final socialService = SocialService();
    
    // Share restaurant
    await socialService.shareRestaurant(
      restaurantName: 'Franklin Barbecue',
      restaurantAddress: '900 E 11th St, Austin, TX',
      imageUrl: 'https://example.com/restaurant.jpg',
    );
    
    // Share verified visit
    await socialService.shareVerifiedVisit(
      restaurantName: 'Franklin Barbecue',
      rating: 5.0,
      photoUrl: 'https://example.com/visit.jpg',
      reviewText: 'Amazing brisket!',
    );
    
    // Generate Instagram story
    final storyFile = await socialService.generateInstagramStory(
      restaurantName: 'Franklin Barbecue',
      photoUrl: 'https://example.com/visit.jpg',
      rating: 5.0,
      reviewText: 'Best BBQ in Austin!',
    );
    
    print('Instagram story generated: ${storyFile?.path}');
  }
}

// Example widget showing social features integration
class SocialFeaturesExampleWidget extends StatefulWidget {
  const SocialFeaturesExampleWidget({super.key});

  @override
  State<SocialFeaturesExampleWidget> createState() => _SocialFeaturesExampleWidgetState();
}

class _SocialFeaturesExampleWidgetState extends State<SocialFeaturesExampleWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Features Examples'),
        actions: [
          // Friend requests badge
          NotificationBadge(
            count: 3,
            child: IconButton(
              onPressed: () => _showFriendRequests(),
              icon: const Icon(Icons.person_add),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Friends section
          _buildSection(
            'Friends Management',
            [
              ElevatedButton(
                onPressed: _loadFriends,
                child: const Text('Load Friends'),
              ),
              ElevatedButton(
                onPressed: _searchFriends,
                child: const Text('Search Friends'),
              ),
              ElevatedButton(
                onPressed: _sendFriendRequest,
                child: const Text('Send Friend Request'),
              ),
            ],
          ),
          
          // Social feed section
          _buildSection(
            'Social Feed',
            [
              ElevatedButton(
                onPressed: _loadSocialFeed,
                child: const Text('Load Social Feed'),
              ),
              ElevatedButton(
                onPressed: _loadTrending,
                child: const Text('Load Trending'),
              ),
              ElevatedButton(
                onPressed: _likeFeedItem,
                child: const Text('Like Feed Item'),
              ),
            ],
          ),
          
          // Achievements section
          _buildSection(
            'Achievements',
            [
              ElevatedButton(
                onPressed: _loadAchievements,
                child: const Text('Load Achievements'),
              ),
              ElevatedButton(
                onPressed: _showAchievementProgress,
                child: const Text('Show Progress'),
              ),
              ElevatedButton(
                onPressed: _unlockAchievement,
                child: const Text('Simulate Unlock'),
              ),
            ],
          ),
          
          // Sharing section
          _buildSection(
            'Sharing',
            [
              ElevatedButton(
                onPressed: _shareRestaurant,
                child: const Text('Share Restaurant'),
              ),
              ElevatedButton(
                onPressed: _shareVisit,
                child: const Text('Share Visit'),
              ),
              ElevatedButton(
                onPressed: _generateStory,
                child: const Text('Generate Story'),
              ),
            ],
          ),
          
          // Mock data section
          _buildSection(
            'Mock Data Examples',
            [
              _buildMockFriendCard(),
              const SizedBox(height: 16),
              _buildMockAchievementCard(),
              const SizedBox(height: 16),
              _buildMockSocialFeedItem(),
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

  Widget _buildMockFriendCard() {
    final mockFriend = Friend(
      id: 'mock_1',
      name: 'John Doe',
      phoneNumber: '+1234567890',
      profileImageUrl: 'https://picsum.photos/100/100?random=1',
      joinedDate: DateTime.now().subtract(const Duration(days: 30)),
      totalVisits: 15,
      averageRating: 4.2,
      favoriteCuisines: ['BBQ', 'Tacos'],
      currentStreak: 3,
    );

    return FriendCardWidget(
      friend: mockFriend,
      onTap: () => _showSnackBar('Friend card tapped'),
      onRemove: () => _showSnackBar('Remove friend'),
    );
  }

  Widget _buildMockAchievementCard() {
    final mockAchievement = Achievement(
      id: 'first_visit',
      name: 'First Bite',
      description: 'Verify your first restaurant visit',
      iconUrl: '🍽️',
      type: AchievementType.visits,
      targetValue: 1,
      badgeColor: '#FFD700',
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
      currentProgress: 1,
    );

    return AchievementCardWidget(
      achievement: mockAchievement,
      onTap: () => _showSnackBar('Achievement card tapped'),
      showUnlockedDate: true,
    );
  }

  Widget _buildMockSocialFeedItem() {
    final mockFeedItem = SocialFeedItem(
      id: 'feed_1',
      userId: 'user_1',
      userName: 'Jane Smith',
      userProfileImage: 'https://picsum.photos/100/100?random=2',
      type: SocialFeedItemType.verifiedVisit,
      restaurantId: 'restaurant_1',
      restaurantName: 'Franklin Barbecue',
      restaurantImageUrl: 'https://picsum.photos/400/300?random=10',
      rating: 5.0,
      reviewText: 'Amazing brisket! Worth the wait.',
      visitPhotoUrl: 'https://picsum.photos/400/300?random=11',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likesCount: 12,
      isLikedByCurrentUser: false,
    );

    return SocialFeedItemWidget(
      item: mockFeedItem,
      onLike: () => _showSnackBar('Liked feed item'),
      onUnlike: () => _showSnackBar('Unliked feed item'),
      onTap: () => _showSnackBar('Feed item tapped'),
      onShare: () => _showSnackBar('Shared feed item'),
    );
  }

  // Action methods
  Future<void> _loadFriends() async {
    final provider = context.read<SocialProvider>();
    await provider.loadFriends();
    _showSnackBar('Friends loaded: ${provider.friends.length}');
  }

  Future<void> _searchFriends() async {
    final provider = context.read<SocialProvider>();
    await provider.searchFriends('john');
    _showSnackBar('Search completed: ${provider.searchResults.length} results');
  }

  Future<void> _sendFriendRequest() async {
    final provider = context.read<SocialProvider>();
    final success = await provider.sendFriendRequest('mock_user_123');
    _showSnackBar('Friend request sent: $success');
  }

  Future<void> _loadSocialFeed() async {
    final provider = context.read<SocialProvider>();
    await provider.loadSocialFeed();
    _showSnackBar('Social feed loaded: ${provider.socialFeed.length} items');
  }

  Future<void> _loadTrending() async {
    final provider = context.read<SocialProvider>();
    await provider.loadSocialFeed();
    _showSnackBar('Trending loaded: ${provider.trendingRestaurants.length} items');
  }

  Future<void> _likeFeedItem() async {
    final provider = context.read<SocialProvider>();
    await provider.likeFeedItem('mock_feed_item_123');
    _showSnackBar('Feed item liked');
  }

  Future<void> _loadAchievements() async {
    final provider = context.read<SocialProvider>();
    await provider.loadAchievements();
    _showSnackBar('Achievements loaded: ${provider.achievements.length}');
  }

  void _showAchievementProgress() {
    final provider = context.read<SocialProvider>();
    final progress = provider.achievementProgress;
    _showSnackBar('Achievement progress: ${(progress * 100).round()}%');
  }

  void _unlockAchievement() {
    _showSnackBar('Achievement unlocked! (Simulated)');
  }

  Future<void> _shareRestaurant() async {
    final socialService = SocialService();
    final success = await socialService.shareRestaurant(
      restaurantName: 'Franklin Barbecue',
      restaurantAddress: '900 E 11th St, Austin, TX',
    );
    _showSnackBar('Restaurant shared: $success');
  }

  Future<void> _shareVisit() async {
    final socialService = SocialService();
    final success = await socialService.shareVerifiedVisit(
      restaurantName: 'Franklin Barbecue',
      rating: 5.0,
      photoUrl: 'https://picsum.photos/400/300',
      reviewText: 'Amazing BBQ!',
    );
    _showSnackBar('Visit shared: $success');
  }

  Future<void> _generateStory() async {
    final socialService = SocialService();
    final storyFile = await socialService.generateInstagramStory(
      restaurantName: 'Franklin Barbecue',
      photoUrl: 'https://picsum.photos/400/300',
      rating: 5.0,
      reviewText: 'Best BBQ in Austin!',
    );
    _showSnackBar('Story generated: ${storyFile != null}');
  }

  void _showFriendRequests() {
    _showSnackBar('Opening friend requests...');
  }

  void _showSnackBar(String message) {
    // This would use NavigationService.context in a real implementation
    print('SnackBar: $message');
  }
}

// Complete social features example app
class SocialFeaturesExampleApp extends StatelessWidget {
  const SocialFeaturesExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Features Examples',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
      ),
      home: ChangeNotifierProvider(
        create: (_) => SocialProvider(),
        child: const SocialFeaturesExampleWidget(),
      ),
    );
  }
}

// Main example widget
class SocialFeaturesExampleWidget extends StatefulWidget {
  const SocialFeaturesExampleWidget({super.key});

  @override
  State<SocialFeaturesExampleWidget> createState() => _SocialFeaturesExampleWidgetState();
}

class _SocialFeaturesExampleWidgetState extends State<SocialFeaturesExampleWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize social provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Features'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Feed'),
            Tab(text: 'Achievements'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildFeedTab(),
          _buildAchievementsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search section
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => socialProvider.searchFriends(value),
            ),
            
            const SizedBox(height: 16),
            
            // Friends list
            if (socialProvider.friends.isNotEmpty) ...[
              const Text(
                'Your Friends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...socialProvider.friends.map((friend) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FriendCardWidget(
                  friend: friend,
                  onTap: () => _showSnackBar('Tapped ${friend.name}'),
                  onRemove: () => socialProvider.removeFriend(friend.id),
                ),
              )),
            ],
            
            // Search results
            if (socialProvider.searchResults.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...socialProvider.searchResults.map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FriendCardWidget(
                  friend: user,
                  showStats: false,
                  onTap: () => socialProvider.sendFriendRequest(user.id),
                ),
              )),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFeedTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: socialProvider.socialFeed.length,
          itemBuilder: (context, index) {
            final item = socialProvider.socialFeed[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SocialFeedItemWidget(
                item: item,
                onLike: () => socialProvider.likeFeedItem(item.id),
                onUnlike: () => socialProvider.unlikeFeedItem(item.id),
                onTap: () => _showSnackBar('Feed item tapped'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: socialProvider.achievements.length,
          itemBuilder: (context, index) {
            final achievement = socialProvider.achievements[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AchievementCardWidget(
                achievement: achievement,
                onTap: () => _showSnackBar('Achievement tapped: ${achievement.name}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        final stats = socialProvider.userStats;
        
        if (stats == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard('Total Visits', stats.totalVisits.toString()),
            _buildStatCard('Average Rating', stats.averageRating.toStringAsFixed(1)),
            _buildStatCard('Current Streak', stats.currentStreak.toString()),
            _buildStatCard('Max Streak', stats.maxStreak.toString()),
            _buildStatCard('Cuisines Tried', stats.cuisinesTried.length.toString()),
            _buildStatCard('Friends', stats.friendsCount.toString()),
            _buildStatCard('Achievements', stats.achievementsUnlocked.toString()),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
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

