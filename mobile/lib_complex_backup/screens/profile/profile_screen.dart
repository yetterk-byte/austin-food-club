import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/rsvp_provider.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/profile/user_header.dart';
import '../../widgets/profile/upcoming_rsvps.dart';
import '../../widgets/profile/verified_visits.dart';
import '../../widgets/profile/settings_section.dart';
import '../../widgets/profile/achievements_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  bool _isGridView = true;
  String _sortBy = 'date'; // date, rating, restaurant
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

    _fabController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 100) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer4<AppProvider, AuthProvider, UserProvider, RSVPProvider>(
        builder: (context, appProvider, authProvider, userProvider, rsvpProvider, child) {
          // Show loading state
          if (!appProvider.isInitialized || userProvider.isLoading) {
            return _buildLoadingState();
          }

          // Show error state
          if (userProvider.error != null) {
            return CustomErrorWidget(
              message: userProvider.error!,
              onRetry: () => _refreshData(),
            );
          }

          // Show main content
          final user = userProvider.currentUser;
          if (user == null) {
            return _buildEmptyState();
          }

          return _buildMainContent(user, userProvider, rsvpProvider);
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        // Loading header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: LoadingShimmer(
            child: Container(
              height: 200,
              color: Colors.grey.shade300,
            ),
          ),
        ),
        
        // Loading content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LoadingShimmer(
                child: Container(
                  height: 20,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 8),
              LoadingShimmer(
                child: Container(
                  height: 16,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 16),
              LoadingShimmer(
                child: Container(
                  height: 100,
                  color: Colors.grey.shade300,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No profile data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please sign in to view your profile',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(user, UserProvider userProvider, RSVPProvider rsvpProvider) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _refreshData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // User Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _showSettingsBottomSheet,
                icon: const Icon(Icons.settings),
              ),
              IconButton(
                onPressed: _shareProfile,
                icon: const Icon(Icons.share),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: UserHeader(
                user: user,
                onEditProfile: _editProfile,
                onEditAvatar: _editAvatar,
              ),
            ),
          ),

          // Stats Section
          SliverToBoxAdapter(
            child: _buildStatsSection(userProvider),
          ),

          // Upcoming RSVPs Section
          SliverToBoxAdapter(
            child: UpcomingRSVPs(
              rsvps: rsvpProvider.userRSVPs,
              onVerifyVisit: _verifyVisit,
              onCancelRSVP: _cancelRSVP,
            ),
          ),

          // Verified Visits Section
          SliverToBoxAdapter(
            child: VerifiedVisits(
              visits: userProvider.verifiedVisits,
              isGridView: _isGridView,
              sortBy: _sortBy,
              onToggleView: () => setState(() => _isGridView = !_isGridView),
              onSortChanged: (sortBy) => setState(() => _sortBy = sortBy),
              onVisitTapped: _showVisitDetails,
              onLoadMore: _loadMoreVisits,
            ),
          ),

          // Achievements Section
          SliverToBoxAdapter(
            child: AchievementsSection(
              user: user,
              visits: userProvider.verifiedVisits,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(UserProvider userProvider) {
    final stats = userProvider.getUserStats();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Visits
          Expanded(
            child: _buildStatItem(
              icon: Icons.restaurant,
              label: 'Total Visits',
              value: '${stats['totalVisits'] ?? 0}',
              color: Colors.blue,
            ),
          ),
          
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          
          // Average Rating
          Expanded(
            child: _buildStatItem(
              icon: Icons.star,
              label: 'Avg Rating',
              value: '${(stats['averageRating'] ?? 0.0).toStringAsFixed(1)}',
              color: Colors.orange,
            ),
          ),
          
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          
          // This Month
          Expanded(
            child: _buildStatItem(
              icon: Icons.calendar_month,
              label: 'This Month',
              value: '${stats['thisMonthVisits'] ?? 0}',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton(
            onPressed: _showQuickActions,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // Event Handlers
  Future<void> _refreshData() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.refreshAll();
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditProfileBottomSheet(),
    );
  }

  void _editAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditAvatarBottomSheet(),
    );
  }

  void _verifyVisit(rsvp) {
    // Navigate to verification screen
    Navigator.of(context).pushNamed('/verification', arguments: rsvp);
  }

  void _cancelRSVP(String rsvpId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel RSVP'),
        content: const Text('Are you sure you want to cancel this RSVP?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Cancel RSVP logic
              _showSuccessMessage('RSVP cancelled');
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showVisitDetails(visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVisitDetailsBottomSheet(visit),
    );
  }

  void _loadMoreVisits() {
    // Load more verified visits
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Implement pagination logic
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSection(
        onSignOut: _signOut,
        onNotificationSettings: _showNotificationSettings,
        onPrivacySettings: _showPrivacySettings,
        onAccountManagement: _showAccountManagement,
      ),
    );
  }

  void _shareProfile() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final stats = userProvider.getUserStats();
    
    final message = 'Check out my Austin Food Club profile! '
        '${stats['totalVisits']} visits, '
        '${(stats['averageRating'] ?? 0.0).toStringAsFixed(1)} avg rating.';
    
    // Use share_plus package for actual sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: $message'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickActionsBottomSheet(),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    // Navigate to notification settings
    Navigator.of(context).pushNamed('/settings/notifications');
  }

  void _showPrivacySettings() {
    // Navigate to privacy settings
    Navigator.of(context).pushNamed('/settings/privacy');
  }

  void _showAccountManagement() {
    // Navigate to account management
    Navigator.of(context).pushNamed('/settings/account');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Bottom Sheet Builders
  Widget _buildEditProfileBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // Add form fields for editing profile
                const Text('Profile editing form would go here'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditAvatarBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Take photo logic
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Choose from gallery logic
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Remove photo logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitDetailsBottomSheet(visit) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.restaurant?.name ?? 'Unknown Restaurant',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // Add visit details
                const Text('Visit details would go here'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: const Text('Add Restaurant'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Add restaurant logic
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Verify Visit'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Verify visit logic
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('View Wishlist'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // View wishlist logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

