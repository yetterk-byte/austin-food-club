import '../models/restaurant.dart';
import '../models/rsvp.dart';
import 'api_service.dart';

class MockDataService {
  /// Get featured restaurant (tries API first, falls back to mock)
  static Future<Restaurant> getFeaturedRestaurant() async {
    try {
      // Try to get from API first
      return await ApiService.getFeaturedRestaurant();
    } catch (e) {
      print('API unavailable, using mock data: $e');
      // Fallback to mock data
      return getFeaturedRestaurantMock();
    }
  }

  /// Mock featured restaurant data
  static Restaurant getFeaturedRestaurantMock() {
    return Restaurant(
      id: 'test-restaurant-1', // Use the actual restaurant ID from backend
      name: 'Suerte',
      description: 'Contemporary Mexican cuisine with handmade tortillas, fresh ingredients, and creative cocktails in a vibrant East Austin setting.',
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
      address: '1800 E 6th St, Austin, TX 78702',
      cuisineType: 'Mexican',
      rating: 4.8,
      priceRange: '\$\$\$',
      waitTime: '30-45 min',
      specialties: ['Handmade Tortillas', 'Mezcal Cocktails', 'Fresh Ceviche', 'Wood-fired Dishes'],
      hours: {
        'Monday': 'Closed',
        'Tuesday': '5:00 PM - 10:00 PM',
        'Wednesday': '5:00 PM - 10:00 PM',
        'Thursday': '5:00 PM - 10:00 PM',
        'Friday': '5:00 PM - 11:00 PM',
        'Saturday': '5:00 PM - 11:00 PM',
        'Sunday': '5:00 PM - 10:00 PM',
      },
      googleMapsUrl: 'https://maps.google.com/?q=Suerte+Austin',
      isFeatured: true,
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
        name: 'Franklin Barbecue',
        description: 'World-renowned BBQ joint famous for its brisket and long lines.',
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop',
        address: '900 E 11th St, Austin, TX 78702',
        cuisineType: 'BBQ',
        rating: 4.9,
        priceRange: '\$\$',
        waitTime: '60-90 min',
        specialties: ['Brisket', 'Pulled Pork', 'Sausage', 'Ribs'],
        hours: {
          'Monday': 'Closed',
          'Tuesday': '11:00 AM - 2:00 PM',
          'Wednesday': '11:00 AM - 2:00 PM',
          'Thursday': '11:00 AM - 2:00 PM',
          'Friday': '11:00 AM - 2:00 PM',
          'Saturday': '11:00 AM - 2:00 PM',
          'Sunday': '11:00 AM - 2:00 PM',
        },
        googleMapsUrl: 'https://maps.google.com/?q=Franklin+Barbecue+Austin',
      ),
      Restaurant(
        id: 'restaurant_3',
        name: 'Uchi',
        description: 'Upscale sushi restaurant with innovative Japanese cuisine and artistic presentation.',
        imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
        address: '801 S Lamar Blvd, Austin, TX 78704',
        cuisineType: 'Japanese',
        rating: 4.7,
        priceRange: '\$\$\$\$',
        waitTime: '45-60 min',
        specialties: ['Omakase', 'Fresh Sashimi', 'Creative Rolls', 'Sake Pairings'],
        hours: {
          'Monday': '5:00 PM - 10:00 PM',
          'Tuesday': '5:00 PM - 10:00 PM',
          'Wednesday': '5:00 PM - 10:00 PM',
          'Thursday': '5:00 PM - 10:00 PM',
          'Friday': '5:00 PM - 11:00 PM',
          'Saturday': '5:00 PM - 11:00 PM',
          'Sunday': '5:00 PM - 10:00 PM',
        },
        googleMapsUrl: 'https://maps.google.com/?q=Uchi+Austin',
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
        'Monday': 12,
        'Tuesday': 18,
        'Wednesday': 24,
        'Thursday': 31,
        'Friday': 45,
        'Saturday': 52,
        'Sunday': 28,
      };
    }
  }

  static List<String> getDaysOfWeek() {
    return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  }
}
