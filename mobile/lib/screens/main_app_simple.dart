import 'package:flutter/material.dart';
import 'restaurant_screen.dart';
import 'profile_screen.dart';
import 'friends_screen.dart';
import '../models/restaurant.dart';
import '../services/mock_data_service.dart';

class MainAppSimple extends StatefulWidget {
  const MainAppSimple({super.key});

  @override
  State<MainAppSimple> createState() => _MainAppSimpleState();
}

class _MainAppSimpleState extends State<MainAppSimple> {
  int _currentIndex = 0;

  List<Widget> get _screens {
    return [
      RestaurantScreen(restaurant: MockDataService.getFeaturedRestaurantMock()),
      const FriendsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
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
    );
  }
}
