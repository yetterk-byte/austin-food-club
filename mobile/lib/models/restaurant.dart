class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String address;
  final String cuisineType;
  final double rating;
  final String priceRange;
  final String waitTime;
  final List<String> specialties;
  final Map<String, String> hours;
  final String googleMapsUrl;
  final bool isFeatured;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.cuisineType,
    required this.rating,
    required this.priceRange,
    required this.waitTime,
    required this.specialties,
    required this.hours,
    required this.googleMapsUrl,
    this.isFeatured = false,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      address: json['address'] ?? '',
      cuisineType: json['cuisineType'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      priceRange: json['priceRange'] ?? '',
      waitTime: json['waitTime'] ?? '',
      specialties: List<String>.from(json['specialties'] ?? []),
      hours: Map<String, String>.from(json['hours'] ?? {}),
      googleMapsUrl: json['googleMapsUrl'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'cuisineType': cuisineType,
      'rating': rating,
      'priceRange': priceRange,
      'waitTime': waitTime,
      'specialties': specialties,
      'hours': hours,
      'googleMapsUrl': googleMapsUrl,
      'isFeatured': isFeatured,
    };
  }
}