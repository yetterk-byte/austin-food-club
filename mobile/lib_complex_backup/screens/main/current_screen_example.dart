// Current Screen Usage Examples
// This file demonstrates how to use the CurrentScreen and its components

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'current_screen.dart';
import '../../providers/app_provider.dart';
import '../../widgets/restaurant/restaurant_hero.dart';
import '../../widgets/restaurant/rsvp_section.dart';
import '../../widgets/restaurant/restaurant_details.dart';
import '../../widgets/restaurant/rsvp_bottom_sheet.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_widget.dart';

class CurrentScreenExamples {
  // Example 1: Basic Current Screen Usage
  static Widget buildBasicExample() {
    return const CurrentScreen();
  }

  // Example 2: Current Screen with Custom App Bar
  static Widget buildCustomAppBarExample() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Featured Restaurant'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Handle share
            },
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: () {
              // Handle favorite
            },
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: const CurrentScreen(),
    );
  }

  // Example 3: Current Screen with Bottom Navigation
  static Widget buildWithBottomNavExample() {
    return Scaffold(
      body: const CurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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

  // Example 4: Restaurant Hero Widget Usage
  static Widget buildRestaurantHeroExample() {
    // Mock restaurant data
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imageUrl: 'https://example.com/restaurant.jpg',
      cuisineType: 'BBQ',
      description: 'Award-winning barbecue in the heart of Austin.',
      specialties: ['Brisket', 'Ribs', 'Sausage'],
      isFeatured: true,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: RestaurantHero(
                restaurant: restaurant,
                parallaxValue: 0.5, // Example parallax value
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Restaurant content goes here'),
            ),
          ),
        ],
      ),
    );
  }

  // Example 5: RSVP Section Widget Usage
  static Widget buildRSVPSectionExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Restaurant info
            Container(
              height: 200,
              color: Colors.grey.shade300,
              child: const Center(
                child: Text('Restaurant Image'),
              ),
            ),
            
            // RSVP Section
            RSVPSection(
              restaurant: restaurant,
              onRSVP: (day, status) {
                print('RSVP: $day - $status');
              },
              onShowDetails: (day) {
                print('Show details for: $day');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Example 6: Restaurant Details Widget Usage
  static Widget buildRestaurantDetailsExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: 'Franklin Barbecue is a barbecue restaurant in Austin, Texas, owned by Aaron Franklin. The restaurant is known for its brisket, which has been praised by food critics and barbecue enthusiasts. Franklin Barbecue has been featured in numerous publications and television shows, and has won several awards for its barbecue.',
      specialties: ['Brisket', 'Ribs', 'Sausage', 'Turkey', 'Pork Shoulder'],
      cuisineType: 'BBQ',
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Restaurant hero
            Container(
              height: 200,
              color: Colors.grey.shade300,
              child: const Center(
                child: Text('Restaurant Image'),
              ),
            ),
            
            // Restaurant details
            RestaurantDetails(
              restaurant: restaurant,
              onReadMore: () {
                print('Read more clicked');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Example 7: RSVP Bottom Sheet Usage
  static Widget buildRSVPBottomSheetExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => RSVPBottomSheet(
                restaurant: restaurant,
                day: 'Monday',
                rsvpCount: 15,
                onAddToCalendar: () {
                  print('Add to calendar');
                },
                onSetReminder: () {
                  print('Set reminder');
                },
              ),
            );
          },
          child: const Text('Show RSVP Bottom Sheet'),
        ),
      ),
    );
  }

  // Example 8: Loading States
  static Widget buildLoadingStatesExample() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Loading hero
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: LoadingShimmer(
              child: Container(
                height: 300,
                color: Colors.grey.shade300,
              ),
            ),
          ),
          
          // Loading content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                LoadingShimmer(
                  child: Container(
                    height: 20,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                LoadingShimmer(
                  child: Container(
                    height: 16,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                LoadingShimmer(
                  child: Container(
                    height: 100,
                    color: Colors.grey.shade300,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Example 9: Error States
  static Widget buildErrorStatesExample() {
    return Scaffold(
      body: Column(
        children: [
          // Network error
          Expanded(
            child: NetworkErrorWidget(
              onRetry: () {
                print('Retry network request');
              },
            ),
          ),
          
          // Server error
          Expanded(
            child: ServerErrorWidget(
              onRetry: () {
                print('Retry server request');
              },
            ),
          ),
          
          // Not found error
          Expanded(
            child: NotFoundErrorWidget(
              itemName: 'Restaurant',
              onRetry: () {
                print('Retry search');
              },
            ),
          ),
        ],
      ),
    );
  }

  // Example 10: Complete Integration
  static Widget buildCompleteIntegrationExample() {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Current Screen Example',
            theme: ThemeData(
              primarySwatch: Colors.orange,
              useMaterial3: true,
            ),
            home: const CurrentScreen(),
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
}

// Example App
class CurrentScreenExampleApp extends StatelessWidget {
  const CurrentScreenExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Current Screen Examples',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const CurrentScreen(),
    );
  }
}

