import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/restaurant.dart';
import '../widgets/rsvp_section.dart';
import '../widgets/simple_map_widget.dart';
import '../config/app_theme.dart';
// import 'photo_verification_screen.dart'; // Temporarily disabled

class RestaurantScreen extends StatefulWidget {
  final Restaurant restaurant;
  final Function(double)? onScrollOpacityChanged;

  const RestaurantScreen({
    super.key,
    required this.restaurant,
    this.onScrollOpacityChanged,
  });

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    // Add scroll listener for bottom navigation opacity
    _scrollController.addListener(_onScroll);

    // Pulsing arrow animation
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  void _onScroll() {
    if (widget.onScrollOpacityChanged != null) {
      // Calculate opacity based on scroll position
      // Show buttons after scrolling 200px from top
      const double showThreshold = 200.0;
      double opacity = (_scrollController.offset / showThreshold).clamp(0.0, 1.0);
      widget.onScrollOpacityChanged!(opacity);
    }
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return const Icon(
            Icons.star,
            color: Colors.white,
            size: 20,
          );
        } else if (index < rating) {
          // Half star
          return const Icon(
            Icons.star_half,
            color: Colors.white,
            size: 20,
          );
        } else {
          // Empty star
          return const Icon(
            Icons.star_border,
            color: Colors.white,
            size: 20,
          );
        }
      }),
    );
  }

  Widget _buildCurrentStatusChip() {
    // Simple logic to determine if restaurant is currently open
    // In a real app, you'd check against current time and hours
    final now = DateTime.now();
    final isWeekend = now.weekday >= 6; // Saturday = 6, Sunday = 7
    final currentHour = now.hour;
    
    // Simple heuristic: assume open during typical dinner hours
    final isLikelyOpen = (currentHour >= 17 && currentHour <= 22) || isWeekend;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLikelyOpen 
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLikelyOpen 
              ? Colors.green.withOpacity(0.5)
              : Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Text(
        isLikelyOpen ? 'Open' : 'Check Hours',
        style: TextStyle(
          color: isLikelyOpen ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🏪 RestaurantScreen: Building screen for ${widget.restaurant.name}');
    
    // RESTORED FULL RESTAURANT SCREEN EXPERIENCE
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Full-screen Hero Image with Parallax + animated restaurant title
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height, // Full screen hero
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            toolbarHeight: 60,
            title: Text(
              'Austin Food Club',
              style: AppTheme.monotonBranding.copyWith(
                fontSize: 28,
                color: Colors.white,
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Calculate the scroll progress (0.0 = fully expanded, 1.0 = fully collapsed)
                final double expandedHeight = MediaQuery.of(context).size.height;
                final double collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
                final double currentHeight = constraints.maxHeight;
                final double rawProgress = 1.0 - ((currentHeight - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);

                // Slightly quicker fall (less easing power)
                final double positionProgress = math.pow(rawProgress, 1.4).toDouble();
                
                // Start restaurant title below app name, animate toward details header
                const double toolbarH = 60.0;
                final double heroNameTop = MediaQuery.of(context).padding.top + toolbarH + 8;
                final double heroNameLeft = 16;
                final double contentNameTop = expandedHeight - 100; // target closer to details title
                final double contentNameLeft = 20;
                
                // Interpolate between positions using slowed progress
                final double nameTop = heroNameTop + (contentNameTop - heroNameTop) * positionProgress;
                final double nameLeft = heroNameLeft + (contentNameLeft - heroNameLeft) * positionProgress;
                
                // Calculate opacity for the scroll indicator (keep visible longer)
                final double scrollIndicatorOpacity = (1.0 - rawProgress * 1.2).clamp(0.0, 1.0);
                // Slightly sooner handoff (~55% collapsed)
                const double handoffStart = 0.55;
                const double handoffEnd = 1.0;
                final double heroOpacity = (1.0 - ((rawProgress - handoffStart) / (handoffEnd - handoffStart)).clamp(0.0, 1.0));
                
                return Stack(
                fit: StackFit.expand,
                children: [
                    // Full-screen restaurant image
                  Image.network(
                    widget.restaurant.imageUrl ?? 'https://via.placeholder.com/400x200?text=Restaurant+Image',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      print('🏪 RestaurantScreen: Loading image: ${widget.restaurant.imageUrl}');
                      if (loadingProgress == null) {
                        print('🏪 RestaurantScreen: Image loaded successfully');
                        return child;
                      }
                      print('🏪 RestaurantScreen: Image loading progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.orange),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('🏪 RestaurantScreen: Image load error: $error');
                      print('🏪 RestaurantScreen: Image URL: ${widget.restaurant.imageUrl}');
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.restaurant, size: 100, color: Colors.white54),
                        ),
                      );
                    },
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
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    // Animated restaurant name under the app title (cross-fades during handoff)
                    Positioned(
                      top: nameTop,
                      left: nameLeft,
                      right: 20,
                      child: Opacity(
                        opacity: heroOpacity,
                        child: Text(
                          widget.restaurant.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          // Match details section typography
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Pulsing down-arrow scroll hint
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: scrollIndicatorOpacity,
                        child: AnimatedBuilder(
                          animation: _arrowController,
                          builder: (context, child) {
                            final double t = _arrowController.value; // 0..1
                            final double opacity = 0.5 + 0.5 * t; // 0.5..1.0
                            final double dy = 4 * (1 - t); // small up/down motion
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(0, dy),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white70,
                                  size: 30,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Content with background overlay
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black, // Match app background
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  const SizedBox(height: 20), // Top padding for rounded corners
                // Restaurant Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'This Week\'s Featured Restaurant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                        AnimatedBuilder(
                          animation: _scrollController,
                          builder: (context, child) {
                            // Reveal the inline name earlier so hero lands precisely
                            final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
                            final expandedHeight = MediaQuery.of(context).size.height;
                            final scrollProgress = (scrollOffset / (expandedHeight * 0.8)).clamp(0.0, 1.0);
                            
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: scrollProgress > 0.65 ? 1.0 : 0.0,
                              child: Text(
                        widget.restaurant.name,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                              ),
                            );
                          },
                      ),
                      const SizedBox(height: 8),
                      Text(
                          widget.restaurant.categories != null && widget.restaurant.categories!.isNotEmpty 
                              ? widget.restaurant.categories!.first.title 
                              : 'Restaurant',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Rating, Price, Wait Time Row
                      Row(
                        children: [
                          // Stars
                            _buildStarRating(widget.restaurant.rating ?? 0.0),
                          const SizedBox(width: 20),
                          // Price Range
                          Text(
                              widget.restaurant.price ?? '\$\$',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Wait Time
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 18, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                  widget.restaurant.expectedWait ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                  const SizedBox(height: 24),
                  // About
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          widget.restaurant.specialNotes ?? 'A great restaurant in Austin.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Specialties
                  if (widget.restaurant.categories != null && widget.restaurant.categories!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Specialties',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                            children: widget.restaurant.categories!.map((category) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orange.withOpacity(0.5)),
                              ),
                              child: Text(
                                  category.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[300],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Hours - Simplified
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      color: Colors.grey[900],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[700]!, width: 1),
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hours',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            // Current status indicator
                            _buildCurrentStatusChip(),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                const Divider(color: Colors.grey),
                                const SizedBox(height: 8),
                                ...(widget.restaurant.hours?.entries ?? <MapEntry<String, dynamic>>[]).map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: entry.value == 'Closed' 
                                                ? Colors.red.withOpacity(0.2)
                                                : Colors.green.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: entry.value == 'Closed' 
                                                  ? Colors.red.withOpacity(0.5)
                                                  : Colors.green.withOpacity(0.5),
                                            ),
                                          ),
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              color: entry.value == 'Closed' ? Colors.red : Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Location with Google Map
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Map only
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[700]!, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SimpleMapWidget(
                                  latitude: widget.restaurant.latitude,
                                  longitude: widget.restaurant.longitude,
                                  address: null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                // RSVP Section
                Center(
                  child: RSVPSection(restaurant: widget.restaurant),
                ),
                  const SizedBox(height: 120), // Extra space for floating buttons
              ],
            ),
          ),
        ),
        ],
      ),
      ),
    );
  }
}
