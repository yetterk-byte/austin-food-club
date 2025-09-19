// Provider Usage Examples
// This file demonstrates how to use the Provider architecture

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'auth_provider.dart';
import 'restaurant_provider.dart';
import 'rsvp_provider.dart';
import 'user_provider.dart';

class ProviderExamples {
  // Example 1: Basic Provider Setup
  static Widget buildProviderExample() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => RSVPProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    );
  }

  // Example 2: Using AuthProvider
  static Widget buildAuthExample() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const CircularProgressIndicator();
        }

        if (authProvider.error != null) {
          return Text('Error: ${authProvider.error}');
        }

        if (authProvider.isAuthenticated) {
          return Text('Welcome, ${authProvider.currentUser?.name}!');
        }

        return const Text('Please sign in');
      },
    );
  }

  // Example 3: Using RestaurantProvider
  static Widget buildRestaurantExample() {
    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, child) {
        if (restaurantProvider.isLoading) {
          return const CircularProgressIndicator();
        }

        if (restaurantProvider.error != null) {
          return Text('Error: ${restaurantProvider.error}');
        }

        return ListView.builder(
          itemCount: restaurantProvider.allRestaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurantProvider.allRestaurants[index];
            return ListTile(
              title: Text(restaurant.name),
              subtitle: Text(restaurant.area),
              trailing: IconButton(
                icon: Icon(
                  restaurantProvider.isInWishlist(restaurant.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                onPressed: () => restaurantProvider.toggleWishlist(restaurant.id),
              ),
            );
          },
        );
      },
    );
  }

  // Example 4: Using RSVPProvider
  static Widget buildRSVPExample() {
    return Consumer<RSVPProvider>(
      builder: (context, rsvpProvider, child) {
        if (rsvpProvider.isLoading) {
          return const CircularProgressIndicator();
        }

        if (rsvpProvider.error != null) {
          return Text('Error: ${rsvpProvider.error}');
        }

        return Column(
          children: [
            // RSVP Counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
                  .map((day) => Column(
                        children: [
                          Text(day),
                          Text('${rsvpProvider.getRSVPCount(day)}'),
                        ],
                      ))
                  .toList(),
            ),
            
            // User RSVPs
            Expanded(
              child: ListView.builder(
                itemCount: rsvpProvider.userRSVPs.length,
                itemBuilder: (context, index) {
                  final rsvp = rsvpProvider.userRSVPs[index];
                  return ListTile(
                    title: Text('RSVP for ${rsvp.day}'),
                    subtitle: Text('Status: ${rsvp.status}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () => rsvpProvider.cancelRSVP(rsvp.id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Example 5: Using UserProvider
  static Widget buildUserExample() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const CircularProgressIndicator();
        }

        if (userProvider.error != null) {
          return Text('Error: ${userProvider.error}');
        }

        final stats = userProvider.getUserStats();
        
        return Column(
          children: [
            // User Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Visits: ${stats['totalVisits']}'),
                    Text('Average Rating: ${stats['averageRating']?.toStringAsFixed(1)}'),
                    Text('This Month: ${stats['thisMonthVisits']}'),
                    Text('Favorite Cuisine: ${stats['favoriteCuisine']}'),
                  ],
                ),
              ),
            ),
            
            // Verified Visits
            Expanded(
              child: ListView.builder(
                itemCount: userProvider.verifiedVisits.length,
                itemBuilder: (context, index) {
                  final visit = userProvider.verifiedVisits[index];
                  return ListTile(
                    title: Text(visit.restaurant?.name ?? 'Unknown Restaurant'),
                    subtitle: Text('Rating: ${visit.rating}/5'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => userProvider.deleteVerification(visit.id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Example 6: Using AppProvider (Coordinated)
  static Widget buildAppExample() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (!appProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (appProvider.hasAnyError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Errors occurred:'),
                  ...appProvider.getAllErrors().map((error) => Text(error)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => appProvider.clearAllErrors(),
                    child: const Text('Clear Errors'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Austin Food Club'),
            actions: [
              if (appProvider.isAnyLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: const Center(
            child: Text('App is ready!'),
          ),
        );
      },
    );
  }

  // Example 7: Error Handling
  static Widget buildErrorHandlingExample() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            if (authProvider.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(authProvider.error!)),
                    IconButton(
                      onPressed: () => authProvider.clearError(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            
            ElevatedButton(
              onPressed: () async {
                try {
                  await authProvider.signIn('+1234567890');
                } catch (e) {
                  // Error is automatically handled by the provider
                }
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }

  // Example 8: Loading States
  static Widget buildLoadingExample() {
    return Consumer<RestaurantProvider>(
      builder: (context, restaurantProvider, child) {
        return Stack(
          children: [
            // Main content
            ListView.builder(
              itemCount: restaurantProvider.allRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurantProvider.allRestaurants[index];
                return ListTile(
                  title: Text(restaurant.name),
                  subtitle: Text(restaurant.area),
                );
              },
            ),
            
            // Loading overlay
            if (restaurantProvider.isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  // Example 9: Combined Provider Usage
  static Widget buildCombinedExample() {
    return Consumer2<AuthProvider, RestaurantProvider>(
      builder: (context, authProvider, restaurantProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const Center(
            child: Text('Please sign in to view restaurants'),
          );
        }

        if (restaurantProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView.builder(
          itemCount: restaurantProvider.allRestaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurantProvider.allRestaurants[index];
            return Card(
              child: ListTile(
                title: Text(restaurant.name),
                subtitle: Text(restaurant.area),
                trailing: IconButton(
                  icon: Icon(
                    restaurantProvider.isInWishlist(restaurant.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  onPressed: () => restaurantProvider.toggleWishlist(restaurant.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Example 10: Provider Initialization
  static Future<void> initializeProviders(BuildContext context) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.initialize();
  }
}

// Example App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provider Examples',
      home: ProviderExamples.buildAppExample(),
    );
  }
}

