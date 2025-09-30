import 'package:flutter/material.dart';

/// City Configuration for Multi-City Food Club Support
/// Manages city-specific branding, settings, and API configurations

class CityConfig {
  final String id;
  final String name;
  final String slug;
  final String displayName;
  final String state;
  final String timezone;
  final String yelpLocation;
  final int yelpRadius;
  final Color brandColor;
  final String? logoUrl;
  final String? heroImageUrl;
  final bool isActive;
  final DateTime? launchDate;

  const CityConfig({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayName,
    required this.state,
    required this.timezone,
    required this.yelpLocation,
    required this.yelpRadius,
    required this.brandColor,
    this.logoUrl,
    this.heroImageUrl,
    required this.isActive,
    this.launchDate,
  });

  factory CityConfig.fromJson(Map<String, dynamic> json) {
    return CityConfig(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      displayName: json['displayName'],
      state: json['state'],
      timezone: json['timezone'],
      yelpLocation: json['yelpLocation'],
      yelpRadius: json['yelpRadius'],
      brandColor: Color(int.parse(json['brandColor'].replaceFirst('#', '0xFF'))),
      logoUrl: json['logoUrl'],
      heroImageUrl: json['heroImageUrl'],
      isActive: json['isActive'],
      launchDate: json['launchDate'] != null ? DateTime.parse(json['launchDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'displayName': displayName,
      'state': state,
      'timezone': timezone,
      'yelpLocation': yelpLocation,
      'yelpRadius': yelpRadius,
      'brandColor': '#${brandColor.value.toRadixString(16).substring(2)}',
      'logoUrl': logoUrl,
      'heroImageUrl': heroImageUrl,
      'isActive': isActive,
      'launchDate': launchDate?.toIso8601String(),
    };
  }
}

/// Predefined city configurations
class Cities {
  static const austin = CityConfig(
    id: 'austin',
    name: 'Austin',
    slug: 'austin',
    displayName: 'Austin Food Club',
    state: 'TX',
    timezone: 'America/Chicago',
    yelpLocation: 'Austin, TX',
    yelpRadius: 24140,
    brandColor: Color(0xFF20b2aa),
    isActive: true,
  );

  static const nola = CityConfig(
    id: 'nola',
    name: 'New Orleans',
    slug: 'nola',
    displayName: 'NOLA Food Club',
    state: 'LA',
    timezone: 'America/Chicago',
    yelpLocation: 'New Orleans, LA',
    yelpRadius: 24140,
    brandColor: Color(0xFF8b4513),
    isActive: false,
  );

  static const boston = CityConfig(
    id: 'boston',
    name: 'Boston',
    slug: 'boston',
    displayName: 'Boston Food Club',
    state: 'MA',
    timezone: 'America/New_York',
    yelpLocation: 'Boston, MA',
    yelpRadius: 24140,
    brandColor: Color(0xFF0f4c75),
    isActive: false,
  );

  static const nyc = CityConfig(
    id: 'nyc',
    name: 'New York',
    slug: 'nyc',
    displayName: 'NYC Food Club',
    state: 'NY',
    timezone: 'America/New_York',
    yelpLocation: 'New York, NY',
    yelpRadius: 24140,
    brandColor: Color(0xFFff6b35),
    isActive: false,
  );

  static const List<CityConfig> all = [austin, nola, boston, nyc];
  static const List<CityConfig> active = [austin];

  static CityConfig? getBySlug(String slug) {
    try {
      return all.firstWhere((city) => city.slug == slug);
    } catch (e) {
      return null;
    }
  }

  static CityConfig get defaultCity => austin;
}

/// City selection service for managing current city context
class CityService {
  static CityConfig _currentCity = Cities.defaultCity;
  static final List<Function(CityConfig)> _listeners = [];

  static CityConfig get currentCity => _currentCity;

  static void setCurrentCity(CityConfig city) {
    if (_currentCity != city) {
      _currentCity = city;
      _notifyListeners();
    }
  }

  static void setCityBySlug(String slug) {
    final city = Cities.getBySlug(slug);
    if (city != null) {
      setCurrentCity(city);
    }
  }

  static void addListener(Function(CityConfig) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(CityConfig) listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_currentCity);
    }
  }

  /// Get API base URL with city context
  static String getApiBaseUrl() {
    // In production, this could route to city-specific subdomains
    // For now, use headers to specify city context
    return 'https://api.austinfoodclub.com';
  }

  /// Get API headers with city context
  static Map<String, String> getApiHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-City-Slug': _currentCity.slug,
    };
  }

  /// Check if a city is available/launched
  static bool isCityAvailable(String slug) {
    final city = Cities.getBySlug(slug);
    return city?.isActive ?? false;
  }

  /// Get launch message for inactive cities
  static String getLaunchMessage(String slug) {
    final city = Cities.getBySlug(slug);
    if (city == null) {
      return 'City not found';
    }
    
    if (city.isActive) {
      return '${city.displayName} is now available!';
    }
    
    return '${city.displayName} is coming soon! Stay tuned for our launch.';
  }
}

/// City-aware theme data
class CityTheme {
  static ThemeData getTheme(CityConfig city) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: city.brandColor,
      colorScheme: ColorScheme.dark(
        primary: city.brandColor,
        secondary: Colors.orange,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[900],
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }

  static Color getAccentColor(CityConfig city) {
    // Different accent colors for different cities
    switch (city.slug) {
      case 'austin':
        return Colors.orange;
      case 'nola':
        return Colors.purple;
      case 'boston':
        return Colors.red;
      case 'nyc':
        return Colors.yellow;
      default:
        return Colors.orange;
    }
  }
}
