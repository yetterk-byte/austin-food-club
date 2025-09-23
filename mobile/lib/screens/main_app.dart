import 'package:flutter/material.dart';
import 'dart:ui';
import 'restaurant_screen.dart';
import 'profile_screen.dart';
import 'friends_screen.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../widgets/api_status_indicator.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  Restaurant? featuredRestaurant;
  bool isLoading = true;
  double _bottomNavOpacity = 0.0; // Control bottom nav visibility

  @override
  void initState() {
    super.initState();
    _loadFeaturedRestaurant();
  }

  Future<void> _loadFeaturedRestaurant() async {
    try {
      final restaurant = await RestaurantService.getFeaturedRestaurant();
      setState(() {
        featuredRestaurant = restaurant;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading featured restaurant: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      // Reset bottom nav opacity when switching away from restaurant screen
      if (index != 0) {
        _bottomNavOpacity = 1.0;
      }
    });
  }

  // Callback to update bottom nav opacity based on scroll position
  void _updateBottomNavOpacity(double opacity) {
    if (_bottomNavOpacity != opacity) {
      setState(() {
        _bottomNavOpacity = opacity;
      });
    }
  }

  Widget _buildFloatingCircularNav() {
    final List<NavItem> navItems = [
      NavItem(
        icon: Icons.restaurant,
        activeIcon: Icons.restaurant,
        label: 'This Week',
        index: 0,
      ),
      NavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Friends',
        index: 1,
      ),
      NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        index: 2,
      ),
    ];

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: navItems.map((item) => _buildCircularNavItem(item)).toList(),
        ),
      ),
    );
  }

  Widget _buildCircularNavItem(NavItem item) {
    final bool isSelected = _currentIndex == item.index;
    
    return GestureDetector(
      onTap: () => _onTabTapped(item.index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
            color: isSelected 
                ? Colors.orange.withOpacity(0.25) // More see-through orange
                : Colors.black.withOpacity(0.2), // More see-through black
                // No border/outline as requested
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: isSelected ? 15 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
          child: Center(
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              color: Colors.white, // Always white for maximum visibility
              size: isSelected ? 26 : 22, // Smaller icons for smaller buttons
            ),
          ),
          ),
        ),
      ),
    ),
  );
  }

  List<Widget> get _screens {
    return [
      featuredRestaurant != null 
          ? RestaurantScreen(
              restaurant: featuredRestaurant!,
              onScrollOpacityChanged: _currentIndex == 0 ? _updateBottomNavOpacity : null,
            )
          : const Center(child: CircularProgressIndicator(color: Colors.orange)),
      const FriendsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('Loading Austin Food Club...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true, // This is crucial for glass effect
      floatingActionButton: null, // Remove any existing FAB
      bottomNavigationBar: null, // Remove traditional bottom bar
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Floating circular navigation with scroll-based opacity
          Positioned(
            bottom: 30 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _currentIndex == 0 ? _bottomNavOpacity : 1.0, // Only fade on restaurant screen
              duration: const Duration(milliseconds: 200),
              child: _buildFloatingCircularNav(),
            ),
          ),
          // API Status Indicator - moved to top
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const ApiStatusIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}