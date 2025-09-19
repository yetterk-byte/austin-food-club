import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:austin_food_club_flutter/providers/app_provider.dart';
import 'package:austin_food_club_flutter/providers/auth_provider.dart';
import 'package:austin_food_club_flutter/providers/restaurant_provider.dart';
import 'package:austin_food_club_flutter/providers/rsvp_provider.dart';
import 'package:austin_food_club_flutter/providers/user_provider.dart';
import 'package:austin_food_club_flutter/providers/social_provider.dart';
import 'package:austin_food_club_flutter/providers/offline_provider.dart';
import 'package:austin_food_club_flutter/models/restaurant.dart';
import 'package:austin_food_club_flutter/models/rsvp.dart';
import 'package:austin_food_club_flutter/models/verified_visit.dart';
import 'package:austin_food_club_flutter/models/user.dart';

class TestHelpers {
  // Create test app with providers
  static Widget createTestApp({
    Widget? home,
    bool isAuthenticated = false,
    List<Restaurant>? restaurants,
    List<RSVP>? rsvps,
    User? currentUser,
  }) {
    final appProvider = AppProvider();
    
    // Setup mock data if provided
    if (isAuthenticated && currentUser != null) {
      appProvider.auth.setAuthenticated(true);
      appProvider.auth.setCurrentUser(currentUser);
    }
    
    if (restaurants != null) {
      appProvider.restaurants.setAllRestaurants(restaurants);
      if (restaurants.isNotEmpty) {
        appProvider.restaurants.setCurrentRestaurant(restaurants.first);
      }
    }
    
    if (rsvps != null) {
      appProvider.rsvps.setUserRSVPs(rsvps);
    }

    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>(create: (_) => appProvider),
          ChangeNotifierProvider<AuthProvider>(create: (_) => appProvider.auth),
          ChangeNotifierProvider<RestaurantProvider>(create: (_) => appProvider.restaurants),
          ChangeNotifierProvider<RSVPProvider>(create: (_) => appProvider.rsvps),
          ChangeNotifierProvider<UserProvider>(create: (_) => appProvider.user),
          ChangeNotifierProvider<SocialProvider>(create: (_) => SocialProvider()),
          ChangeNotifierProvider<OfflineProvider>(create: (_) => appProvider.offline),
        ],
        child: home ?? const Scaffold(body: Text('Test App')),
      ),
    );
  }

  // Mock data generators
  static Restaurant createMockRestaurant({
    String? id,
    String? name,
    String? area,
    int? price,
  }) {
    return Restaurant(
      id: id ?? 'restaurant_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Mock Restaurant',
      address: '123 Test St, Austin, TX 78701',
      area: area ?? 'Downtown',
      price: price ?? 2,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static RSVP createMockRSVP({
    String? id,
    String? userId,
    String? restaurantId,
    String? day,
    RSVPStatus? status,
  }) {
    return RSVP(
      id: id ?? 'rsvp_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? 'user_123',
      restaurantId: restaurantId ?? 'restaurant_123',
      day: day ?? 'Monday',
      status: status ?? RSVPStatus.going,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static VerifiedVisit createMockVerifiedVisit({
    String? id,
    String? userId,
    String? restaurantId,
    int? rating,
    String? review,
  }) {
    return VerifiedVisit(
      id: id ?? 'visit_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? 'user_123',
      restaurantId: restaurantId ?? 'restaurant_123',
      visitDate: DateTime.now(),
      rating: rating ?? 5,
      review: review,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static User createMockUser({
    String? id,
    String? name,
    String? email,
    String? phone,
  }) {
    return User(
      id: id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test User',
      email: email ?? 'test@example.com',
      phone: phone ?? '+15551234567',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Test utilities
  static Future<void> waitForAnimation(WidgetTester tester, {Duration? duration}) async {
    await tester.pump();
    await tester.pump(duration ?? const Duration(milliseconds: 300));
  }

  static Future<void> enterTextSlowly(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    for (int i = 0; i < text.length; i++) {
      await tester.enterText(finder, text.substring(0, i + 1));
      await tester.pump();
      await Future.delayed(delay);
    }
  }

  static Future<void> tapAndWait(
    WidgetTester tester,
    Finder finder, {
    Duration? delay,
  }) async {
    await tester.tap(finder);
    await tester.pump();
    if (delay != null) {
      await tester.pump(delay);
    }
  }

  // Verification helpers
  static void verifyWidgetExists(Finder finder, {int count = 1}) {
    if (count == 1) {
      expect(finder, findsOneWidget);
    } else {
      expect(finder, findsNWidgets(count));
    }
  }

  static void verifyWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  static void verifyTextExists(String text, {int count = 1}) {
    verifyWidgetExists(find.text(text), count: count);
  }

  static void verifyIconExists(IconData icon, {int count = 1}) {
    verifyWidgetExists(find.byIcon(icon), count: count);
  }

  // State verification helpers
  static void verifyLoadingState(WidgetTester tester) {
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
  }

  static void verifyErrorState(WidgetTester tester, String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  }

  static void verifyEmptyState(WidgetTester tester, String emptyMessage) {
    expect(find.text(emptyMessage), findsOneWidget);
  }

  // Navigation helpers
  static Future<void> navigateToTab(
    WidgetTester tester,
    String tabName,
  ) async {
    await tester.tap(find.text(tabName));
    await tester.pumpAndSettle();
  }

  static Future<void> navigateBack(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }

  // Form helpers
  static Future<void> fillForm(
    WidgetTester tester,
    Map<String, String> fieldValues,
  ) async {
    for (final entry in fieldValues.entries) {
      final finder = find.widgetWithText(TextField, entry.key);
      if (finder.evaluate().isNotEmpty) {
        await tester.enterText(finder, entry.value);
        await tester.pump();
      }
    }
  }

  static Future<void> submitForm(WidgetTester tester, String buttonText) async {
    await tester.tap(find.text(buttonText));
    await tester.pumpAndSettle();
  }

  // Mock network responses
  static Map<String, dynamic> createMockRestaurantResponse() {
    return {
      'restaurant': {
        'id': 'restaurant_123',
        'name': 'Franklin Barbecue',
        'description': 'Authentic Texas BBQ',
        'address': '900 E 11th St, Austin, TX 78702',
        'area': 'East Austin',
        'price': 3,
        'imageUrl': 'https://example.com/franklin.jpg',
        'cuisineType': 'BBQ',
        'phone': '+15124623300',
        'website': 'https://franklinbarbecue.com',
        'weekOf': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    };
  }

  static Map<String, dynamic> createMockRSVPResponse() {
    return {
      'rsvp': {
        'id': 'rsvp_123',
        'userId': 'user_123',
        'restaurantId': 'restaurant_123',
        'day': 'Monday',
        'status': 'going',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    };
  }

  static Map<String, dynamic> createMockVerifiedVisitResponse() {
    return {
      'visit': {
        'id': 'visit_123',
        'userId': 'user_123',
        'restaurantId': 'restaurant_123',
        'visitDate': DateTime.now().toIso8601String(),
        'rating': 5,
        'review': 'Amazing food and great service!',
        'photoUrl': 'https://example.com/visit_photo.jpg',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }
    };
  }

  // Custom matchers
  static Matcher hasTextColor(Color color) {
    return _HasTextColor(color);
  }

  static Matcher hasBackgroundColor(Color color) {
    return _HasBackgroundColor(color);
  }

  static Matcher isEnabled() {
    return _IsEnabled();
  }

  static Matcher isDisabled() {
    return _IsDisabled();
  }
}

// Custom matcher implementations
class _HasTextColor extends Matcher {
  final Color expectedColor;
  
  const _HasTextColor(this.expectedColor);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Text) {
      return item.style?.color == expectedColor;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has text color $expectedColor');
  }
}

class _HasBackgroundColor extends Matcher {
  final Color expectedColor;
  
  const _HasBackgroundColor(this.expectedColor);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Container) {
      final decoration = item.decoration;
      if (decoration is BoxDecoration) {
        return decoration.color == expectedColor;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has background color $expectedColor');
  }
}

class _IsEnabled extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is ElevatedButton) {
      return item.onPressed != null;
    }
    if (item is TextButton) {
      return item.onPressed != null;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is enabled');
  }
}

class _IsDisabled extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is ElevatedButton) {
      return item.onPressed == null;
    }
    if (item is TextButton) {
      return item.onPressed == null;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is disabled');
  }
}

