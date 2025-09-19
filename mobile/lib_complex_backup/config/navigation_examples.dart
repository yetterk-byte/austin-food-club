// Navigation System Usage Examples
// This file demonstrates how to use the navigation system

import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

class NavigationExamples {
  // Basic navigation examples
  static void basicNavigationExamples() {
    // Navigate to different screens
    NavigationService.goToCurrent();
    NavigationService.goToDiscover();
    NavigationService.goToWishlist();
    NavigationService.goToProfile();
    
    // Navigate to auth screens
    NavigationService.goToAuth();
    NavigationService.goToAuthVerify(phoneNumber: '+1234567890');
    
    // Navigate with parameters
    NavigationService.goToRestaurantDetails(restaurantId: 'restaurant_123');
    
    // Push navigation (with back button)
    NavigationService.pushRestaurantDetails(restaurantId: 'restaurant_123');
    NavigationService.pushVerifyVisit(
      rsvpId: 'rsvp_123',
      restaurantName: 'Franklin Barbecue',
      visitDate: DateTime.now(),
    );
  }

  // Navigation with results
  static Future<void> navigationWithResultsExamples() async {
    // Push screen and wait for result
    final result = await NavigationService.pushRestaurantDetails<bool>(
      restaurantId: 'restaurant_123',
    );
    
    if (result == true) {
      print('User liked the restaurant');
    }
    
    // Push verification screen and handle result
    final verificationResult = await NavigationService.pushVerifyVisit<Map<String, dynamic>>(
      rsvpId: 'rsvp_123',
      restaurantName: 'Franklin Barbecue',
      visitDate: DateTime.now(),
    );
    
    if (verificationResult != null) {
      print('Verification completed: $verificationResult');
    }
  }

  // Modal and dialog examples
  static Future<void> modalExamples(BuildContext context) async {
    // Show bottom sheet modal
    await NavigationService.showModal(
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select an option'),
            ListTile(
              title: const Text('Option 1'),
              onTap: () => NavigationService.pop('option1'),
            ),
            ListTile(
              title: const Text('Option 2'),
              onTap: () => NavigationService.pop('option2'),
            ),
          ],
        ),
      ),
    );
    
    // Show full screen modal
    await NavigationService.showFullScreenModal(
      Scaffold(
        appBar: AppBar(
          title: const Text('Full Screen Modal'),
          leading: IconButton(
            onPressed: () => NavigationService.pop(),
            icon: const Icon(Icons.close),
          ),
        ),
        body: const Center(
          child: Text('Full screen content'),
        ),
      ),
    );
    
    // Show dialog
    await NavigationService.showDialog(
      AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => NavigationService.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => NavigationService.pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Deep link handling examples
  static Future<void> deepLinkExamples() async {
    // Handle restaurant deep link
    await NavigationService.handleDeepLink('https://app.austinfoodclub.com/restaurant/123');
    
    // Handle verification deep link
    await NavigationService.handleDeepLink(
      'https://app.austinfoodclub.com/verify-visit/rsvp_123?restaurant=Franklin%20Barbecue&date=2023-12-01T18:00:00Z',
    );
    
    // Handle profile deep link
    await NavigationService.handleDeepLink('https://app.austinfoodclub.com/profile');
  }

  // Utility examples
  static void utilityExamples() {
    // Check if can go back
    if (NavigationService.canPop()) {
      NavigationService.pop();
    }
    
    // Get current location
    final currentLocation = NavigationService.getCurrentLocation();
    print('Current location: $currentLocation');
    
    // Get path parameters
    final pathParams = NavigationService.getCurrentPathParameters();
    print('Path parameters: $pathParams');
    
    // Get query parameters
    final queryParams = NavigationService.getCurrentQueryParameters();
    print('Query parameters: $queryParams');
    
    // Clear navigation stack and go to specific route
    NavigationService.clearAndNavigateTo('/main/current');
  }

  // Bottom navigation examples
  static void bottomNavigationExamples() {
    // Switch to specific tab by index
    NavigationService.switchToTab(0); // Current
    NavigationService.switchToTab(1); // Discover
    NavigationService.switchToTab(2); // Wishlist
    NavigationService.switchToTab(3); // Profile
    
    // Get current tab index
    final currentTab = NavigationService.getCurrentTabIndex('/main/current');
    print('Current tab: $currentTab');
  }
}

// Example widget showing navigation usage
class NavigationExampleWidget extends StatelessWidget {
  const NavigationExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic navigation
          _buildSection(
            'Basic Navigation',
            [
              ElevatedButton(
                onPressed: () => NavigationService.goToCurrent(),
                child: const Text('Go to Current'),
              ),
              ElevatedButton(
                onPressed: () => NavigationService.goToDiscover(),
                child: const Text('Go to Discover'),
              ),
              ElevatedButton(
                onPressed: () => NavigationService.goToWishlist(),
                child: const Text('Go to Wishlist'),
              ),
              ElevatedButton(
                onPressed: () => NavigationService.goToProfile(),
                child: const Text('Go to Profile'),
              ),
            ],
          ),
          
          // Push navigation
          _buildSection(
            'Push Navigation',
            [
              ElevatedButton(
                onPressed: () => NavigationService.pushRestaurantDetails(
                  restaurantId: 'restaurant_123',
                ),
                child: const Text('Push Restaurant Details'),
              ),
              ElevatedButton(
                onPressed: () => NavigationService.pushVerifyVisit(
                  rsvpId: 'rsvp_123',
                  restaurantName: 'Franklin Barbecue',
                  visitDate: DateTime.now(),
                ),
                child: const Text('Push Verify Visit'),
              ),
            ],
          ),
          
          // Modals and dialogs
          _buildSection(
            'Modals & Dialogs',
            [
              ElevatedButton(
                onPressed: () => _showBottomModal(),
                child: const Text('Show Bottom Modal'),
              ),
              ElevatedButton(
                onPressed: () => _showFullScreenModal(),
                child: const Text('Show Full Screen Modal'),
              ),
              ElevatedButton(
                onPressed: () => _showAlertDialog(),
                child: const Text('Show Alert Dialog'),
              ),
            ],
          ),
          
          // Utilities
          _buildSection(
            'Utilities',
            [
              ElevatedButton(
                onPressed: () {
                  final location = NavigationService.getCurrentLocation();
                  _showSnackBar('Current location: $location');
                },
                child: const Text('Get Current Location'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (NavigationService.canPop()) {
                    NavigationService.pop();
                  } else {
                    _showSnackBar('Cannot go back');
                  }
                },
                child: const Text('Go Back'),
              ),
              ElevatedButton(
                onPressed: () => NavigationService.clearAndNavigateTo('/main/current'),
                child: const Text('Clear Stack & Go Home'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: child,
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _showBottomModal() async {
    final result = await NavigationService.showModal<String>(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select an option',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Option 1'),
              onTap: () => NavigationService.pop('option1'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Option 2'),
              onTap: () => NavigationService.pop('option2'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Option 3'),
              onTap: () => NavigationService.pop('option3'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _showSnackBar('Selected: $result');
    }
  }

  Future<void> _showFullScreenModal() async {
    await NavigationService.showFullScreenModal(
      Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Full Screen Modal'),
          backgroundColor: Colors.orange,
          leading: IconButton(
            onPressed: () => NavigationService.pop(),
            icon: const Icon(Icons.close),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant,
                size: 64,
                color: Colors.orange,
              ),
              SizedBox(height: 16),
              Text(
                'Full Screen Modal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This is a full screen modal example',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAlertDialog() async {
    final result = await NavigationService.showDialog<bool>(
      AlertDialog(
        title: const Text('Confirm Action'),
        content: const Text('Are you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => NavigationService.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => NavigationService.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result == true) {
      _showSnackBar('Action confirmed');
    } else {
      _showSnackBar('Action cancelled');
    }
  }

  void _showSnackBar(String message) {
    final context = NavigationService.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

