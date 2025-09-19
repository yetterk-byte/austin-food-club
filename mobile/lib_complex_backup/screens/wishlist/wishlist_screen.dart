import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/common/restaurant_card.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_view.dart';
import '../../services/navigation_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isGridView = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().fetchWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Wishlist content
            Expanded(
              child: _buildWishlistContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Wishlist',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<RestaurantProvider>(
                  builder: (context, restaurantProvider, child) {
                    final count = restaurantProvider.wishlist.length;
                    return Text(
                      count == 1 ? '$count restaurant saved' : '$count restaurants saved',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleView,
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistContent() {
    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, child) {
        if (restaurantProvider.isLoading && restaurantProvider.wishlist.isEmpty) {
          return _buildLoadingState();
        }

        if (restaurantProvider.error != null && restaurantProvider.wishlist.isEmpty) {
          return _buildErrorState(restaurantProvider.error!);
        }

        if (restaurantProvider.wishlist.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => restaurantProvider.fetchWishlist(),
          color: Colors.orange,
          child: _isGridView
              ? _buildGridView(restaurantProvider.wishlist)
              : _buildListView(restaurantProvider.wishlist),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isGridView
          ? ShimmerLayouts.verifiedVisitsGrid(itemCount: 6)
          : ShimmerLayouts.restaurantList(itemCount: 5),
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorViewVariants.server(
      customMessage: error,
      onRetry: () {
        context.read<RestaurantProvider>().fetchWishlist();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Your Wishlist is Empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Start exploring restaurants and save your favorites here',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Discover button
            ElevatedButton.icon(
              onPressed: () => NavigationService.goToDiscover(),
              icon: const Icon(Icons.explore),
              label: const Text('Discover Restaurants'),
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

  Widget _buildGridView(List restaurants) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return RestaurantCardVariants.grid(
          restaurant: restaurant,
          onTap: () => NavigationService.pushRestaurantDetails(
            restaurantId: restaurant.id,
          ),
          onWishlistToggle: () => _removeFromWishlist(restaurant.id),
          isInWishlist: true, // Always true in wishlist
        );
      },
    );
  }

  Widget _buildListView(List restaurants) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Dismissible(
            key: Key(restaurant.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
            ),
            onDismissed: (direction) {
              _removeFromWishlist(restaurant.id);
              _showRemovedSnackBar(restaurant.name);
            },
            child: RestaurantCardVariants.featured(
              restaurant: restaurant,
              onTap: () => NavigationService.pushRestaurantDetails(
                restaurantId: restaurant.id,
              ),
              onWishlistToggle: () => _removeFromWishlist(restaurant.id),
              isInWishlist: true, // Always true in wishlist
            ),
          ),
        );
      },
    );
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _removeFromWishlist(String restaurantId) {
    context.read<RestaurantProvider>().toggleWishlist(restaurantId);
  }

  void _showRemovedSnackBar(String restaurantName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$restaurantName removed from wishlist'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Implement undo functionality
            // This would re-add the restaurant to wishlist
          },
        ),
      ),
    );
  }
}

