class Restaurant {
  final String id;
  final String yelpId;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? imageUrl;
  final String? yelpUrl;
  final String? price;
  final double? rating;
  final int? reviewCount;
  final List<Category>? categories;
  final Map<String, dynamic>? hours;
  final String? specialNotes;
  final String? expectedWait;
  final String? dressCode;
  final String? parkingInfo;
  final DateTime? lastSyncedAt;
  final int? rsvpCount;

  Restaurant({
    required this.id,
    required this.yelpId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.imageUrl,
    this.yelpUrl,
    this.price,
    this.rating,
    this.reviewCount,
    this.categories,
    this.hours,
    this.specialNotes,
    this.expectedWait,
    this.dressCode,
    this.parkingInfo,
    this.lastSyncedAt,
    this.rsvpCount,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // Handle city field - it can be either a string or an object
    String cityName = 'Austin';
    if (json['city'] is String) {
      cityName = json['city'];
    } else if (json['city'] is Map && json['city']['name'] != null) {
      cityName = json['city']['name'];
    } else if (json['cityName'] != null) {
      cityName = json['cityName'];
    }
    
    return Restaurant(
      id: json['id'],
      yelpId: json['yelpId'],
      name: json['name'],
      address: json['address'],
      city: cityName,
      state: json['state'] ?? 'TX',
      zipCode: json['zipCode']?.toString() ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      phone: json['phone'],
      imageUrl: json['imageUrl'],
      yelpUrl: json['yelpUrl'],
      price: json['price'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((c) => Category.fromJson(c))
              .toList()
          : null,
      hours: _parseHours(json['hours']),
      specialNotes: json['specialNotes'],
      expectedWait: json['expectedWait'],
      dressCode: json['dressCode'],
      parkingInfo: json['parkingInfo'],
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'])
          : null,
      rsvpCount: json['rsvps']?.length ?? 0,
    );
  }

  static Map<String, dynamic>? _parseHours(dynamic hoursData) {
    if (hoursData == null) return null;
    
    try {
      // If it's already a Map, return it
      if (hoursData is Map<String, dynamic>) {
        return hoursData;
      }
      
      // If it's a Map with different types, convert it
      if (hoursData is Map) {
        return Map<String, dynamic>.from(hoursData);
      }
      
      // If it's Yelp's complex hours format (array), convert to simple format
      if (hoursData is List && hoursData.isNotEmpty) {
        final Map<String, dynamic> simpleHours = {};
        final daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        
        // Initialize all days as closed
        for (String day in daysOfWeek) {
          simpleHours[day] = 'Closed';
        }
        
        // Parse Yelp hours format
        final hoursBlock = hoursData[0];
        if (hoursBlock is Map && hoursBlock['open'] is List) {
          final openHours = hoursBlock['open'] as List;
          
          for (var timeSlot in openHours) {
            if (timeSlot is Map) {
              final dayIndex = timeSlot['day'] as int? ?? 0;
              final start = timeSlot['start'] as String? ?? '';
              final end = timeSlot['end'] as String? ?? '';
              
              if (dayIndex >= 0 && dayIndex < daysOfWeek.length && start.isNotEmpty && end.isNotEmpty) {
                final startFormatted = _formatTime(start);
                final endFormatted = _formatTime(end);
                simpleHours[daysOfWeek[dayIndex]] = '$startFormatted - $endFormatted';
              }
            }
          }
        }
        
        return simpleHours;
      }
      
      // Fallback: return null for any other format
      return null;
    } catch (e) {
      // If parsing fails, return null rather than crashing
      return null;
    }
  }

  static String _formatTime(String time24) {
    if (time24.length != 4) return time24;
    
    try {
      final hour = int.parse(time24.substring(0, 2));
      final minute = time24.substring(2, 4);
      
      if (hour == 0) return '12:$minute AM';
      if (hour < 12) return '$hour:$minute AM';
      if (hour == 12) return '12:$minute PM';
      return '${hour - 12}:$minute PM';
    } catch (e) {
      return time24;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'yelpId': yelpId,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'imageUrl': imageUrl,
      'yelpUrl': yelpUrl,
      'price': price,
      'rating': rating,
      'reviewCount': reviewCount,
      'categories': categories?.map((c) => c.toJson()).toList(),
      'hours': hours,
      'specialNotes': specialNotes,
      'expectedWait': expectedWait,
      'dressCode': dressCode,
      'parkingInfo': parkingInfo,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'rsvpCount': rsvpCount,
    };
  }

  String get fullAddress => '$address, $city, $state $zipCode';
  
  bool get isOpenNow {
    // Implement logic to check if restaurant is currently open based on hours
    return true; // Placeholder
  }
}

class Category {
  final String alias;
  final String title;

  Category({required this.alias, required this.title});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      alias: json['alias'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alias': alias,
      'title': title,
    };
  }
}