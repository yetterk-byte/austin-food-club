import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/social/friend_card_widget.dart';
import '../../widgets/social/friend_request_widget.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_view.dart';
import '../../services/navigation_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadFriends();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
          'Friends',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Friends'),
                  Consumer<SocialProvider>(
                    builder: (context, socialProvider, child) {
                      final count = socialProvider.friends.length;
                      if (count > 0) {
                        return Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  Consumer<SocialProvider>(
                    builder: (context, socialProvider, child) {
                      final count = socialProvider.pendingRequestsCount;
                      if (count > 0) {
                        return Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            const Tab(text: 'Find'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildFindTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isFriendsLoading && socialProvider.friends.isEmpty) {
          return _buildLoadingState();
        }

        if (socialProvider.error != null && socialProvider.friends.isEmpty) {
          return _buildErrorState(socialProvider.error!);
        }

        if (socialProvider.friends.isEmpty) {
          return _buildEmptyFriendsState();
        }

        return RefreshIndicator(
          onRefresh: () => socialProvider.loadFriends(),
          color: Colors.orange,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: socialProvider.friends.length,
            itemBuilder: (context, index) {
              final friend = socialProvider.friends[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FriendCardWidget(
                  friend: friend,
                  onTap: () => _showFriendProfile(friend),
                  onRemove: () => _removeFriend(friend),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isFriendsLoading && socialProvider.friendRequests.isEmpty) {
          return _buildLoadingState();
        }

        final pendingRequests = socialProvider.friendRequests
            .where((request) => request.status == FriendRequestStatus.pending)
            .toList();

        if (pendingRequests.isEmpty) {
          return _buildEmptyRequestsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingRequests.length,
          itemBuilder: (context, index) {
            final request = pendingRequests[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FriendRequestWidget(
                request: request,
                onAccept: () => socialProvider.respondToFriendRequest(request.id, true),
                onDecline: () => socialProvider.respondToFriendRequest(request.id, false),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFindTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomTextFieldVariants.search(
                controller: _searchController,
                hint: 'Search by phone number or name...',
                onChanged: (value) {
                  socialProvider.searchFriends(value);
                },
                onClear: () {
                  socialProvider.clearSearchResults();
                },
              ),
            ),
            
            // Search results
            Expanded(
              child: socialProvider.searchResults.isEmpty
                  ? _buildEmptySearchState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: socialProvider.searchResults.length,
                      itemBuilder: (context, index) {
                        final user = socialProvider.searchResults[index];
                        final isFriend = socialProvider.isFriend(user.id);
                        final hasPendingRequest = socialProvider.hasPendingRequest(user.id);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSearchResultCard(
                            user,
                            isFriend,
                            hasPendingRequest,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResultCard(Friend user, bool isFriend, bool hasPendingRequest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade700,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade600,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    color: Colors.grey.shade400,
                  )
                : null,
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.phoneNumber!,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (isFriend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                'Friends',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (hasPendingRequest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _sendFriendRequest(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Add Friend'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerContainer(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorViewVariants.server(
      customMessage: error,
      onRetry: () {
        context.read<SocialProvider>().loadFriends();
      },
    );
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Friends Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Find friends to share your food adventures with',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(2),
              icon: const Icon(Icons.search),
              label: const Text('Find Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mail_outline,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Friend Requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Friend requests will appear here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Find Friends',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Search for friends by phone number or name',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendProfile(Friend friend) {
    NavigationService.goToNamed('friend-profile', pathParameters: {'id': friend.id});
  }

  void _removeFriend(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.name} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SocialProvider>().removeFriend(friend.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _sendFriendRequest(Friend user) {
    context.read<SocialProvider>().sendFriendRequest(user.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request sent to ${user.name}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

