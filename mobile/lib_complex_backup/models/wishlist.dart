import 'restaurant.dart';

class WishlistItem {
  final String id;
  final String userId;
  final String restaurantId;
  final Restaurant? restaurant;
  final DateTime createdAt;
  final DateTime? lastVisited;
  final int visitCount;
  final bool isFavorited;

  const WishlistItem({
    required this.id,
    required this.userId,
    required this.restaurantId,
    this.restaurant,
    required this.createdAt,
    this.lastVisited,
    this.visitCount = 0,
    this.isFavorited = false,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurant: json['restaurant'] != null 
          ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastVisited: json['lastVisited'] != null 
          ? DateTime.parse(json['lastVisited'] as String)
          : null,
      visitCount: json['visitCount'] as int? ?? 0,
      isFavorited: json['isFavorited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurant': restaurant?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastVisited': lastVisited?.toIso8601String(),
      'visitCount': visitCount,
      'isFavorited': isFavorited,
    };
  }

  WishlistItem copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    Restaurant? restaurant,
    DateTime? createdAt,
    DateTime? lastVisited,
    int? visitCount,
    bool? isFavorited,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurant: restaurant ?? this.restaurant,
      createdAt: createdAt ?? this.createdAt,
      lastVisited: lastVisited ?? this.lastVisited,
      visitCount: visitCount ?? this.visitCount,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  // Helper methods
  bool get hasRestaurant => restaurant != null;
  bool get hasBeenVisited => lastVisited != null;
  bool get isRecentlyVisited {
    if (lastVisited == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastVisited!);
    return difference.inDays <= 30; // Visited within last 30 days
  }
  
  String get timeSinceAdded {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
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
  
  String get timeSinceLastVisit {
    if (lastVisited == null) return 'Never visited';
    
    final now = DateTime.now();
    final difference = now.difference(lastVisited!);
    
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
  
  String get visitCountDisplay {
    if (visitCount == 0) return 'Not visited';
    if (visitCount == 1) return 'Visited once';
    return 'Visited $visitCount times';
  }
  
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
  
  String get formattedLastVisitedDate {
    if (lastVisited == null) return 'Never';
    return '${lastVisited!.day}/${lastVisited!.month}/${lastVisited!.year}';
  }
  
  // Status helpers
  String get status {
    if (visitCount == 0) return 'Not visited';
    if (isRecentlyVisited) return 'Recently visited';
    return 'Visited before';
  }
  
  bool get isFrequentVisitor => visitCount >= 3;
  bool get isNewAddition {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 7; // Added within last 7 days
  }
  
  // Action methods
  WishlistItem markAsVisited() {
    return copyWith(
      lastVisited: DateTime.now(),
      visitCount: visitCount + 1,
    );
  }
  
  WishlistItem toggleFavorite() {
    return copyWith(isFavorited: !isFavorited);
  }
  
  WishlistItem removeFromWishlist() {
    return copyWith(isFavorited: false);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WishlistItem(id: $id, userId: $userId, restaurantId: $restaurantId, visitCount: $visitCount)';
  }
}

