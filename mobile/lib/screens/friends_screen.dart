import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend.dart';
import '../models/user.dart';
import '../services/social_service.dart';
import '../providers/auth_provider.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Friend> friends = [];
  List<SocialFeedItem> socialFeed = [];
  List<User> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '1';

      final loadedFriends = await SocialService.getFriends(userId);
      final loadedFeed = await SocialService.getSocialFeed(userId);

      setState(() {
        friends = loadedFriends;
        socialFeed = loadedFeed;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _searchFriends(String query) async {
    setState(() {
      isSearching = true;
    });

    try {
      // Simulate API call to search users
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock search results based on query
      final mockUsers = [
        User(
          id: 'search_1',
          email: 'emma.wilson@email.com',
          name: 'Emma Wilson',
          isVerified: true,
          createdAt: DateTime.now(),
        ),
        User(
          id: 'search_2',
          email: 'david.martinez@email.com',
          name: 'David Martinez',
          isVerified: true,
          createdAt: DateTime.now(),
        ),
        User(
          id: 'search_3',
          email: 'lisa.taylor@email.com',
          name: 'Lisa Taylor',
          isVerified: false,
          createdAt: DateTime.now(),
        ),
        User(
          id: 'search_4',
          email: 'james.brown@email.com',
          name: 'James Brown',
          isVerified: true,
          createdAt: DateTime.now(),
        ),
      ];

      // Filter based on search query
      final filteredUsers = mockUsers.where((user) {
        final nameMatch = user.name.toLowerCase().contains(query.toLowerCase());
        final emailMatch = user.email.toLowerCase().contains(query.toLowerCase());
        return nameMatch || emailMatch;
      }).toList();

      setState(() {
        searchResults = filteredUsers;
      });
    } catch (e) {
      print('Error searching friends: $e');
    }
  }

  Future<void> _addFriend(User user) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '1';
      
      // Simulate API call to add friend
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Create new friend object
      final newFriend = Friend(
        id: 'friend_${user.id}',
        userId: userId,
        friendId: user.id,
        friendUser: user,
        createdAt: DateTime.now(),
      );
      
      setState(() {
        friends.add(newFriend);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} added to friends!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add friend: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'My Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(),
          _buildFriendsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for friends by name or email...',
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          searchQuery = '';
                          searchResults.clear();
                          isSearching = false;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange),
              ),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
              if (value.isNotEmpty) {
                _searchFriends(value);
              } else {
                setState(() {
                  searchResults.clear();
                  isSearching = false;
                });
              }
            },
          ),
        ),
        
        // Content Area
        Expanded(
          child: isSearching 
              ? _buildSearchResults()
              : _buildMyFriendsList(),
        ),
      ],
    );
  }

  Widget _buildMyFriendsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 24),
            Text(
              'No friends yet',
              style: TextStyle(fontSize: 20, color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            Text(
              'Search above to find and add friends!',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120), // Extra bottom padding for floating buttons
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final user = searchResults[index];
        final isAlreadyFriend = friends.any((f) => f.friendUser.id == user.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                user.initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              user.email,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            trailing: isAlreadyFriend
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'Friends',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _addFriend(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Add', style: TextStyle(fontSize: 12)),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text(
            friend.friendUser.initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          friend.friendUser.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getVerifiedVisitsCount(friend.friendUser.id)} verified visits',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            Text(
              'Last visit: ${_getLastVisitDate(friend.friendUser.id)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'remove') {
              _showRemoveFriendDialog(friend);
            } else if (value == 'view_visits') {
              _showFriendVisits(friend);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_visits',
              child: Row(
                children: [
                  Icon(Icons.restaurant, size: 20),
                  SizedBox(width: 12),
                  Text('View Visits'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Remove Friend', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showFriendVisits(friend),
      ),
    );
  }

  Widget _buildActivityTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (socialFeed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 24),
            Text(
              'No activity yet',
              style: TextStyle(fontSize: 20, color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            Text(
              'Your friends\' activity will appear here!\nVerified visits and RSVPs from your network.',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.orange,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 120), // Extra bottom padding for floating buttons
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
          final item = socialFeed[index];
                  return _buildModernFeedItem(item);
                },
                childCount: socialFeed.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFeedItem(SocialFeedItem item) {
    switch (item.type) {
      case 'verified_visit':
        return _buildVerifiedVisitCard(item);
      case 'rsvp':
        return _buildRSVPLineItem(item);
      default:
        return _buildGenericFeedItem(item);
    }
  }

  Widget _buildVerifiedVisitCard(SocialFeedItem item) {
    return Container(
      width: double.infinity,
      height: 400, // Full screen height card
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo from verified visit
          ClipRRect(
            borderRadius: BorderRadius.circular(0), // Full screen edge-to-edge
            child: Image.network(
              item.photoUrl ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 60, color: Colors.white54),
                  ),
                );
              },
            ),
          ),
          // Dark gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Top-left: Friend name
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              item.user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
          // Top-right: Star rating
          if (item.rating != null)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      item.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bottom-left: Restaurant name and date visited
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.restaurant != null)
                  Text(
                    item.restaurant!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.createdAt),
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRSVPLineItem(SocialFeedItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.orange.withOpacity(0.3),
            child: Text(
              item.user.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // RSVP info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(
                        text: item.user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' is going to '),
                      TextSpan(
                        text: item.restaurant?.name ?? 'a restaurant',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.rsvpDay != null) ...[
                        const TextSpan(text: ' on '),
                        TextSpan(
                          text: item.rsvpDay!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(item.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // RSVP status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: const Text(
              'Going',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericFeedItem(SocialFeedItem item) {
    // Fallback for other activity types
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.orange,
                child: Text(
                  item.user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      _formatDate(item.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.description != null) ...[
            const SizedBox(height: 8),
            Text(
              item.description!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedItem(SocialFeedItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  radius: 20,
                  child: Text(
                    item.user.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.user.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        item.timeAgo,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Content based on type
            if (item.type == 'verified_visit' && item.restaurant != null) ...[
              Row(
                children: [
                  if (item.photoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.photoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        'Attended event at ${item.restaurant!.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < (item.rating ?? 0).floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.white,
                                size: 16,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              '${item.rating?.toInt() ?? 0} stars',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else if (item.type == 'new_friend') ...[
              Text(
                'Joined Austin Food Club! 🎉',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ] else if (item.type == 'rsvp_created' && item.restaurant != null) ...[
              Text(
                'RSVPed to this week\'s event at ${item.restaurant!.name} 📅',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ],
          ],
        ),
      ),
    );
  }


  void _showAddFriendDialog() {
    // Switch to My Friends tab and focus search
    _tabController.animateTo(0);
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use the search bar above to find friends!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showFriendVisits(Friend friend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${friend.friendUser.name}\'s Event History',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_getVerifiedVisitsCount(friend.friendUser.id)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Events',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _getLastVisitDate(friend.friendUser.id),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Last Visit',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event, size: 60, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    const Text('Event history coming soon!'),
                    Text(
                      'You\'ll be able to see all weekly event visits here',
                      style: TextStyle(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFriendDialog(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.friendUser.name} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.currentUser?.id ?? '1';
              
              final success = await SocialService.removeFriend(userId, friend.friendId);
              if (success) {
                setState(() {
                  friends.removeWhere((f) => f.id == friend.id);
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${friend.friendUser.name} removed from friends'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference < 7) {
      return '${difference}d ago';
    } else if (difference < 30) {
      return '${(difference / 7).floor()}w ago';
    } else {
      return '${(difference / 30).floor()}mo ago';
    }
  }

  int _getVerifiedVisitsCount(String userId) {
    // Mock data for friend's verified visits count
    switch (userId) {
      case '3': // Sarah Johnson
        return 8;
      case '4': // Mike Chen
        return 12;
      case '5': // Alex Rivera
        return 3;
      default:
        return 0;
    }
  }

  String _getLastVisitDate(String userId) {
    // Mock data for friend's last visit date
    switch (userId) {
      case '3': // Sarah Johnson
        return '2 days ago';
      case '4': // Mike Chen
        return '1 week ago';
      case '5': // Alex Rivera
        return '3 weeks ago';
      default:
        return 'Never';
    }
  }
}
