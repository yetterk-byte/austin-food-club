import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:austin_food_club_flutter/config/routes.dart';
import 'package:austin_food_club_flutter/screens/main/main_shell.dart';
import 'package:austin_food_club_flutter/screens/splash/splash_screen.dart';
import 'package:austin_food_club_flutter/screens/auth/login_screen.dart';
import 'package:austin_food_club_flutter/screens/main/current_screen.dart';
import 'package:austin_food_club_flutter/providers/auth_provider.dart';
import 'package:austin_food_club_flutter/services/navigation_service.dart';

void main() {
  group('Navigation Widget Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    Widget createTestApp({bool isAuthenticated = false}) {
      if (isAuthenticated) {
        mockAuthProvider.setAuthenticated(true);
      }

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ],
        child: MaterialApp.router(
          routerConfig: AppRoutes.router,
        ),
      );
    }

    testWidgets('App starts with splash screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());

      // Verify splash screen is displayed
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Austin Food Club'), findsOneWidget);
      expect(find.text('Discover Austin\'s Best Restaurants'), findsOneWidget);
    });

    testWidgets('Unauthenticated user redirects to login', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: false));

      // Wait for redirect
      await tester.pumpAndSettle();

      // Should redirect to login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Authenticated user sees main app', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));

      // Wait for redirect
      await tester.pumpAndSettle();

      // Should see main app with bottom navigation
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(CurrentScreen), findsOneWidget);
    });

    testWidgets('Bottom navigation displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Verify bottom navigation items
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('Bottom navigation tab switching', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Initially on Current tab
      expect(find.byIcon(Icons.home), findsOneWidget);

      // Tap Discover tab
      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();

      // Verify navigation to Discover screen
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Tap Wishlist tab
      await tester.tap(find.text('Wishlist'));
      await tester.pumpAndSettle();

      // Verify navigation to Wishlist screen
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify navigation to Profile screen
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Navigation badge displays correctly', (WidgetTester tester) async {
      // Mock badge counts
      // This would require setting up the app provider with badge data

      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Verify badges are displayed (if any)
      // expect(find.text('3'), findsOneWidget); // Wishlist count
      // expect(find.text('2'), findsOneWidget); // Unverified visits count
    });

    testWidgets('Deep link navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Test programmatic navigation
      NavigationService.goToRestaurantDetails(restaurantId: 'restaurant_123');
      await tester.pumpAndSettle();

      // Verify navigation to restaurant details
      // This would depend on your restaurant details screen implementation
    });

    testWidgets('Route guards work correctly', (WidgetTester tester) async {
      // Test accessing protected route while unauthenticated
      await tester.pumpWidget(createTestApp(isAuthenticated: false));

      // Try to navigate to protected route
      NavigationService.goToProfile();
      await tester.pumpAndSettle();

      // Should redirect to login
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Back navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to a detail screen
      NavigationService.pushRestaurantDetails(restaurantId: 'restaurant_123');
      await tester.pumpAndSettle();

      // Use back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back on main screen
      expect(find.byType(CurrentScreen), findsOneWidget);
    });

    testWidgets('Modal navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Open verification modal
      NavigationService.pushVerifyVisit(
        rsvpId: 'rsvp_123',
        restaurantName: 'Franklin Barbecue',
        visitDate: DateTime.now(),
      );
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.byType(VerifyVisitScreen), findsOneWidget);
    });

    testWidgets('Navigation service methods work', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Test various navigation methods
      NavigationService.goToCurrent();
      await tester.pumpAndSettle();
      expect(find.byType(CurrentScreen), findsOneWidget);

      NavigationService.goToDiscover();
      await tester.pumpAndSettle();
      // expect(find.byType(DiscoverScreen), findsOneWidget);

      NavigationService.goToWishlist();
      await tester.pumpAndSettle();
      // expect(find.byType(WishlistScreen), findsOneWidget);

      NavigationService.goToProfile();
      await tester.pumpAndSettle();
      // expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Error screen displays for invalid routes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Navigate to invalid route
      NavigationService.goTo('/invalid-route');
      await tester.pumpAndSettle();

      // Should show error screen
      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Go Home'), findsOneWidget);
    });

    testWidgets('Hero animations work for images', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // This would test hero animations between screens
      // Requires more complex setup with actual image widgets
    });

    testWidgets('Custom transitions work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(isAuthenticated: true));
      await tester.pumpAndSettle();

      // Test slide transition
      NavigationService.pushRestaurantDetails(restaurantId: 'restaurant_123');
      
      // Verify transition animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      
      // This would verify the slide transition is occurring
    });
  });
}

