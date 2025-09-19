import 'package:flutter/material.dart';
import 'restaurant_screen.dart';
import 'profile_screen.dart';
import 'friends_screen.dart';
import '../models/restaurant.dart';
import '../services/mock_data_service.dart';
import '../widgets/api_status_indicator.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  Restaurant? featuredRestaurant;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedRestaurant();
  }

  Future<void> _loadFeaturedRestaurant() async {
    try {
      final restaurant = await MockDataService.getFeaturedRestaurant();
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
    });
  }

  List<Widget> get _screens {
    return [
      featuredRestaurant != null 
          ? RestaurantScreen(restaurant: featuredRestaurant!)
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(
            top: BorderSide(
              color: Colors.grey[700]!,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // API Status Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  ApiStatusIndicator(),
                  Spacer(),
                ],
              ),
            ),
            BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.orange,
              unselectedItemColor: Colors.grey[400],
              selectedFontSize: 12,
              unselectedFontSize: 12,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant),
                  activeIcon: Icon(Icons.restaurant, size: 28),
                  label: 'This Week',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people, size: 28),
                  label: 'Friends',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person, size: 28),
                  label: 'Profile',
                ),
              ],
        ),
          ],
        ),
      ),
    );
  }
}
