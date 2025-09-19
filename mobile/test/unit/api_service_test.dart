import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:austin_food_club_flutter/services/api_service.dart';
import 'package:austin_food_club_flutter/models/restaurant.dart';
import 'package:austin_food_club_flutter/models/rsvp.dart';
import 'package:austin_food_club_flutter/models/verified_visit.dart';

// Generate mocks
@GenerateMocks([Dio])
import 'api_service_test.mocks.dart';

void main() {
  group('API Service Unit Tests', () {
    late ApiService apiService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      apiService = ApiService();
      // Inject mock dio (would need to modify ApiService to accept dio instance)
    });

    group('Restaurant API', () {
      test('getCurrentRestaurant returns restaurant on success', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'restaurant': {
              'id': 'restaurant_123',
              'name': 'Franklin Barbecue',
              'address': '900 E 11th St, Austin, TX 78702',
              'area': 'East Austin',
              'price': 3,
              'weekOf': DateTime.now().toIso8601String(),
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/restaurants/current'),
        );

        when(mockDio.get('/restaurants/current'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.getCurrentRestaurant();

        // Assert
        expect(result, isA<Restaurant>());
        expect(result?.name, equals('Franklin Barbecue'));
        expect(result?.area, equals('East Austin'));
        expect(result?.price, equals(3));
      });

      test('getCurrentRestaurant handles API error', () async {
        // Arrange
        when(mockDio.get('/restaurants/current'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/restaurants/current'),
              message: 'Network error',
            ));

        // Act & Assert
        expect(
          () => apiService.getCurrentRestaurant(),
          throwsA(isA<Exception>()),
        );
      });

      test('getAllRestaurants returns list of restaurants', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'restaurants': [
              {
                'id': 'restaurant_1',
                'name': 'Franklin Barbecue',
                'address': '900 E 11th St, Austin, TX 78702',
                'area': 'East Austin',
                'price': 3,
                'weekOf': DateTime.now().toIso8601String(),
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              },
              {
                'id': 'restaurant_2',
                'name': 'La Barbecue',
                'address': '2401 E Cesar Chavez St, Austin, TX 78702',
                'area': 'East Austin',
                'price': 2,
                'weekOf': DateTime.now().toIso8601String(),
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              },
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/restaurants'),
        );

        when(mockDio.get('/restaurants'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.getAllRestaurants();

        // Assert
        expect(result, isA<List<Restaurant>>());
        expect(result.length, equals(2));
        expect(result[0].name, equals('Franklin Barbecue'));
        expect(result[1].name, equals('La Barbecue'));
      });
    });

    group('RSVP API', () {
      test('createRSVP returns RSVP on success', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'rsvp': {
              'id': 'rsvp_123',
              'userId': 'user_123',
              'restaurantId': 'restaurant_123',
              'day': 'Monday',
              'status': 'going',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/rsvps'),
        );

        when(mockDio.post('/rsvps', data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.createRSVP(
          restaurantId: 'restaurant_123',
          day: 'Monday',
        );

        // Assert
        expect(result, isA<RSVP>());
        expect(result?.restaurantId, equals('restaurant_123'));
        expect(result?.day, equals('Monday'));
        expect(result?.status, equals(RSVPStatus.going));
      });

      test('createRSVP handles validation error', () async {
        // Arrange
        when(mockDio.post('/rsvps', data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/rsvps'),
              response: Response(
                statusCode: 400,
                data: {'error': 'Invalid day'},
                requestOptions: RequestOptions(path: '/rsvps'),
              ),
            ));

        // Act & Assert
        expect(
          () => apiService.createRSVP(
            restaurantId: 'restaurant_123',
            day: 'InvalidDay',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('getRSVPCounts returns count map', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'counts': {
              'Monday': 5,
              'Tuesday': 3,
              'Wednesday': 8,
              'Thursday': 2,
              'Friday': 12,
              'Saturday': 15,
              'Sunday': 7,
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/rsvps/counts'),
        );

        when(mockDio.get('/rsvps/counts/restaurant_123'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.getRSVPCounts('restaurant_123');

        // Assert
        expect(result, isA<Map<String, int>>());
        expect(result['Monday'], equals(5));
        expect(result['Friday'], equals(12));
      });
    });

    group('Verified Visits API', () {
      test('submitVerification creates verified visit', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'visit': {
              'id': 'visit_123',
              'userId': 'user_123',
              'restaurantId': 'restaurant_123',
              'visitDate': DateTime.now().toIso8601String(),
              'rating': 5,
              'review': 'Amazing food!',
              'photoUrl': 'https://example.com/photo.jpg',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/verified-visits'),
        );

        when(mockDio.post('/verified-visits', data: anyNamed('data')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.submitVerification(
          restaurantId: 'restaurant_123',
          rating: 5,
          review: 'Amazing food!',
          photoUrl: 'https://example.com/photo.jpg',
        );

        // Assert
        expect(result, isA<VerifiedVisit>());
        expect(result?.rating, equals(5));
        expect(result?.review, equals('Amazing food!'));
      });

      test('getVerifiedVisits returns user visits', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'visits': [
              {
                'id': 'visit_1',
                'userId': 'user_123',
                'restaurantId': 'restaurant_1',
                'visitDate': DateTime.now().toIso8601String(),
                'rating': 5,
                'review': 'Great food!',
                'photoUrl': 'https://example.com/photo1.jpg',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              },
              {
                'id': 'visit_2',
                'userId': 'user_123',
                'restaurantId': 'restaurant_2',
                'visitDate': DateTime.now().toIso8601String(),
                'rating': 4,
                'review': 'Good experience',
                'photoUrl': 'https://example.com/photo2.jpg',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              },
            ]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/verified-visits/user_123'),
        );

        when(mockDio.get('/verified-visits/user_123'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.getVerifiedVisits('user_123');

        // Assert
        expect(result, isA<List<VerifiedVisit>>());
        expect(result.length, equals(2));
        expect(result[0].rating, equals(5));
        expect(result[1].rating, equals(4));
      });
    });

    group('Error Handling', () {
      test('handles network timeout', () async {
        // Arrange
        when(mockDio.get(any))
            .thenThrow(DioException(
              type: DioExceptionType.connectionTimeout,
              requestOptions: RequestOptions(path: '/test'),
            ));

        // Act & Assert
        expect(
          () => apiService.getCurrentRestaurant(),
          throwsA(isA<Exception>()),
        );
      });

      test('handles server error', () async {
        // Arrange
        when(mockDio.get(any))
            .thenThrow(DioException(
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 500,
                data: {'error': 'Internal server error'},
                requestOptions: RequestOptions(path: '/test'),
              ),
              requestOptions: RequestOptions(path: '/test'),
            ));

        // Act & Assert
        expect(
          () => apiService.getCurrentRestaurant(),
          throwsA(isA<Exception>()),
        );
      });

      test('handles unauthorized error', () async {
        // Arrange
        when(mockDio.get(any))
            .thenThrow(DioException(
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 401,
                data: {'error': 'Unauthorized'},
                requestOptions: RequestOptions(path: '/test'),
              ),
              requestOptions: RequestOptions(path: '/test'),
            ));

        // Act & Assert
        expect(
          () => apiService.getCurrentRestaurant(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Request Interceptors', () {
      test('adds authorization header when token available', () async {
        // This would test that the auth token is properly added to requests
        // Requires access to the dio interceptors
      });

      test('retries failed requests', () async {
        // This would test the retry logic for failed requests
        // Requires mock setup for multiple calls
      });
    });
  });
}

