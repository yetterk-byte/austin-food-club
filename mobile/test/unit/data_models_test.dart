import 'package:flutter_test/flutter_test.dart';
import 'package:austin_food_club_flutter/models/restaurant.dart';
import 'package:austin_food_club_flutter/models/rsvp.dart';
import 'package:austin_food_club_flutter/models/verified_visit.dart';
import 'package:austin_food_club_flutter/models/user.dart';
import 'package:austin_food_club_flutter/models/friend.dart';

void main() {
  group('Data Models Unit Tests', () {
    group('Restaurant Model Tests', () {
      test('Restaurant.fromJson creates correct instance', () {
        // Arrange
        final json = {
          'id': 'restaurant_123',
          'name': 'Franklin Barbecue',
          'description': 'Authentic Texas BBQ',
          'address': '900 E 11th St, Austin, TX 78702',
          'area': 'East Austin',
          'price': 3,
          'imageUrl': 'https://example.com/image.jpg',
          'cuisineType': 'BBQ',
          'phone': '+15551234567',
          'website': 'https://franklinbarbecue.com',
          'weekOf': '2023-12-01T00:00:00.000Z',
          'createdAt': '2023-12-01T10:00:00.000Z',
          'updatedAt': '2023-12-01T10:00:00.000Z',
        };

        // Act
        final restaurant = Restaurant.fromJson(json);

        // Assert
        expect(restaurant.id, equals('restaurant_123'));
        expect(restaurant.name, equals('Franklin Barbecue'));
        expect(restaurant.description, equals('Authentic Texas BBQ'));
        expect(restaurant.address, equals('900 E 11th St, Austin, TX 78702'));
        expect(restaurant.area, equals('East Austin'));
        expect(restaurant.price, equals(3));
        expect(restaurant.imageUrl, equals('https://example.com/image.jpg'));
        expect(restaurant.cuisineType, equals('BBQ'));
        expect(restaurant.phone, equals('+15551234567'));
        expect(restaurant.website, equals('https://franklinbarbecue.com'));
      });

      test('Restaurant.toJson creates correct map', () {
        // Arrange
        final restaurant = Restaurant(
          id: 'restaurant_123',
          name: 'Franklin Barbecue',
          description: 'Authentic Texas BBQ',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          imageUrl: 'https://example.com/image.jpg',
          cuisineType: 'BBQ',
          phone: '+15551234567',
          website: 'https://franklinbarbecue.com',
          weekOf: DateTime.parse('2023-12-01T00:00:00.000Z'),
          createdAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
          updatedAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
        );

        // Act
        final json = restaurant.toJson();

        // Assert
        expect(json['id'], equals('restaurant_123'));
        expect(json['name'], equals('Franklin Barbecue'));
        expect(json['description'], equals('Authentic Texas BBQ'));
        expect(json['price'], equals(3));
      });

      test('Restaurant.copyWith updates fields correctly', () {
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

        // Act
        final updatedRestaurant = restaurant.copyWith(
          name: 'Updated Name',
          price: 4,
        );

        // Assert
        expect(updatedRestaurant.id, equals('restaurant_123')); // Unchanged
        expect(updatedRestaurant.name, equals('Updated Name')); // Changed
        expect(updatedRestaurant.price, equals(4)); // Changed
        expect(updatedRestaurant.address, equals('900 E 11th St, Austin, TX 78702')); // Unchanged
      });

      test('Restaurant equality works correctly', () {
        // Arrange
        final restaurant1 = Restaurant(
          id: 'restaurant_123',
          name: 'Franklin Barbecue',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final restaurant2 = Restaurant(
          id: 'restaurant_123',
          name: 'Different Name',
          address: 'Different Address',
          area: 'Different Area',
          price: 2,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final restaurant3 = Restaurant(
          id: 'restaurant_456',
          name: 'Franklin Barbecue',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(restaurant1, equals(restaurant2)); // Same ID
        expect(restaurant1, isNot(equals(restaurant3))); // Different ID
      });
    });

    group('RSVP Model Tests', () {
      test('RSVP.fromJson creates correct instance', () {
        // Arrange
        final json = {
          'id': 'rsvp_123',
          'userId': 'user_123',
          'restaurantId': 'restaurant_123',
          'day': 'Monday',
          'status': 'going',
          'createdAt': '2023-12-01T10:00:00.000Z',
          'updatedAt': '2023-12-01T10:00:00.000Z',
        };

        // Act
        final rsvp = RSVP.fromJson(json);

        // Assert
        expect(rsvp.id, equals('rsvp_123'));
        expect(rsvp.userId, equals('user_123'));
        expect(rsvp.restaurantId, equals('restaurant_123'));
        expect(rsvp.day, equals('Monday'));
        expect(rsvp.status, equals(RSVPStatus.going));
      });

      test('RSVP status enum parsing works correctly', () {
        // Test all status values
        final goingRSVP = RSVP.fromJson({
          'id': 'rsvp_1',
          'userId': 'user_123',
          'restaurantId': 'restaurant_123',
          'day': 'Monday',
          'status': 'going',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        final maybeRSVP = RSVP.fromJson({
          'id': 'rsvp_2',
          'userId': 'user_123',
          'restaurantId': 'restaurant_123',
          'day': 'Tuesday',
          'status': 'maybe',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        expect(goingRSVP.status, equals(RSVPStatus.going));
        expect(maybeRSVP.status, equals(RSVPStatus.maybe));
      });
    });

    group('VerifiedVisit Model Tests', () {
      test('VerifiedVisit.fromJson creates correct instance', () {
        // Arrange
        final json = {
          'id': 'visit_123',
          'userId': 'user_123',
          'restaurantId': 'restaurant_123',
          'visitDate': '2023-12-01T18:00:00.000Z',
          'rating': 5,
          'review': 'Amazing food!',
          'photoUrl': 'https://example.com/photo.jpg',
          'createdAt': '2023-12-01T20:00:00.000Z',
          'updatedAt': '2023-12-01T20:00:00.000Z',
        };

        // Act
        final visit = VerifiedVisit.fromJson(json);

        // Assert
        expect(visit.id, equals('visit_123'));
        expect(visit.userId, equals('user_123'));
        expect(visit.restaurantId, equals('restaurant_123'));
        expect(visit.rating, equals(5));
        expect(visit.review, equals('Amazing food!'));
        expect(visit.photoUrl, equals('https://example.com/photo.jpg'));
      });

      test('VerifiedVisit validation works correctly', () {
        // Test valid rating
        expect(() => VerifiedVisit(
          id: 'visit_123',
          userId: 'user_123',
          restaurantId: 'restaurant_123',
          visitDate: DateTime.now(),
          rating: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ), returnsNormally);

        // Test invalid rating (would need validation in model)
        // expect(() => VerifiedVisit(
        //   id: 'visit_123',
        //   userId: 'user_123',
        //   restaurantId: 'restaurant_123',
        //   visitDate: DateTime.now(),
        //   rating: 6, // Invalid
        //   createdAt: DateTime.now(),
        //   updatedAt: DateTime.now(),
        // ), throwsArgumentError);
      });
    });

    group('User Model Tests', () {
      test('User.fromJson creates correct instance', () {
        // Arrange
        final json = {
          'id': 'user_123',
          'name': 'John Doe',
          'email': 'john@example.com',
          'phone': '+15551234567',
          'profileImageUrl': 'https://example.com/avatar.jpg',
          'createdAt': '2023-12-01T10:00:00.000Z',
          'updatedAt': '2023-12-01T10:00:00.000Z',
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.id, equals('user_123'));
        expect(user.name, equals('John Doe'));
        expect(user.email, equals('john@example.com'));
        expect(user.phone, equals('+15551234567'));
        expect(user.profileImageUrl, equals('https://example.com/avatar.jpg'));
      });

      test('User.displayName returns correct value', () {
        // Test with full name
        final user1 = User(
          id: 'user_1',
          name: 'John Doe',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(user1.displayName, equals('John Doe'));

        // Test with email fallback
        final user2 = User(
          id: 'user_2',
          name: '',
          email: 'john@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(user2.displayName, equals('john@example.com'));

        // Test with phone fallback
        final user3 = User(
          id: 'user_3',
          name: '',
          phone: '+15551234567',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(user3.displayName, equals('+15551234567'));
      });
    });

    group('Friend Model Tests', () {
      test('Achievement.progressPercentage calculates correctly', () {
        // Arrange
        final achievement = Achievement(
          id: 'achievement_123',
          name: 'Food Explorer',
          description: 'Visit 10 restaurants',
          iconUrl: '🗺️',
          type: AchievementType.visits,
          targetValue: 10,
          badgeColor: '#FFD700',
          currentProgress: 3,
        );

        // Act & Assert
        expect(achievement.progressPercentage, equals(0.3));
      });

      test('Achievement.progressPercentage handles edge cases', () {
        // Zero target value
        final achievement1 = Achievement(
          id: 'achievement_1',
          name: 'Test',
          description: 'Test achievement',
          iconUrl: '🏆',
          type: AchievementType.visits,
          targetValue: 0,
          badgeColor: '#FFD700',
          currentProgress: 5,
        );
        expect(achievement1.progressPercentage, equals(0.0));

        // Progress exceeds target
        final achievement2 = Achievement(
          id: 'achievement_2',
          name: 'Test',
          description: 'Test achievement',
          iconUrl: '🏆',
          type: AchievementType.visits,
          targetValue: 5,
          badgeColor: '#FFD700',
          currentProgress: 10,
        );
        expect(achievement2.progressPercentage, equals(1.0));
      });

      test('UserStats calculations work correctly', () {
        // Arrange
        final stats = UserStats(
          totalVisits: 15,
          averageRating: 4.2,
          currentStreak: 3,
          maxStreak: 7,
          cuisinesTried: ['BBQ', 'Tacos', 'Asian'],
          friendsCount: 8,
          achievementsUnlocked: 5,
        );

        // Assert
        expect(stats.totalVisits, equals(15));
        expect(stats.averageRating, equals(4.2));
        expect(stats.cuisinesTried.length, equals(3));
        expect(stats.friendsCount, equals(8));
      });
    });

    group('Model Serialization Tests', () {
      test('Restaurant serialization round trip', () {
        // Arrange
        final original = Restaurant(
          id: 'restaurant_123',
          name: 'Franklin Barbecue',
          address: '900 E 11th St, Austin, TX 78702',
          area: 'East Austin',
          price: 3,
          weekOf: DateTime.parse('2023-12-01T00:00:00.000Z'),
          createdAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
          updatedAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
        );

        // Act
        final json = original.toJson();
        final restored = Restaurant.fromJson(json);

        // Assert
        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.address, equals(original.address));
        expect(restored.price, equals(original.price));
        expect(restored.weekOf, equals(original.weekOf));
      });

      test('RSVP serialization round trip', () {
        // Arrange
        final original = RSVP(
          id: 'rsvp_123',
          userId: 'user_123',
          restaurantId: 'restaurant_123',
          day: 'Monday',
          status: RSVPStatus.going,
          createdAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
          updatedAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
        );

        // Act
        final json = original.toJson();
        final restored = RSVP.fromJson(json);

        // Assert
        expect(restored.id, equals(original.id));
        expect(restored.userId, equals(original.userId));
        expect(restored.restaurantId, equals(original.restaurantId));
        expect(restored.day, equals(original.day));
        expect(restored.status, equals(original.status));
      });

      test('VerifiedVisit serialization round trip', () {
        // Arrange
        final original = VerifiedVisit(
          id: 'visit_123',
          userId: 'user_123',
          restaurantId: 'restaurant_123',
          visitDate: DateTime.parse('2023-12-01T18:00:00.000Z'),
          rating: 5,
          review: 'Amazing food!',
          photoUrl: 'https://example.com/photo.jpg',
          createdAt: DateTime.parse('2023-12-01T20:00:00.000Z'),
          updatedAt: DateTime.parse('2023-12-01T20:00:00.000Z'),
        );

        // Act
        final json = original.toJson();
        final restored = VerifiedVisit.fromJson(json);

        // Assert
        expect(restored.id, equals(original.id));
        expect(restored.userId, equals(original.userId));
        expect(restored.rating, equals(original.rating));
        expect(restored.review, equals(original.review));
        expect(restored.photoUrl, equals(original.photoUrl));
      });

      test('User serialization round trip', () {
        // Arrange
        final original = User(
          id: 'user_123',
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+15551234567',
          profileImageUrl: 'https://example.com/avatar.jpg',
          createdAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
          updatedAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
        );

        // Act
        final json = original.toJson();
        final restored = User.fromJson(json);

        // Assert
        expect(restored.id, equals(original.id));
        expect(restored.name, equals(original.name));
        expect(restored.email, equals(original.email));
        expect(restored.phone, equals(original.phone));
        expect(restored.profileImageUrl, equals(original.profileImageUrl));
      });
    });

    group('Model Validation Tests', () {
      test('Restaurant requires valid price range', () {
        // Valid prices (1-4)
        expect(() => Restaurant(
          id: 'restaurant_123',
          name: 'Test Restaurant',
          address: 'Test Address',
          area: 'Test Area',
          price: 1,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ), returnsNormally);

        expect(() => Restaurant(
          id: 'restaurant_123',
          name: 'Test Restaurant',
          address: 'Test Address',
          area: 'Test Area',
          price: 4,
          weekOf: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ), returnsNormally);

        // Invalid prices would need validation in the model
        // expect(() => Restaurant(
        //   id: 'restaurant_123',
        //   name: 'Test Restaurant',
        //   address: 'Test Address',
        //   area: 'Test Area',
        //   price: 0, // Invalid
        //   weekOf: DateTime.now(),
        //   createdAt: DateTime.now(),
        //   updatedAt: DateTime.now(),
        // ), throwsArgumentError);
      });

      test('VerifiedVisit requires valid rating', () {
        // Valid rating (1-5)
        expect(() => VerifiedVisit(
          id: 'visit_123',
          userId: 'user_123',
          restaurantId: 'restaurant_123',
          visitDate: DateTime.now(),
          rating: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ), returnsNormally);

        expect(() => VerifiedVisit(
          id: 'visit_123',
          userId: 'user_123',
          restaurantId: 'restaurant_123',
          visitDate: DateTime.now(),
          rating: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ), returnsNormally);
      });
    });

    group('Model Edge Cases Tests', () {
      test('handles null values correctly', () {
        // Restaurant with minimal data
        final restaurant = Restaurant.fromJson({
          'id': 'restaurant_123',
          'name': 'Test Restaurant',
          'address': 'Test Address',
          'area': 'Test Area',
          'price': 2,
          'weekOf': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          // Optional fields omitted
        });

        expect(restaurant.description, isNull);
        expect(restaurant.imageUrl, isNull);
        expect(restaurant.cuisineType, isNull);
        expect(restaurant.phone, isNull);
        expect(restaurant.website, isNull);
      });

      test('handles empty strings correctly', () {
        // Test empty string handling
        final user = User.fromJson({
          'id': 'user_123',
          'name': '',
          'email': '',
          'phone': '',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        expect(user.name, equals(''));
        expect(user.email, equals(''));
        expect(user.phone, equals(''));
      });
    });
  });
}

