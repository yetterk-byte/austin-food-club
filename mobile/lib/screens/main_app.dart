import 'package:flutter/material.dart';
import 'dart:ui';
import 'restaurant_screen.dart';
import 'profile_screen.dart';
import 'friends_screen.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../widgets/api_status_indicator.dart';
import '../config/feature_flags.dart';

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
  double _bottomNavOpacity = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedRestaurant();
  }

  Future<void> _loadFeaturedRestaurant() async {
    try {
      final restaurant = await RestaurantService.getFeaturedRestaurant();
      if (!mounted) return;
      setState(() {
        featuredRestaurant = restaurant;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 0) {
        _bottomNavOpacity = 1.0;
      }
    });
  }

  void _updateBottomNavOpacity(double opacity) {
    if (_bottomNavOpacity != opacity) {
      setState(() {
        _bottomNavOpacity = opacity;
      });
    }
  }

  Widget _buildFloatingCircularNav() {
    final List<NavItem> navItems = [];
    navItems.add(NavItem(icon: Icons.restaurant, activeIcon: Icons.restaurant, label: 'This Week', index: 0));
    if (FeatureFlags.enableFriends) {
      navItems.add(NavItem(icon: Icons.groups_rounded, activeIcon: Icons.groups, label: 'Friends', index: navItems.length));
    }
    navItems.add(NavItem(icon: Icons.account_circle_rounded, activeIcon: Icons.account_circle, label: 'Profile', index: navItems.length));

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
                    ? Colors.orange.withOpacity(0.25)
                    : Colors.black.withOpacity(0.2),
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
                  item.icon,
                  color: Colors.white,
                  size: isSelected ? 26 : 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> get _screens {
    final bool hasRestaurant = featuredRestaurant != null;
    final List<Widget> screens = [];
    screens.add(
      hasRestaurant
          ? RestaurantScreen(
              restaurant: featuredRestaurant!,
              onScrollOpacityChanged: _currentIndex == 0 ? _updateBottomNavOpacity : null,
            )
          : _buildRestaurantUnavailable(),
    );
    if (FeatureFlags.enableFriends) {
      screens.add(const FriendsScreen());
    }
    screens.add(const ProfileScreen());
    return screens;
  }

  Widget _buildRestaurantUnavailable() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                "Featured restaurant unavailable",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "We couldn't load this week's restaurant from Yelp. Please try again shortly.",
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFeaturedRestaurant,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      floatingActionButton: null,
      bottomNavigationBar: null,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 30 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: (_currentIndex == 0 && featuredRestaurant != null) ? _bottomNavOpacity : 1.0,
              duration: const Duration(milliseconds: 200),
              child: _buildFloatingCircularNav(),
            ),
          ),
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