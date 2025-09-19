import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/api_service.dart';

class RestaurantProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Restaurant? _currentRestaurant;
  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _wishlist = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  Restaurant? get currentRestaurant => _currentRestaurant;
  List<Restaurant> get allRestaurants => _allRestaurants;
  List<Restaurant> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize restaurant provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      await _fetchCurrentRestaurant();
      await _fetchAllRestaurants();
      await _fetchWishlist();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize restaurants: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch current restaurant (featured restaurant)
  Future<void> fetchCurrentRestaurant() async {
    try {
      _setLoading(true);
      _clearError();
      
      final restaurant = await _apiService.getCurrentRestaurant();
      _currentRestaurant = restaurant;
    } catch (e) {
      _setError('Failed to fetch current restaurant: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all restaurants
  Future<void> fetchAllRestaurants() async {
    try {
      _setLoading(true);
      _clearError();
      
      final restaurants = await _apiService.getAllRestaurants();
      _allRestaurants = restaurants;
    } catch (e) {
      _setError('Failed to fetch restaurants: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch wishlist
  Future<void> fetchWishlist() async {
    try {
      _setLoading(true);
      _clearError();
      
      final wishlist = await _apiService.getWishlist();
      _wishlist = wishlist;
    } catch (e) {
      _setError('Failed to fetch wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle wishlist status
  Future<void> toggleWishlist(String restaurantId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final isInWishlist = _isInWishlist(restaurantId);
      
      if (isInWishlist) {
        await _apiService.removeFromWishlist(restaurantId);
        _wishlist.removeWhere((restaurant) => restaurant.id == restaurantId);
      } else {
        await _apiService.addToWishlist(restaurantId);
        // Add restaurant to wishlist if we have it in allRestaurants
        final restaurant = _allRestaurants.firstWhere(
          (r) => r.id == restaurantId,
          orElse: () => Restaurant(
            id: restaurantId,
            name: 'Unknown Restaurant',
            address: '',
            area: '',
            price: 1,
            weekOf: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        _wishlist.add(restaurant);
      }
    } catch (e) {
      _setError('Failed to toggle wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check if restaurant is in wishlist
  bool isInWishlist(String restaurantId) {
    return _wishlist.any((restaurant) => restaurant.id == restaurantId);
  }

  // Get restaurant by ID
  Restaurant? getRestaurantById(String id) {
    try {
      return _allRestaurants.firstWhere((restaurant) => restaurant.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search restaurants
  List<Restaurant> searchRestaurants(String query) {
    if (query.isEmpty) return _allRestaurants;
    
    final lowercaseQuery = query.toLowerCase();
    return _allRestaurants.where((restaurant) {
      return restaurant.name.toLowerCase().contains(lowercaseQuery) ||
             restaurant.area.toLowerCase().contains(lowercaseQuery) ||
             restaurant.address.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Filter restaurants by area
  List<Restaurant> getRestaurantsByArea(String area) {
    return _allRestaurants.where((restaurant) => restaurant.area == area).toList();
  }

  // Filter restaurants by price range
  List<Restaurant> getRestaurantsByPriceRange(int minPrice, int maxPrice) {
    return _allRestaurants.where((restaurant) {
      return restaurant.price >= minPrice && restaurant.price <= maxPrice;
    }).toList();
  }

  // Get unique areas
  List<String> getUniqueAreas() {
    return _allRestaurants.map((restaurant) => restaurant.area).toSet().toList()..sort();
  }

  // Refresh all data
  Future<void> refresh() async {
    try {
      _setLoading(true);
      _clearError();
      
      await Future.wait([
        _fetchCurrentRestaurant(),
        _fetchAllRestaurants(),
        _fetchWishlist(),
      ]);
    } catch (e) {
      _setError('Failed to refresh data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  Future<void> _fetchCurrentRestaurant() async {
    try {
      final restaurant = await _apiService.getCurrentRestaurant();
      _currentRestaurant = restaurant;
    } catch (e) {
      print('Error fetching current restaurant: $e');
    }
  }

  Future<void> _fetchAllRestaurants() async {
    try {
      final restaurants = await _apiService.getAllRestaurants();
      _allRestaurants = restaurants;
    } catch (e) {
      print('Error fetching all restaurants: $e');
    }
  }

  Future<void> _fetchWishlist() async {
    try {
      final wishlist = await _apiService.getWishlist();
      _wishlist = wishlist;
    } catch (e) {
      print('Error fetching wishlist: $e');
    }
  }

  // Error Management
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}