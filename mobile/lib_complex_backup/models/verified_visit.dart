import 'restaurant.dart';

class VerifiedVisit {
  final String id;
  final String userId;
  final String restaurantId;
  final Restaurant? restaurant;
  final String photoUrl;
  final int rating; // 1-5
  final String? review;
  final DateTime visitDate;
  final DateTime createdAt;

  const VerifiedVisit({
    required this.id,
    required this.userId,
    required this.restaurantId,
    this.restaurant,
    required this.photoUrl,
    required this.rating,
    this.review,
    required this.visitDate,
    required this.createdAt,
  });

  factory VerifiedVisit.fromJson(Map<String, dynamic> json) {
    return VerifiedVisit(
      id: json['id'] as String,
      userId: json['userId'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurant: json['restaurant'] != null 
          ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
      photoUrl: json['photoUrl'] as String,
      rating: json['rating'] as int,
      review: json['review'] as String?,
      visitDate: DateTime.parse(json['visitDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurant': restaurant?.toJson(),
      'photoUrl': photoUrl,
      'rating': rating,
      'review': review,
      'visitDate': visitDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  VerifiedVisit copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    Restaurant? restaurant,
    String? photoUrl,
    int? rating,
    String? review,
    DateTime? visitDate,
    DateTime? createdAt,
  }) {
    return VerifiedVisit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurant: restaurant ?? this.restaurant,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      visitDate: visitDate ?? this.visitDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool get hasReview => review != null && review!.isNotEmpty;
  bool get isHighRating => rating >= 4;
  bool get isLowRating => rating <= 2;
  bool get isPerfectRating => rating == 5;
  
  String get ratingDisplay {
    return '$rating/5';
  }
  
  String get starsDisplay {
    return '★' * rating + '☆' * (5 - rating);
  }
  
  String get formattedVisitDate {
    return '${visitDate.day}/${visitDate.month}/${visitDate.year}';
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(visitDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  String get shortReview {
    if (!hasReview) return '';
    if (review!.length <= 50) return review!;
    return '${review!.substring(0, 47)}...';
  }
  
  bool get hasRestaurant => restaurant != null;
  
  // Validation methods
  bool get isValidRating => rating >= 1 && rating <= 5;
  bool get hasValidPhoto => photoUrl.isNotEmpty;
  
  // Rating helpers
  String get ratingDescription {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }
  
  // Date helpers
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(visitDate);
    return difference.inDays <= 7;
  }
  
  bool get isThisMonth {
    final now = DateTime.now();
    return visitDate.year == now.year && visitDate.month == now.month;
  }
  
  bool get isThisYear {
    final now = DateTime.now();
    return visitDate.year == now.year;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerifiedVisit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VerifiedVisit(id: $id, userId: $userId, restaurantId: $restaurantId, rating: $rating, visitDate: $visitDate)';
  }
}

