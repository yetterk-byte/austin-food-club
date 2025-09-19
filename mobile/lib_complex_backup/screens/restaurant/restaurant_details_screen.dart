import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/star_rating.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/navigation_service.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().fetchRestaurantDetails(widget.restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<RestaurantProvider>(
        builder: (context, restaurantProvider, child) {
          final restaurant = restaurantProvider.currentRestaurant;

          if (restaurantProvider.isLoading && restaurant == null) {
            return _buildLoadingState();
          }

          if (restaurantProvider.error != null && restaurant == null) {
            return _buildErrorState(restaurantProvider.error!);
          }

          if (restaurant == null) {
            return _buildNotFoundState();
          }

          return CustomScrollView(
            slivers: [
              // Hero image with app bar
              _buildSliverAppBar(restaurant),
              
              // Restaurant details
              SliverToBoxAdapter(
                child: _buildRestaurantDetails(restaurant),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => NavigationService.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: ShimmerLayouts.currentRestaurant(),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => NavigationService.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: ErrorViewVariants.server(
        customMessage: error,
        onRetry: () {
          context.read<RestaurantProvider>().fetchRestaurantDetails(widget.restaurantId);
        },
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => NavigationService.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: ErrorViewVariants.notFound(
        customMessage: 'Restaurant not found',
        onRetry: () => NavigationService.pop(),
      ),
    );
  }

  Widget _buildSliverAppBar(restaurant) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        onPressed: () => NavigationService.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _toggleWishlist(restaurant.id),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Consumer<RestaurantProvider>(
              builder: (context, provider, child) {
                final isInWishlist = provider.isInWishlist(restaurant.id);
                return Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_outline,
                  color: isInWishlist ? Colors.red : Colors.white,
                );
              },
            ),
          ),
        ),
        IconButton(
          onPressed: () => _shareRestaurant(restaurant),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Restaurant image
            restaurant.imageUrl != null
                ? Image.network(
                    restaurant.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                  )
                : _buildPlaceholderImage(),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildRestaurantDetails(restaurant) {
    return Container(
      color: Colors.grey.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info
          _buildBasicInfo(restaurant),
          
          // Rating and price
          _buildRatingAndPrice(restaurant),
          
          // Description
          _buildDescription(restaurant),
          
          // Hours
          _buildHours(restaurant),
          
          // Location
          _buildLocation(restaurant),
          
          // RSVP section
          _buildRSVPSection(restaurant),
          
          // Bottom padding
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(restaurant) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant.name,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            restaurant.area,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingAndPrice(restaurant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Rating
          StarRatingVariants.withText(
            rating: 4.5, // Mock rating
            text: '4.5 (123 reviews)',
            starSize: 20,
          ),
          
          const Spacer(),
          
          // Price range
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
              ),
            ),
            child: Text(
              '\$' * restaurant.price,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(restaurant) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            restaurant.description ?? 'A great restaurant in ${restaurant.area}. Come enjoy amazing food and excellent service.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade300,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHours(restaurant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hours',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildHourRow('Monday - Thursday', '11:00 AM - 9:00 PM'),
                _buildHourRow('Friday - Saturday', '11:00 AM - 10:00 PM'),
                _buildHourRow('Sunday', '12:00 PM - 8:00 PM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation(restaurant) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    restaurant.address,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _openMaps(restaurant.address),
                  icon: const Icon(
                    Icons.directions,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRSVPSection(restaurant) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visit This Week',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Join other food lovers this week!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          CustomButtonVariants.primary(
            text: 'RSVP for This Week',
            fullWidth: true,
            size: ButtonSize.large,
            icon: Icons.event,
            onPressed: () => _showRSVPModal(restaurant),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _toggleWishlist(String restaurantId) {
    context.read<RestaurantProvider>().toggleWishlist(restaurantId);
  }

  void _shareRestaurant(restaurant) {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${restaurant.name}...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _openMaps(String address) {
    // Implement maps opening functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to $address...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showRSVPModal(restaurant) {
    // Implement RSVP modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('RSVP for ${restaurant.name}'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

