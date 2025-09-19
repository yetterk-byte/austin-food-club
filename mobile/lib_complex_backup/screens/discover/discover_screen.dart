import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/common/restaurant_card.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_view.dart';
import '../../services/navigation_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isGridView = true;

  final List<String> _filters = ['All', 'BBQ', 'Tacos', 'Asian', 'Italian', 'American'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().fetchAllRestaurants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            
            // Search and filters
            _buildSearchAndFilters(),
            
            // Restaurant list/grid
            Expanded(
              child: _buildRestaurantList(),
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
                  'Discover Restaurants',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find your next favorite spot',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
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

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          CustomTextFieldVariants.search(
            controller: _searchController,
            hint: 'Search restaurants...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onClear: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _filters.length - 1 ? 8 : 0,
                  ),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey.shade800,
                    selectedColor: Colors.orange.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.orange : Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRestaurantList() {
    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, child) {
        if (restaurantProvider.isLoading && restaurantProvider.allRestaurants.isEmpty) {
          return _buildLoadingState();
        }

        if (restaurantProvider.error != null && restaurantProvider.allRestaurants.isEmpty) {
          return _buildErrorState(restaurantProvider.error!);
        }

        final filteredRestaurants = _filterRestaurants(restaurantProvider.allRestaurants);

        if (filteredRestaurants.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => restaurantProvider.fetchAllRestaurants(),
          color: Colors.orange,
          child: _isGridView
              ? _buildGridView(filteredRestaurants)
              : _buildListView(filteredRestaurants),
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
        context.read<RestaurantProvider>().fetchAllRestaurants();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No restaurants found'
                : 'No restaurants available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Check back later for new restaurants',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
          onWishlistToggle: () => _toggleWishlist(restaurant.id),
          isInWishlist: _isInWishlist(restaurant.id),
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
          child: RestaurantCardVariants.featured(
            restaurant: restaurant,
            onTap: () => NavigationService.pushRestaurantDetails(
              restaurantId: restaurant.id,
            ),
            onWishlistToggle: () => _toggleWishlist(restaurant.id),
            isInWishlist: _isInWishlist(restaurant.id),
          ),
        );
      },
    );
  }

  List _filterRestaurants(List restaurants) {
    var filtered = restaurants;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((restaurant) {
        return restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               restaurant.area.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_selectedFilter != 'All') {
      // This would filter by cuisine type if available in the model
      // filtered = filtered.where((restaurant) {
      //   return restaurant.cuisineType == _selectedFilter;
      // }).toList();
    }

    return filtered;
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _toggleWishlist(String restaurantId) {
    context.read<RestaurantProvider>().toggleWishlist(restaurantId);
  }

  bool _isInWishlist(String restaurantId) {
    return context.read<RestaurantProvider>().isInWishlist(restaurantId);
  }
}

