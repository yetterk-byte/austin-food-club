import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable/expandable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/restaurant.dart';
import '../widgets/rsvp_section.dart';
import '../widgets/reliable_map_widget.dart';
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

class _RestaurantScreenState extends State<RestaurantScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add scroll listener for bottom navigation opacity
    _scrollController.addListener(_onScroll);
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
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Full-screen Hero Image with Parallax Effect
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height, // Full screen height
            floating: false,
            pinned: true,
            backgroundColor: Colors.black.withOpacity(0.5), // More translucent app bar background
            toolbarHeight: 80, // Increased height to accommodate large Monoton text
            title: Text(
              'Austin Food Club',
              style: GoogleFonts.monoton(
                color: Colors.white,
                fontSize: 32, // Keep the same large size as hero!
                letterSpacing: 2.0, // Keep the same spacing as hero
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Calculate the scroll progress (0.0 = fully expanded, 1.0 = fully collapsed)
                final double expandedHeight = MediaQuery.of(context).size.height;
                final double collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
                final double currentHeight = constraints.maxHeight;
                final double scrollProgress = 1.0 - ((currentHeight - collapsedHeight) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);
                
                    // Calculate positions for the restaurant name transition
                    final double heroNameTop = MediaQuery.of(context).padding.top + 60; // Higher since no Austin Food Club in hero
                    final double heroNameLeft = 20;
                final double contentNameTop = expandedHeight - (expandedHeight - collapsedHeight) * (1 - scrollProgress) + 60; // Approximate content position
                final double contentNameLeft = 20;
                
                // Interpolate between hero and content positions
                final double nameTop = heroNameTop + (contentNameTop - heroNameTop) * scrollProgress;
                final double nameLeft = heroNameLeft + (contentNameLeft - heroNameLeft) * scrollProgress;
                
                // Calculate font size transition (32px to 28px)
                final double fontSize = 32.0 - (4.0 * scrollProgress);
                
                // Calculate opacity for the scroll indicator
                final double scrollIndicatorOpacity = (1.0 - scrollProgress * 2).clamp(0.0, 1.0);
                
                return Stack(
                fit: StackFit.expand,
                children: [
                    // Full-screen restaurant image
                  CachedNetworkImage(
                      imageUrl: widget.restaurant.imageUrl ?? 'https://via.placeholder.com/400x200?text=Restaurant+Image',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.orange),
                        ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 100, color: Colors.white54),
                      ),
                    ),
                  ),
                    // Subtle gradient for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                    // App bar bottom edge gradient (only at the very bottom)
                    if (scrollProgress > 0.7) // Show gradient when app bar is mostly visible
                      Positioned(
                        top: collapsedHeight - 5, // Start at very bottom of app bar
                        left: 0,
                        right: 0,
                        height: 30, // Much smaller gradient zone
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),  // Light start
                                Colors.black.withOpacity(0.15), // Very light
                                Colors.black.withOpacity(0.05), // Almost transparent
                                Colors.transparent,              // Fully transparent
                              ],
                              stops: const [0.0, 0.4, 0.7, 1.0], // Quick, subtle bottom fade
                            ),
                          ),
                        ),
                      ),
                        // Austin Food Club is now always in the app bar
                    // Animated restaurant name that transitions from hero to content position
                    if (scrollProgress < 0.9) // Hide when almost fully scrolled to avoid overlap
                      Positioned(
                        top: nameTop,
                        left: nameLeft,
                        right: 20,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 100),
                          opacity: 1.0 - (scrollProgress * 1.2).clamp(0.0, 1.0),
                          child: Text(
                            widget.restaurant.name,
                            style: GoogleFonts.robotoCondensed(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w300, // Light 300
                              letterSpacing: -0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8 - (4 * scrollProgress), // Reduce shadow as it transitions
                                  offset: Offset(2 - scrollProgress, 2 - scrollProgress),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                        // Scroll indicator at bottom (fades out as you scroll)
                        if (scrollIndicatorOpacity > 0)
                          Positioned(
                            bottom: 40,
                            left: 0,
                            right: 0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: scrollIndicatorOpacity,
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.white.withOpacity(0.8),
                                size: 32,
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
                            // Calculate scroll progress for content visibility
                            final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
                            final expandedHeight = MediaQuery.of(context).size.height;
                            final scrollProgress = (scrollOffset / (expandedHeight * 0.7)).clamp(0.0, 1.0);
                            
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: scrollProgress > 0.8 ? 1.0 : 0.0, // Show when hero name is almost gone
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
                          widget.restaurant.categories?.first.title ?? 'Restaurant',
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
                  // Hours - Expandable
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ExpandableNotifier(
                      child: Card(
                        color: Colors.grey[900],
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[700]!, width: 1),
                        ),
                        child: ExpandablePanel(
                          header: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
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
                          ),
                          collapsed: Container(),
                          expanded: Padding(
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
                          theme: const ExpandableThemeData(
                            headerAlignment: ExpandablePanelHeaderAlignment.center,
                            tapBodyToExpand: true,
                            tapBodyToCollapse: true,
                            hasIcon: true,
                            iconColor: Colors.orange,
                            iconSize: 20,
                          ),
                        ),
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
                        // Reliable Google Maps Widget
                        ReliableMapWidget(
                          latitude: widget.restaurant.latitude,
                          longitude: widget.restaurant.longitude,
                          restaurantName: widget.restaurant.name,
                          address: widget.restaurant.fullAddress,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                // RSVP Section
                RSVPSection(restaurant: widget.restaurant),
                  const SizedBox(height: 120), // Extra space for floating buttons
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
