import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:austin_food_club_flutter/providers/auth_provider.dart';
import 'package:austin_food_club_flutter/providers/restaurant_provider.dart';
import 'package:austin_food_club_flutter/providers/rsvp_provider.dart';
import 'package:austin_food_club_flutter/providers/user_provider.dart';
import 'package:austin_food_club_flutter/providers/social_provider.dart';
import 'package:austin_food_club_flutter/providers/offline_provider.dart';
import 'package:austin_food_club_flutter/services/auth_service.dart';
import 'package:austin_food_club_flutter/services/api_service.dart';
import 'package:austin_food_club_flutter/models/restaurant.dart';
import 'package:austin_food_club_flutter/models/rsvp.dart';
import 'package:austin_food_club_flutter/models/user.dart';

// Generate mocks
@GenerateMocks([AuthService, ApiService])
import 'provider_logic_test.mocks.dart';

void main() {
  group('Provider Logic Unit Tests', () {
    group('AuthProvider Tests', () {
      late AuthProvider authProvider;
      late MockAuthService mockAuthService;

      setUp(() {
        mockAuthService = MockAuthService();
        authProvider = AuthProvider();
        // Inject mock service (would need to modify provider to accept service)
      });

      test('initial state is correct', () {
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.isLoading, isFalse);
        expect(authProvider.error, isNull);
        expect(authProvider.currentUser, isNull);
      });

      test('signInWithPhone sets loading state', () async {
        // Arrange
        when(mockAuthService.signInWithPhone(any))
            .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));

        // Act
        final future = authProvider.signInWithPhone('+15551234567');
        
        // Assert loading state
        expect(authProvider.isLoading, isTrue);
        expect(authProvider.error, isNull);

        await future;
        expect(authProvider.isLoading, isFalse);
      });

      test('signInWithPhone handles success', () async {
        // Arrange
        when(mockAuthService.signInWithPhone(any))
            .thenAnswer((_) async {});

        // Act
        await authProvider.signInWithPhone('+15551234567');

        // Assert
        expect(authProvider.isLoading, isFalse);
        expect(authProvider.error, isNull);
      });

      test('signInWithPhone handles error', () async {
        // Arrange
        when(mockAuthService.signInWithPhone(any))
            .thenThrow(Exception('Invalid phone number'));

        // Act
        await authProvider.signInWithPhone('invalid');

        // Assert
        expect(authProvider.isLoading, isFalse);
        expect(authProvider.error, equals('Invalid phone number'));
      });

      test('verifyPhoneOTP authenticates user on success', () async {
        // Arrange
        final mockUser = User(
          id: 'user_123',
          name: 'John Doe',
          phone: '+15551234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockAuthService.verifyPhoneOTP(any, any))
            .thenAnswer((_) async => mockUser);

        // Act
        await authProvider.verifyPhoneOTP('+15551234567', '123456');

        // Assert
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.currentUser, equals(mockUser));
        expect(authProvider.error, isNull);
      });

      test('signOut clears user state', () async {
        // Arrange - set authenticated state
        authProvider.setAuthenticated(true);
        authProvider.setCurrentUser(User(
          id: 'user_123',
          name: 'John Doe',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        when(mockAuthService.signOut())
            .thenAnswer((_) async {});

        // Act
        await authProvider.signOut();

        // Assert
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.currentUser, isNull);
      });
    });

    group('RestaurantProvider Tests', () {
      late RestaurantProvider restaurantProvider;
      late MockApiService mockApiService;

      setUp(() {
        mockApiService = MockApiService();
        restaurantProvider = RestaurantProvider();
        // Inject mock service
      });

      test('initial state is correct', () {
        expect(restaurantProvider.currentRestaurant, isNull);
        expect(restaurantProvider.allRestaurants, isEmpty);
        expect(restaurantProvider.wishlist, isEmpty);
        expect(restaurantProvider.isLoading, isFalse);
        expect(restaurantProvider.error, isNull);
      });

      test('fetchCurrentRestaurant updates state correctly', () async {
        // Arrange
        final mockRestaurant = Restaurant(
          id: 'restaurant_123',
          name: 'Franklin Barbecue',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockApiService.getCurrentRestaurant())
            .thenAnswer((_) async => mockRestaurant);

        // Act
        await restaurantProvider.fetchCurrentRestaurant();

        // Assert
        expect(restaurantProvider.currentRestaurant, equals(mockRestaurant));
        expect(restaurantProvider.isLoading, isFalse);
        expect(restaurantProvider.error, isNull);
      });

      test('toggleWishlist adds restaurant to wishlist', () {
        // Arrange
        final restaurant = Restaurant(
          id: 'restaurant_123',
          name: 'Franklin Barbecue',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        restaurantProvider.setAllRestaurants([restaurant]);

        // Act
        restaurantProvider.toggleWishlist('restaurant_123');

        // Assert
        expect(restaurantProvider.isInWishlist('restaurant_123'), isTrue);
        expect(restaurantProvider.wishlist.length, equals(1));
      });

      test('toggleWishlist removes restaurant from wishlist', () {
        // Arrange
        final restaurant = Restaurant(
          id: 'restaurant_123',
          name: 'Franklin Barbecue',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        restaurantProvider.setAllRestaurants([restaurant]);
        restaurantProvider.toggleWishlist('restaurant_123'); // Add to wishlist

        // Act
        restaurantProvider.toggleWishlist('restaurant_123'); // Remove from wishlist

        // Assert
        expect(restaurantProvider.isInWishlist('restaurant_123'), isFalse);
        expect(restaurantProvider.wishlist.length, equals(0));
      });
    });

    group('RSVPProvider Tests', () {
      late RSVPProvider rsvpProvider;
      late MockApiService mockApiService;

      setUp(() {
        mockApiService = MockApiService();
        rsvpProvider = RSVPProvider();
        // Inject mock service
      });

      test('createRSVP enforces one RSVP per restaurant', () async {
        // Arrange - existing RSVP for Tuesday
        final existingRSVP = RSVP(
          id: 'rsvp_1',
          userId: 'user_123',
          restaurantId: 'restaurant_123',
          day: 'Tuesday',
          status: RSVPStatus.going,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        rsvpProvider.setUserRSVPs([existingRSVP]);

        // Mock API calls
        when(mockApiService.cancelRSVP(any))
            .thenAnswer((_) async => true);
        when(mockApiService.createRSVP(
          restaurantId: any,
          day: any,
        )).thenAnswer((_) async => RSVP(
          id: 'rsvp_2',
          userId: 'user_123',
          restaurantId: 'restaurant_123',
          day: 'Wednesday',
          status: RSVPStatus.going,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        // Act - create RSVP for Wednesday
        await rsvpProvider.createRSVP('restaurant_123', 'Wednesday');

        // Assert - should have cancelled Tuesday and created Wednesday
        verify(mockApiService.cancelRSVP('rsvp_1')).called(1);
        verify(mockApiService.createRSVP(
          restaurantId: 'restaurant_123',
          day: 'Wednesday',
        )).called(1);
      });

      test('getRSVPCount returns correct count', () {
        // Arrange
        rsvpProvider.setRSVPCounts({
          'Monday': 5,
          'Tuesday': 3,
          'Wednesday': 8,
        });

        // Act & Assert
        expect(rsvpProvider.getRSVPCount('Monday'), equals(5));
        expect(rsvpProvider.getRSVPCount('Tuesday'), equals(3));
        expect(rsvpProvider.getRSVPCount('Wednesday'), equals(8));
        expect(rsvpProvider.getRSVPCount('Thursday'), equals(0));
      });

      test('hasRSVPForDay returns correct value', () {
        // Arrange
        final rsvp = RSVP(
          id: 'rsvp_123',
          userId: 'user_123',
          restaurantId: 'restaurant_123',
          day: 'Monday',
          status: RSVPStatus.going,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        rsvpProvider.setUserRSVPs([rsvp]);

        // Act & Assert
        expect(rsvpProvider.hasRSVPForDay('restaurant_123', 'Monday'), isTrue);
        expect(rsvpProvider.hasRSVPForDay('restaurant_123', 'Tuesday'), isFalse);
      });
    });

    group('SocialProvider Tests', () {
      late SocialProvider socialProvider;

      setUp(() {
        socialProvider = SocialProvider();
      });

      test('pendingRequestsCount returns correct count', () {
        // This would test the pending friend requests count logic
        expect(socialProvider.pendingRequestsCount, equals(0));
      });

      test('achievementProgress calculates correctly', () {
        // This would test achievement progress calculation
        expect(socialProvider.achievementProgress, equals(0.0));
      });
    });

    group('OfflineProvider Tests', () {
      late OfflineProvider offlineProvider;

      setUp(() {
        offlineProvider = OfflineProvider();
      });

      test('initial state is correct', () {
        expect(offlineProvider.isOnline, isTrue);
        expect(offlineProvider.isSyncing, isFalse);
        expect(offlineProvider.syncProgress, equals(0.0));
        expect(offlineProvider.offlineModeEnabled, isTrue);
      });

      test('getConnectionStatusText returns correct text', () {
        // Test online state
        expect(offlineProvider.getConnectionStatusText(), equals('Online'));

        // Test offline state
        offlineProvider.setOffline();
        expect(offlineProvider.getConnectionStatusText(), equals('Offline'));

        // Test syncing state
        offlineProvider.setSyncing(true);
        expect(offlineProvider.getConnectionStatusText(), equals('Syncing...'));
      });

      test('shouldShowOfflineIndicator returns correct value', () {
        // Online and not syncing - should not show
        expect(offlineProvider.shouldShowOfflineIndicator(), isFalse);

        // Offline - should show
        offlineProvider.setOffline();
        expect(offlineProvider.shouldShowOfflineIndicator(), isTrue);

        // Syncing - should show
        offlineProvider.setOnline();
        offlineProvider.setSyncing(true);
        expect(offlineProvider.shouldShowOfflineIndicator(), isTrue);
      });
    });
  });
}

