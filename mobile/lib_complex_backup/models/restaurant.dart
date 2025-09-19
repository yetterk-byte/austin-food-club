class Restaurant {
  final String id;
  final String name;
  final String description;
  final String cuisine;
  final String address;
  final String imageUrl;
  final double rating;
  final String priceRange;
  final Map<String, dynamic> hours;
  final List<String> highlights;
  final DateTime? featuredWeek;
  final bool isFeatured;

  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisine,
    required this.address,
    required this.imageUrl,
    required this.rating,
    required this.priceRange,
    this.hours = const {},
    this.highlights = const [],
    this.featuredWeek,
    this.isFeatured = false,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cuisine: json['cuisine'] as String,
      address: json['address'] as String,
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      priceRange: json['priceRange'] as String,
      hours: Map<String, dynamic>.from(json['hours'] as Map? ?? {}),
      highlights: List<String>.from(json['highlights'] as List? ?? []),
      featuredWeek: json['featuredWeek'] != null 
          ? DateTime.parse(json['featuredWeek'] as String)
          : null,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cuisine': cuisine,
      'address': address,
      'imageUrl': imageUrl,
      'rating': rating,
      'priceRange': priceRange,
      'hours': hours,
      'highlights': highlights,
      'featuredWeek': featuredWeek?.toIso8601String(),
      'isFeatured': isFeatured,
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? cuisine,
    String? address,
    String? imageUrl,
    double? rating,
    String? priceRange,
    Map<String, dynamic>? hours,
    List<String>? highlights,
    DateTime? featuredWeek,
    bool? isFeatured,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cuisine: cuisine ?? this.cuisine,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      priceRange: priceRange ?? this.priceRange,
      hours: hours ?? this.hours,
      highlights: highlights ?? this.highlights,
      featuredWeek: featuredWeek ?? this.featuredWeek,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  // Helper methods
  bool get isOpenNow {
    final now = DateTime.now();
    final dayOfWeek = _getDayOfWeek(now.weekday);
    final todayHours = hours[dayOfWeek] as Map<String, dynamic>?;
    
    if (todayHours == null) return false;
    
    final openTime = todayHours['open'] as String?;
    final closeTime = todayHours['close'] as String?;
    
    if (openTime == null || closeTime == null) return false;
    
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return currentTime.compareTo(openTime) >= 0 && currentTime.compareTo(closeTime) <= 0;
  }

  String _getDayOfWeek(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  String get formattedHours {
    if (hours.isEmpty) return 'Hours not available';
    
    final today = DateTime.now();
    final dayOfWeek = _getDayOfWeek(today.weekday);
    final todayHours = hours[dayOfWeek] as Map<String, dynamic>?;
    
    if (todayHours == null) return 'Hours not available';
    
    final openTime = todayHours['open'] as String?;
    final closeTime = todayHours['close'] as String?;
    
    if (openTime == null || closeTime == null) return 'Hours not available';
    
    return '$openTime - $closeTime';
  }

  String get priceSymbols {
    switch (priceRange.toLowerCase()) {
      case 'budget':
      case '\$':
        return '\$';
      case 'moderate':
      case '\$\$':
        return '\$\$';
      case 'expensive':
      case '\$\$\$':
        return '\$\$\$';
      case 'very expensive':
      case '\$\$\$\$':
        return '\$\$\$\$';
      default:
        return priceRange;
    }
  }

  String get ratingDisplay {
    return rating.toStringAsFixed(1);
  }

  List<String> get topHighlights {
    return highlights.take(3).toList();
  }

  bool get hasHighlights => highlights.isNotEmpty;
  bool get isCurrentlyFeatured => isFeatured && featuredWeek != null;
  
  String get shortDescription {
    if (description.length <= 100) return description;
    return '${description.substring(0, 97)}...';
  }

  // Validation methods
  bool get isValidRating => rating >= 0.0 && rating <= 5.0;
  bool get hasValidImage => imageUrl.isNotEmpty;
  bool get hasValidAddress => address.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Restaurant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, cuisine: $cuisine, rating: $rating)';
  }
}