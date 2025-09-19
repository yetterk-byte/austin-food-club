class AppConstants {
  // API Configuration - Connect to your existing Express backend
  static const String baseUrl = 'http://localhost:3001/api';
  static const String restaurantsEndpoint = '/restaurants';
  static const String rsvpEndpoint = '/rsvp';
  static const String verifiedVisitsEndpoint = '/verified-visits';
  static const String wishlistEndpoint = '/wishlist';
  
  // Supabase Configuration
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // App Configuration
  static const String appName = 'Austin Food Club';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String rsvpDataKey = 'rsvp_data';
  static const String wishlistDataKey = 'wishlist_data';
  
  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const int imageQuality = 85;
  static const int thumbnailSize = 300;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxReviewLength = 500;
  
  // Rating
  static const int minRating = 1;
  static const int maxRating = 5;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // RSVP Status
  static const String rsvpGoing = 'going';
  static const String rsvpMaybe = 'maybe';
  static const String rsvpNotGoing = 'not_going';
  
  // Days of Week
  static const List<String> daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  
  // Price Ranges
  static const List<String> priceRanges = [
    '\$',
    '\$\$',
    '\$\$\$',
    '\$\$\$\$',
  ];
  
  // Cuisine Types
  static const List<String> cuisineTypes = [
    'American',
    'Italian',
    'Mexican',
    'Asian',
    'Mediterranean',
    'Indian',
    'Thai',
    'Chinese',
    'Japanese',
    'French',
    'BBQ',
    'Seafood',
    'Steakhouse',
    'Pizza',
    'Burgers',
    'Tacos',
    'Sushi',
    'Other',
  ];
}