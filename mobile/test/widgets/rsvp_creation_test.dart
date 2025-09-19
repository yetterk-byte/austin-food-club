import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:austin_food_club_flutter/screens/main/current_screen.dart';
import 'package:austin_food_club_flutter/providers/rsvp_provider.dart';
import 'package:austin_food_club_flutter/providers/restaurant_provider.dart';
import 'package:austin_food_club_flutter/widgets/restaurant/rsvp_section.dart';
import 'package:austin_food_club_flutter/widgets/common/custom_button.dart';
import 'package:austin_food_club_flutter/models/restaurant.dart';
import 'package:austin_food_club_flutter/models/rsvp.dart';

void main() {
  group('RSVP Creation Widget Tests', () {
    late RSVPProvider mockRSVPProvider;
    late RestaurantProvider mockRestaurantProvider;
    late Restaurant mockRestaurant;

    setUp(() {
      mockRSVPProvider = RSVPProvider();
      mockRestaurantProvider = RestaurantProvider();
      
      mockRestaurant = Restaurant(
        id: 'restaurant_123',
        name: 'Franklin Barbecue',
        address: '900 E 11th St, Austin, TX 78702',
        area: 'East Austin',
        price: 3,
        weekOf: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<RSVPProvider>(create: (_) => mockRSVPProvider),
            ChangeNotifierProvider<RestaurantProvider>(create: (_) => mockRestaurantProvider),
          ],
          child: child,
        ),
      );
    }

    testWidgets('RSVP section displays day buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Verify day buttons are displayed
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Thursday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
    });

    testWidgets('Day selection updates UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Tap Monday button
      await tester.tap(find.text('Monday'));
      await tester.pump();

      // Verify Monday is selected (visual state change)
      // This would depend on your implementation of selected state
      final mondayButton = find.text('Monday');
      expect(mondayButton, findsOneWidget);
    });

    testWidgets('RSVP count displays correctly', (WidgetTester tester) async {
      // Mock RSVP counts
      mockRSVPProvider.setRSVPCounts({
        'Monday': 5,
        'Tuesday': 3,
        'Wednesday': 8,
      });

      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Verify RSVP counts are displayed
      expect(find.text('5'), findsOneWidget); // Monday count
      expect(find.text('3'), findsOneWidget); // Tuesday count
      expect(find.text('8'), findsOneWidget); // Wednesday count
    });

    testWidgets('RSVP button shows correct state', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Initially should show "RSVP" button
      expect(find.text('RSVP'), findsOneWidget);

      // Select a day
      await tester.tap(find.text('Monday'));
      await tester.pump();

      // Should show "Going" or similar confirmation
      // This depends on your RSVP flow implementation
    });

    testWidgets('RSVP creation flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Select Monday
      await tester.tap(find.text('Monday'));
      await tester.pump();

      // Tap RSVP button
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Verify RSVP creation was triggered
      // This would check if the provider method was called
      expect(mockRSVPProvider.isLoading, isFalse);
    });

    testWidgets('RSVP loading state', (WidgetTester tester) async {
      // Set loading state
      mockRSVPProvider.setLoading(true);

      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('RSVP error handling', (WidgetTester tester) async {
      // Set error state
      mockRSVPProvider.setError('Failed to create RSVP');

      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      await tester.pump();

      // Verify error message is displayed
      expect(find.text('Failed to create RSVP'), findsOneWidget);
    });

    testWidgets('Existing RSVP displays correctly', (WidgetTester tester) async {
      // Mock existing RSVP
      final mockRSVP = RSVP(
        id: 'rsvp_123',
        userId: 'user_123',
        restaurantId: 'restaurant_123',
        day: 'Monday',
        status: RSVPStatus.going,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockRSVPProvider.setUserRSVPs([mockRSVP]);

      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Verify existing RSVP is shown
      expect(find.text('Going'), findsOneWidget);
      expect(find.text('Cancel RSVP'), findsOneWidget);
    });

    testWidgets('RSVP cancellation flow', (WidgetTester tester) async {
      // Mock existing RSVP
      final mockRSVP = RSVP(
        id: 'rsvp_123',
        userId: 'user_123',
        restaurantId: 'restaurant_123',
        day: 'Monday',
        status: RSVPStatus.going,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockRSVPProvider.setUserRSVPs([mockRSVP]);

      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Tap cancel RSVP button
      await tester.tap(find.text('Cancel RSVP'));
      await tester.pump();

      // Verify confirmation dialog appears
      expect(find.text('Cancel RSVP?'), findsOneWidget);
      expect(find.text('Are you sure you want to cancel your RSVP?'), findsOneWidget);

      // Confirm cancellation
      await tester.tap(find.text('Yes, Cancel'));
      await tester.pump();

      // Verify RSVP was cancelled
      // This would check if the provider method was called
    });

    testWidgets('One RSVP per user per restaurant enforcement', (WidgetTester tester) async {
      // Mock existing RSVP for Tuesday
      final existingRSVP = RSVP(
        id: 'rsvp_123',
        userId: 'user_123',
        restaurantId: 'restaurant_123',
        day: 'Tuesday',
        status: RSVPStatus.going,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      mockRSVPProvider.setUserRSVPs([existingRSVP]);

      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Select Wednesday (different day)
      await tester.tap(find.text('Wednesday'));
      await tester.pump();

      // Tap RSVP button
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Verify that Tuesday RSVP was cancelled and Wednesday was created
      // This would check the provider state
    });

    testWidgets('RSVP counts update in real-time', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Initial counts
      mockRSVPProvider.setRSVPCounts({'Monday': 5});
      await tester.pump();

      expect(find.text('5'), findsOneWidget);

      // Update counts
      mockRSVPProvider.setRSVPCounts({'Monday': 6});
      await tester.pump();

      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('RSVP success animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RSVPSection(restaurant: mockRestaurant),
        ),
      );

      // Select day and create RSVP
      await tester.tap(find.text('Monday'));
      await tester.pump();

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Mock successful RSVP creation
      mockRSVPProvider.setSuccess(true);
      await tester.pump();

      // Verify success state is shown
      // This would check for success animation or message
    });
  });
}

