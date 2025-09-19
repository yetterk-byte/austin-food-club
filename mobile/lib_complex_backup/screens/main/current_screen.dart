import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/rsvp_provider.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/restaurant/restaurant_hero.dart';
import '../../widgets/restaurant/rsvp_section.dart';
import '../../widgets/restaurant/restaurant_details.dart';
import '../../widgets/restaurant/rsvp_bottom_sheet.dart';

class CurrentScreen extends StatefulWidget {
  const CurrentScreen({super.key});

  @override
  State<CurrentScreen> createState() => _CurrentScreenState();
}

class _CurrentScreenState extends State<CurrentScreen>
    with TickerProviderStateMixin {
  late AnimationController _parallaxController;
  late AnimationController _rsvpAnimationController;
  late Animation<double> _parallaxAnimation;
  late Animation<double> _rsvpAnimation;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
  }

  void _initializeAnimations() {
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rsvpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _parallaxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: Curves.easeOut,
    ));

    _rsvpAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rsvpAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final maxOffset = 200.0; // Adjust based on your hero height
      final progress = (offset / maxOffset).clamp(0.0, 1.0);
      _parallaxController.value = progress;
    });
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    _rsvpAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<AppProvider, RestaurantProvider, RSVPProvider>(
        builder: (context, appProvider, restaurantProvider, rsvpProvider, child) {
          // Show loading state
          if (!appProvider.isInitialized || restaurantProvider.isLoading) {
            return _buildLoadingState();
          }

          // Show error state
          if (restaurantProvider.error != null) {
            return CustomErrorWidget(
              message: restaurantProvider.error!,
              onRetry: () => _refreshData(),
            );
          }

          // Show main content
          final restaurant = restaurantProvider.currentRestaurant;
          if (restaurant == null) {
            return _buildEmptyState();
          }

          return _buildMainContent(restaurant, rsvpProvider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: LoadingShimmer(
            child: Container(
              height: 300,
              color: Colors.grey.shade300,
            ),
          ),
        ),
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
            Icons.restaurant,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No restaurant available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for the featured restaurant',
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

  Widget _buildMainContent(restaurant, RSVPProvider rsvpProvider) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _refreshData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Hero Section with Parallax
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () => _shareRestaurant(restaurant),
                icon: const Icon(Icons.share),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedBuilder(
                animation: _parallaxAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -50 * _parallaxAnimation.value),
                    child: RestaurantHero(
                      restaurant: restaurant,
                      parallaxValue: _parallaxAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // Restaurant Details
          SliverToBoxAdapter(
            child: RestaurantDetails(
              restaurant: restaurant,
              onReadMore: _showDescriptionBottomSheet,
            ),
          ),

          // RSVP Section
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _rsvpAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * _rsvpAnimation.value),
                  child: RSVPSection(
                    restaurant: restaurant,
                    onRSVP: _handleRSVP,
                    onShowDetails: _showRSVPDetails,
                  ),
                );
              },
            ),
          ),

          // Additional Info
          SliverToBoxAdapter(
            child: _buildAdditionalInfo(restaurant),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(restaurant) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hours of Operation
          _buildInfoSection(
            icon: Icons.access_time,
            title: 'Hours of Operation',
            content: _buildHoursContent(restaurant),
          ),
          
          const SizedBox(height: 24),
          
          // Address with Map Link
          _buildInfoSection(
            icon: Icons.location_on,
            title: 'Location',
            content: _buildAddressContent(restaurant),
          ),
          
          const SizedBox(height: 24),
          
          // Contact Info
          _buildInfoSection(
            icon: Icons.phone,
            title: 'Contact',
            content: _buildContactContent(restaurant),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildHoursContent(restaurant) {
    // Mock hours data - replace with actual restaurant hours
    final hours = {
      'Monday': '11:00 AM - 10:00 PM',
      'Tuesday': '11:00 AM - 10:00 PM',
      'Wednesday': '11:00 AM - 10:00 PM',
      'Thursday': '11:00 AM - 10:00 PM',
      'Friday': '11:00 AM - 11:00 PM',
      'Saturday': '10:00 AM - 11:00 PM',
      'Sunday': '10:00 AM - 9:00 PM',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hours.entries.map((entry) {
        final isToday = _isToday(entry.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? Colors.orange : null,
                  ),
                ),
              ),
              Text(
                entry.value,
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.orange : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddressContent(restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant.address,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _openMaps(restaurant),
              icon: const Icon(Icons.map, size: 16),
              label: const Text('Open in Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _getDirections(restaurant),
              icon: const Icon(Icons.directions, size: 16),
              label: const Text('Directions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactContent(restaurant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (restaurant.phone != null) ...[
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(restaurant.phone!),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _callRestaurant(restaurant.phone!),
                icon: const Icon(Icons.call, color: Colors.green),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (restaurant.website != null) ...[
          Row(
            children: [
              const Icon(Icons.language, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restaurant.website!,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              IconButton(
                onPressed: () => _openWebsite(restaurant.website!),
                icon: const Icon(Icons.open_in_new, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Event Handlers
  Future<void> _refreshData() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.refreshAll();
  }

  Future<void> _handleRSVP(String day, String status) async {
    final rsvpProvider = Provider.of<RSVPProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    
    try {
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      if (status == 'going') {
        await rsvpProvider.createRSVP(restaurantProvider.currentRestaurant!.id, day);
        _rsvpAnimationController.forward().then((_) {
          _rsvpAnimationController.reverse();
        });
      } else {
        // Handle other statuses (maybe, not going)
        // Implementation depends on your API
      }
      
      // Show success message
      _showSuccessMessage('RSVP updated successfully!');
    } catch (e) {
      _showErrorMessage('Failed to update RSVP: $e');
    }
  }

  void _showRSVPDetails(String day) {
    final rsvpProvider = Provider.of<RSVPProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RSVPBottomSheet(
        restaurant: restaurantProvider.currentRestaurant!,
        day: day,
        rsvpCount: rsvpProvider.getRSVPCount(day),
        onAddToCalendar: () => _addToCalendar(day),
        onSetReminder: () => _setReminder(day),
      ),
    );
  }

  void _showDescriptionBottomSheet(String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                    'About This Restaurant',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareRestaurant(restaurant) {
    // Implement sharing functionality
    final text = 'Check out ${restaurant.name} at ${restaurant.address}!';
    // Use share_plus package for actual sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing: $text')),
    );
  }

  Future<void> _openMaps(restaurant) async {
    final url = Uri.parse(
      'https://maps.google.com/?q=${Uri.encodeComponent(restaurant.address)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _getDirections(restaurant) async {
    final url = Uri.parse(
      'https://maps.google.com/?daddr=${Uri.encodeComponent(restaurant.address)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _callRestaurant(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWebsite(String website) async {
    final url = Uri.parse(website);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _addToCalendar(String day) async {
    // Implement calendar integration
    _showSuccessMessage('Added to calendar!');
  }

  Future<void> _setReminder(String day) async {
    // Implement reminder functionality
    _showSuccessMessage('Reminder set!');
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isToday(String day) {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = weekdays[now.weekday - 1];
    return day == today;
  }
}