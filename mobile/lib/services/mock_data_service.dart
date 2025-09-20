import '../models/restaurant.dart';
import '../models/rsvp.dart';
import 'api_service.dart';
import 'restaurant_service.dart';

class MockDataService {
  /// Get featured restaurant (tries API first, falls back to mock)
  static Future<Restaurant> getFeaturedRestaurant() async {
    try {
      // Try to get from new RestaurantService first
      final restaurantService = RestaurantService();
      return await restaurantService.getCurrentRestaurant();
    } catch (e) {
      print('RestaurantService unavailable, trying ApiService: $e');
      try {
        // Fallback to old API service
        return await ApiService.getFeaturedRestaurant();
      } catch (e2) {
        print('All APIs unavailable, using mock data: $e2');
        // Final fallback to mock data
        return getFeaturedRestaurantMock();
      }
    }
  }

  /// Mock featured restaurant data
  static Restaurant getFeaturedRestaurantMock() {
    return Restaurant(
      id: 'test-restaurant-1',
      yelpId: 'suerte-austin',
      name: 'Suerte',
      address: '1800 E 6th St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78702',
      latitude: 30.2628,
      longitude: -97.7231,
      phone: '(512) 953-0092',
          imageUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop', // Upscale contemporary Cajun restaurant interior
      yelpUrl: 'https://www.yelp.com/biz/suerte-austin',
      price: '\$\$\$',
      rating: 4.3,
      reviewCount: 1250,
      categories: [
        Category(alias: 'mexican', title: 'Mexican'),
        Category(alias: 'cocktailbars', title: 'Cocktail Bars'),
      ],
      hours: {
        'Monday': 'Closed',
        'Tuesday': '5:00 PM - 10:00 PM',
        'Wednesday': '5:00 PM - 10:00 PM',
        'Thursday': '5:00 PM - 10:00 PM',
        'Friday': '5:00 PM - 11:00 PM',
        'Saturday': '5:00 PM - 11:00 PM',
        'Sunday': '5:00 PM - 10:00 PM',
      },
      specialNotes: "Incredible contemporary Mexican with a focus on masa. Don't miss the suadero tacos!",
      expectedWait: '30-45 minutes',
      dressCode: 'Casual',
      parkingInfo: 'Street parking available, arrive early for best spots',
      lastSyncedAt: DateTime.now().subtract(const Duration(hours: 2)),
      rsvpCount: 0,
    );
  }

  /// Get all restaurants (tries API first, falls back to mock)
  static Future<List<Restaurant>> getAllRestaurants() async {
    try {
      return await ApiService.getRestaurants();
    } catch (e) {
      print('API unavailable, using mock restaurants: $e');
      return getAllRestaurantsMock();
    }
  }

  /// Mock restaurants data
  static List<Restaurant> getAllRestaurantsMock() {
    return [
      getFeaturedRestaurantMock(),
      Restaurant(
        id: 'restaurant_2',
        yelpId: 'franklin-barbecue-austin',
        name: 'Franklin Barbecue',
        address: '900 E 11th St',
        city: 'Austin',
        state: 'TX',
        zipCode: '78702',
        latitude: 30.2707,
        longitude: -97.7261,
        phone: '(512) 653-1187',
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop',
        yelpUrl: 'https://www.yelp.com/biz/franklin-barbecue-austin',
        price: '\$\$',
        rating: 4.9,
        reviewCount: 2800,
        categories: [
          Category(alias: 'bbq', title: 'Barbeque'),
          Category(alias: 'smokehouse', title: 'Smokehouse'),
        ],
        hours: {
          'Monday': 'Closed',
          'Tuesday': '11:00 AM - 2:00 PM',
          'Wednesday': '11:00 AM - 2:00 PM',
          'Thursday': '11:00 AM - 2:00 PM',
          'Friday': '11:00 AM - 2:00 PM',
          'Saturday': '11:00 AM - 2:00 PM',
          'Sunday': '11:00 AM - 2:00 PM',
        },
        specialNotes: 'World-renowned BBQ joint famous for its brisket and long lines.',
        expectedWait: '60-90 minutes',
        dressCode: 'Casual',
        parkingInfo: 'Limited street parking, arrive early',
      ),
      Restaurant(
        id: 'restaurant_3',
        yelpId: 'uchi-austin',
        name: 'Uchi',
        address: '801 S Lamar Blvd',
        city: 'Austin',
        state: 'TX',
        zipCode: '78704',
        latitude: 30.2649,
        longitude: -97.7430,
        phone: '(512) 916-4808',
        imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
        yelpUrl: 'https://www.yelp.com/biz/uchi-austin',
        price: '\$\$\$\$',
        rating: 4.7,
        reviewCount: 1950,
        categories: [
          Category(alias: 'japanese', title: 'Japanese'),
          Category(alias: 'sushi', title: 'Sushi Bars'),
        ],
        hours: {
          'Monday': '5:00 PM - 10:00 PM',
          'Tuesday': '5:00 PM - 10:00 PM',
          'Wednesday': '5:00 PM - 10:00 PM',
          'Thursday': '5:00 PM - 10:00 PM',
          'Friday': '5:00 PM - 11:00 PM',
          'Saturday': '5:00 PM - 11:00 PM',
          'Sunday': '5:00 PM - 10:00 PM',
        },
        specialNotes: 'Upscale sushi restaurant with innovative Japanese cuisine and artistic presentation.',
        expectedWait: '45-60 minutes',
        dressCode: 'Smart Casual',
        parkingInfo: 'Valet parking available, street parking limited',
      ),
    ];
  }

  /// Get RSVP counts (tries API first, falls back to mock)
  static Future<Map<String, int>> getRSVPCounts(String restaurantId) async {
    try {
      return await ApiService.getRSVPCounts(restaurantId);
    } catch (e) {
      print('API unavailable, using mock RSVP counts: $e');
      return {
        'Thursday': 31,
        'Friday': 45,
        'Saturday': 52,
        'Sunday': 28,
      };
    }
  }

  static List<String> getDaysOfWeek() {
    // Limited to Thursday-Sunday to concentrate users and increase social interactions
    return ['Thursday', 'Friday', 'Saturday', 'Sunday'];
  }
}
