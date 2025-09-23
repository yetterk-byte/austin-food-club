import 'dart:async';
import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/search_service.dart';

class RestaurantSearchWidget extends StatefulWidget {
  final Function(Restaurant) onRestaurantSelected;
  final String? initialQuery;

  const RestaurantSearchWidget({
    super.key,
    required this.onRestaurantSelected,
    this.initialQuery,
  });

  @override
  State<RestaurantSearchWidget> createState() => _RestaurantSearchWidgetState();
}

class _RestaurantSearchWidgetState extends State<RestaurantSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Restaurant> _searchResults = [];
  bool _isSearching = false;
  String _lastSearchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (query.trim().length < 2) {
      return; // Don't search for queries shorter than 2 characters
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query == _lastSearchQuery) return;
    
    setState(() {
      _isSearching = true;
      _lastSearchQuery = query;
    });

    try {
      final results = await SearchService.searchRestaurantsDebounced(
        query: query,
        limit: 10,
      );

      if (mounted && query == _lastSearchQuery) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && query == _lastSearchQuery) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search restaurants (e.g., "Terry Blacks")',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _isSearching = false;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.grey),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        const SizedBox(height: 16),

        // Search results
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }
    
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No restaurants found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    if (_searchResults.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final restaurant = _searchResults[index];
            return _buildRestaurantTile(restaurant);
          },
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Search for restaurants',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Type a restaurant name to find it',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantTile(Restaurant restaurant) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.orange,
        radius: 20,
        child: Text(
          restaurant.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        restaurant.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (restaurant.categories?.isNotEmpty == true)
            Text(
              restaurant.categories!.first.title,
              style: const TextStyle(color: Colors.grey),
            ),
          if (restaurant.address.isNotEmpty)
            Text(
              restaurant.address,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          if (restaurant.rating != null)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${restaurant.rating!.toStringAsFixed(1)} (${restaurant.reviewCount ?? 0} reviews)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: () => widget.onRestaurantSelected(restaurant),
    );
  }
}

