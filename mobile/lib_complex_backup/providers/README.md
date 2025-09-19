# Provider Architecture Documentation

This document describes the Provider-based state management architecture for the Austin Food Club Flutter app.

## Overview

The app uses a centralized state management approach with multiple specialized providers that handle different aspects of the application state:

- **AuthProvider**: Handles authentication, user sessions, and profile management
- **RestaurantProvider**: Manages restaurant data, wishlist, and search functionality
- **RSVPProvider**: Handles RSVP creation, cancellation, and count tracking
- **UserProvider**: Manages user-specific data and verified visits
- **AppProvider**: Coordinates all providers and manages global state

## Provider Structure

### AuthProvider

Manages user authentication and session state.

#### State
- `User? currentUser` - Currently authenticated user
- `bool isLoading` - Loading state for auth operations
- `String? error` - Error messages from auth operations
- `bool isInitialized` - Whether the provider has been initialized

#### Key Methods
- `signIn(String phoneNumber)` - Send OTP to phone number
- `verifyOTP(String otp)` - Verify OTP and complete sign-in
- `signInWithEmail(String email, String password)` - Email authentication
- `signUpWithEmail(String email, String password)` - Email registration
- `signOut()` - Sign out current user
- `updateProfile(Map<String, dynamic> updates)` - Update user profile
- `uploadAvatar(String filePath)` - Upload user avatar
- `authenticateWithBiometrics()` - Biometric authentication
- `enableBiometricAuth()` - Enable biometric authentication
- `disableBiometricAuth()` - Disable biometric authentication

#### Usage Example
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (authProvider.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (authProvider.isAuthenticated) {
      return Text('Welcome, ${authProvider.currentUser?.name}!');
    }
    
    return LoginForm();
  },
)
```

### RestaurantProvider

Manages restaurant data and wishlist functionality.

#### State
- `Restaurant? currentRestaurant` - Currently featured restaurant
- `List<Restaurant> allRestaurants` - All available restaurants
- `List<Restaurant> wishlist` - User's wishlist
- `bool isLoading` - Loading state
- `String? error` - Error messages

#### Key Methods
- `fetchCurrentRestaurant()` - Fetch featured restaurant
- `fetchAllRestaurants()` - Fetch all restaurants
- `fetchWishlist()` - Fetch user's wishlist
- `toggleWishlist(String restaurantId)` - Add/remove from wishlist
- `isInWishlist(String restaurantId)` - Check if restaurant is in wishlist
- `searchRestaurants(String query)` - Search restaurants
- `getRestaurantsByArea(String area)` - Filter by area
- `getRestaurantsByPriceRange(int min, int max)` - Filter by price

#### Usage Example
```dart
Consumer<RestaurantProvider>(
  builder: (context, restaurantProvider, child) {
    return ListView.builder(
      itemCount: restaurantProvider.allRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = restaurantProvider.allRestaurants[index];
        return ListTile(
          title: Text(restaurant.name),
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
)
```

### RSVPProvider

Handles RSVP management and count tracking.

#### State
- `List<RSVP> userRSVPs` - User's RSVPs
- `Map<String, int> rsvpCounts` - RSVP counts by day
- `String? selectedDay` - Currently selected day
- `bool isLoading` - Loading state
- `String? error` - Error messages

#### Key Methods
- `createRSVP(String restaurantId, String day)` - Create new RSVP
- `cancelRSVP(String rsvpId)` - Cancel existing RSVP
- `fetchUserRSVPs()` - Fetch user's RSVPs
- `fetchRSVPCounts(String restaurantId)` - Fetch counts for restaurant
- `getRSVPCount(String day)` - Get count for specific day
- `hasRSVPForDay(String restaurantId, String day)` - Check if user has RSVP
- `getRSVPForDay(String restaurantId, String day)` - Get specific RSVP

#### Usage Example
```dart
Consumer<RSVPProvider>(
  builder: (context, rsvpProvider, child) {
    return Column(
      children: [
        // RSVP Counts
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((day) {
            return Expanded(
              child: Column(
                children: [
                  Text(day),
                  Text('${rsvpProvider.getRSVPCount(day)}'),
                ],
              ),
            );
          }).toList(),
        ),
        
        // RSVP Button
        ElevatedButton(
          onPressed: () => rsvpProvider.createRSVP(restaurantId, 'Monday'),
          child: Text('RSVP for Monday'),
        ),
      ],
    );
  },
)
```

### UserProvider

Manages user-specific data and verified visits.

#### State
- `User? currentUser` - Current user data
- `List<VerifiedVisit> verifiedVisits` - User's verified visits
- `bool isLoading` - Loading state
- `String? error` - Error messages

#### Key Methods
- `fetchUserProfile()` - Fetch user profile
- `fetchVerifiedVisits()` - Fetch verified visits
- `submitVerification(...)` - Submit new verification
- `deleteVerification(String visitId)` - Delete verification
- `getUserStats()` - Get user statistics
- `getVerifiedVisitsByRestaurant(String restaurantId)` - Filter by restaurant
- `getVerifiedVisitsByRating(int rating)` - Filter by rating

#### Usage Example
```dart
Consumer<UserProvider>(
  builder: (context, userProvider, child) {
    final stats = userProvider.getUserStats();
    
    return Column(
      children: [
        Text('Total Visits: ${stats['totalVisits']}'),
        Text('Average Rating: ${stats['averageRating']?.toStringAsFixed(1)}'),
        
        ListView.builder(
          itemCount: userProvider.verifiedVisits.length,
          itemBuilder: (context, index) {
            final visit = userProvider.verifiedVisits[index];
            return ListTile(
              title: Text(visit.restaurant?.name ?? 'Unknown'),
              subtitle: Text('Rating: ${visit.rating}/5'),
            );
          },
        ),
      ],
    );
  },
)
```

### AppProvider

Coordinates all providers and manages global state.

#### State
- `bool isInitialized` - Whether all providers are initialized
- `String? globalError` - Global error messages

#### Key Methods
- `initialize()` - Initialize all providers
- `refreshAll()` - Refresh all provider data
- `clearAllErrors()` - Clear all errors
- `getAllErrors()` - Get all error messages

#### Usage Example
```dart
Consumer<AppProvider>(
  builder: (context, appProvider, child) {
    if (!appProvider.isInitialized) {
      return CircularProgressIndicator();
    }
    
    if (appProvider.hasAnyError) {
      return ErrorWidget(appProvider.getAllErrors());
    }
    
    return MainAppContent();
  },
)
```

## Error Handling

All providers include comprehensive error handling:

1. **Loading States**: Each provider tracks loading state for operations
2. **Error Messages**: Detailed error messages for failed operations
3. **Error Clearing**: Methods to clear errors after handling
4. **Global Error Management**: AppProvider coordinates error handling across all providers

### Error Handling Example
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return Column(
      children: [
        if (authProvider.error != null)
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.red.shade100,
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                Expanded(child: Text(authProvider.error!)),
                IconButton(
                  onPressed: () => authProvider.clearError(),
                  icon: Icon(Icons.close),
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
          child: Text('Sign In'),
        ),
      ],
    );
  },
)
```

## Loading States

All providers track loading states for better UX:

```dart
Consumer<RestaurantProvider>(
  builder: (context, restaurantProvider, child) {
    return Stack(
      children: [
        // Main content
        ListView.builder(
          itemCount: restaurantProvider.allRestaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurantProvider.allRestaurants[index];
            return ListTile(title: Text(restaurant.name));
          },
        ),
        
        // Loading overlay
        if (restaurantProvider.isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  },
)
```

## Best Practices

1. **Use Consumer Widgets**: Always wrap UI that needs provider data with Consumer widgets
2. **Handle Loading States**: Always check loading states before showing data
3. **Handle Errors**: Display error messages and provide ways to clear them
4. **Initialize Providers**: Ensure providers are initialized before use
5. **Dispose Properly**: Providers automatically dispose of resources
6. **Use Specific Providers**: Use the most specific provider for your needs
7. **Combine Providers**: Use Consumer2, Consumer3, etc. for multiple providers

## Provider Lifecycle

1. **Initialization**: Providers are initialized when the app starts
2. **State Updates**: Providers notify listeners when state changes
3. **Disposal**: Providers are automatically disposed when no longer needed
4. **Error Recovery**: Providers can recover from errors and continue operation

## Testing

Providers can be easily tested by mocking the underlying services:

```dart
testWidgets('AuthProvider test', (WidgetTester tester) async {
  final mockAuthService = MockAuthService();
  final authProvider = AuthProvider();
  
  // Test authentication flow
  await authProvider.signIn('+1234567890');
  expect(authProvider.isLoading, true);
  
  await authProvider.verifyOTP('123456');
  expect(authProvider.isAuthenticated, true);
});
```

This architecture provides a clean, maintainable, and testable state management solution for the Austin Food Club app.

