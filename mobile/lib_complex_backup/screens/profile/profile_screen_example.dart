// Profile Screen Usage Examples
// This file demonstrates how to use the ProfileScreen and its components

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_screen.dart';
import '../../providers/app_provider.dart';
import '../../widgets/profile/user_header.dart';
import '../../widgets/profile/upcoming_rsvps.dart';
import '../../widgets/profile/verified_visits.dart';
import '../../widgets/profile/settings_section.dart';
import '../../widgets/profile/achievements_section.dart';
import '../../models/user.dart';
import '../../models/rsvp.dart';
import '../../models/verified_visit.dart';

class ProfileScreenExamples {
  // Example 1: Basic Profile Screen Usage
  static Widget buildBasicExample() {
    return const ProfileScreen();
  }

  // Example 2: Profile Screen with Custom App Bar
  static Widget buildCustomAppBarExample() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Handle settings
            },
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () {
              // Handle share
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: const ProfileScreen(),
    );
  }

  // Example 3: User Header Widget Usage
  static Widget buildUserHeaderExample() {
    // Mock user data
    final user = User(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      phoneNumber: '+1234567890',
      avatarUrl: 'https://example.com/avatar.jpg',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      totalVisits: 15,
      averageRating: 4.2,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: UserHeader(
                user: user,
                onEditProfile: () {
                  print('Edit profile');
                },
                onEditAvatar: () {
                  print('Edit avatar');
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Profile content goes here'),
            ),
          ),
        ],
      ),
    );
  }

  // Example 4: Upcoming RSVPs Widget Usage
  static Widget buildUpcomingRSVPsExample() {
    // Mock RSVP data
    final rsvps = [
      RSVP(
        id: '1',
        userId: '1',
        restaurantId: '1',
        day: 'Monday',
        status: 'going',
        createdAt: DateTime.now().add(const Duration(days: 1)),
        restaurant: Restaurant(
          id: '1',
          name: 'Franklin Barbecue',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      RSVP(
        id: '2',
        userId: '1',
        restaurantId: '2',
        day: 'Wednesday',
        status: 'going',
        createdAt: DateTime.now().add(const Duration(days: 3)),
        restaurant: Restaurant(
          id: '2',
          name: 'Uchi',
          address: '801 S Lamar Blvd, Austin, TX 78704',
          area: 'South Austin',
          price: 4,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User header
            Container(
              height: 200,
              color: Colors.orange.shade100,
              child: const Center(
                child: Text('User Header'),
              ),
            ),
            
            // Upcoming RSVPs
            UpcomingRSVPs(
              rsvps: rsvps,
              onVerifyVisit: (rsvp) {
                print('Verify visit: ${rsvp.id}');
              },
              onCancelRSVP: (rsvpId) {
                print('Cancel RSVP: $rsvpId');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Example 5: Verified Visits Widget Usage
  static Widget buildVerifiedVisitsExample() {
    // Mock verified visits data
    final visits = [
      VerifiedVisit(
        id: '1',
        userId: '1',
        restaurantId: '1',
        photoUrl: 'https://example.com/photo1.jpg',
        rating: 5,
        review: 'Amazing barbecue!',
        visitDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        restaurant: Restaurant(
          id: '1',
          name: 'Franklin Barbecue',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      VerifiedVisit(
        id: '2',
        userId: '1',
        restaurantId: '2',
        photoUrl: 'https://example.com/photo2.jpg',
        rating: 4,
        review: 'Great sushi!',
        visitDate: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        restaurant: Restaurant(
          id: '2',
          name: 'Uchi',
          address: '801 S Lamar Blvd, Austin, TX 78704',
          area: 'South Austin',
          price: 4,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User header
            Container(
              height: 200,
              color: Colors.orange.shade100,
              child: const Center(
                child: Text('User Header'),
              ),
            ),
            
            // Verified Visits
            VerifiedVisits(
              visits: visits,
              isGridView: true,
              sortBy: 'date',
              onToggleView: () {
                print('Toggle view');
              },
              onSortChanged: (sortBy) {
                print('Sort changed: $sortBy');
              },
              onVisitTapped: (visit) {
                print('Visit tapped: ${visit.id}');
              },
              onLoadMore: () {
                print('Load more visits');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Example 6: Settings Section Widget Usage
  static Widget buildSettingsSectionExample() {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SettingsSection(
                onSignOut: () {
                  print('Sign out');
                },
                onNotificationSettings: () {
                  print('Notification settings');
                },
                onPrivacySettings: () {
                  print('Privacy settings');
                },
                onAccountManagement: () {
                  print('Account management');
                },
              ),
            );
          },
          child: const Text('Show Settings'),
        ),
      ),
    );
  }

  // Example 7: Achievements Section Widget Usage
  static Widget buildAchievementsSectionExample() {
    // Mock user and visits data
    final user = User(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      totalVisits: 15,
      averageRating: 4.2,
    );

    final visits = [
      VerifiedVisit(
        id: '1',
        userId: '1',
        restaurantId: '1',
        photoUrl: 'https://example.com/photo1.jpg',
        rating: 5,
        visitDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      // Add more visits...
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User header
            Container(
              height: 200,
              color: Colors.orange.shade100,
              child: const Center(
                child: Text('User Header'),
              ),
            ),
            
            // Achievements Section
            AchievementsSection(
              user: user,
              visits: visits,
            ),
          ],
        ),
      ),
    );
  }

  // Example 8: Complete Profile Screen with Provider
  static Widget buildCompleteExample() {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Profile Screen Example',
            theme: ThemeData(
              primarySwatch: Colors.orange,
              useMaterial3: true,
            ),
            home: const ProfileScreen(),
            builder: (context, child) {
              // Initialize providers when app starts
              WidgetsBinding.instance.addPostFrameCallback((_) {
                appProvider.initialize();
              });
              return child!;
            },
          );
        },
      ),
    );
  }

  // Example 9: Profile Screen with Custom Navigation
  static Widget buildWithNavigationExample() {
    return Scaffold(
      body: const ProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Profile tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Current',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Example 10: Profile Screen with Floating Action Button
  static Widget buildWithFABExample() {
    return Scaffold(
      body: const ProfileScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Quick action');
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Example App
class ProfileScreenExampleApp extends StatelessWidget {
  const ProfileScreenExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Screen Examples',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const ProfileScreen(),
    );
  }
}

