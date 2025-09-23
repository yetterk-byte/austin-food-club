import '../models/restaurant.dart';
import 'api_service.dart';

class MockDataService {
  static Future<Restaurant?> getFeaturedRestaurant() async {
    // Return mock featured restaurant
    return Restaurant(
      id: '1',
      yelpId: 'mock-yelp-id',
      name: 'Tsuke Edomae',
      address: '123 Main St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
      latitude: 30.2672,
      longitude: -97.7431,
      phone: '+1-512-555-0123',
      price: r'$$$$',
      rating: 4.9,
      reviewCount: 150,
      imageUrl: 'https://images.unsplash.com/photo-1579952363873-27d3bfad9c0d?w=800&h=600&fit=crop',
      categories: [
        Category(alias: 'japanese', title: 'Japanese'),
        Category(alias: 'sushi', title: 'Sushi'),
        Category(alias: 'fine_dining', title: 'Fine Dining'),
      ],
    );
  }

  static Future<List<Restaurant>> getAllRestaurantsMock() async {
    return [
      Restaurant(
        id: '1',
        yelpId: 'mock-yelp-1',
        name: 'Tsuke Edomae',
        address: '123 Main St',
        city: 'Austin',
        state: 'TX',
        zipCode: '78701',
        latitude: 30.2672,
        longitude: -97.7431,
        phone: '+1-512-555-0123',
        price: r'$$$$',
        rating: 4.9,
        reviewCount: 150,
        imageUrl: 'https://images.unsplash.com/photo-1579952363873-27d3bfad9c0d?w=800&h=600&fit=crop',
        categories: [
          Category(alias: 'japanese', title: 'Japanese'),
          Category(alias: 'sushi', title: 'Sushi'),
          Category(alias: 'fine_dining', title: 'Fine Dining'),
        ],
      ),
      Restaurant(
        id: '2',
        yelpId: 'mock-yelp-2',
        name: 'Franklin Barbecue',
        address: '900 E 11th St',
        city: 'Austin',
        state: 'TX',
        zipCode: '78702',
        latitude: 30.2705,
        longitude: -97.7320,
        phone: '+1-512-653-1187',
        price: r'$$$',
        rating: 4.8,
        reviewCount: 2500,
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop',
        categories: [
          Category(alias: 'barbecue', title: 'Barbecue'),
          Category(alias: 'american', title: 'American'),
          Category(alias: 'meat', title: 'Meat'),
        ],
      ),
      Restaurant(
        id: '3',
        yelpId: 'mock-yelp-3',
        name: 'Uchi',
        address: '801 S Lamar Blvd',
        city: 'Austin',
        state: 'TX',
        zipCode: '78704',
        latitude: 30.2500,
        longitude: -97.7667,
        phone: '+1-512-916-4808',
        price: r'$$$$',
        rating: 4.7,
        reviewCount: 1800,
        imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
        categories: [
          Category(alias: 'japanese', title: 'Japanese'),
          Category(alias: 'sushi', title: 'Sushi'),
          Category(alias: 'asian_fusion', title: 'Asian Fusion'),
        ],
      ),
    ];
  }

  static List<String> getDaysOfWeek() {
    return ['Thursday', 'Friday', 'Saturday', 'Sunday'];
  }

  static Future<Map<String, int>> getRSVPCounts(String restaurantId) async {
    try {
      final data = await ApiService.getRSVPCounts(restaurantId);
      final Map<String, int> counts = {};
      
      for (final item in data) {
        if (item['day'] != null && item['count'] != null) {
          counts[item['day']] = item['count'];
        }
      }
      
      return counts;
    } catch (e) {
      print('❌ MockDataService: Error getting RSVP counts: $e');
      // Return mock data as fallback
      return {
        'Thursday': 7,
        'Friday': 12,
        'Saturday': 15,
        'Sunday': 8,
      };
    }
  }
}
