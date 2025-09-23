class VerifiedVisit {
  final int id;
  final int userId;
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  final int rating;
  final String? imageUrl;
  final DateTime verifiedAt;
  final String citySlug;

  VerifiedVisit({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.rating,
    this.imageUrl,
    required this.verifiedAt,
    required this.citySlug,
  });

  factory VerifiedVisit.fromJson(Map<String, dynamic> json) {
    return VerifiedVisit(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      restaurantAddress: json['restaurantAddress'] ?? '',
      rating: json['rating'] ?? 0,
      imageUrl: json['imageUrl'],
      verifiedAt: DateTime.parse(json['verifiedAt'] ?? DateTime.now().toIso8601String()),
      citySlug: json['citySlug'] ?? 'austin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'rating': rating,
      'imageUrl': imageUrl,
      'verifiedAt': verifiedAt.toIso8601String(),
      'citySlug': citySlug,
    };
  }

  /// Get a formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(verifiedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get star rating as a string
  String get starRating {
    return '⭐' * rating;
  }
}
