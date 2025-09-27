import 'user.dart';
import 'restaurant.dart';

class Friend {
  final String id;
  final String userId;
  final String friendId;
  final DateTime createdAt;
  final User friendUser;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
    required this.friendUser,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] ?? '',
      userId: json['userId']?.toString() ?? '',
      friendId: json['friendId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      friendUser: User.fromJson(json['friendUser'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'createdAt': createdAt.toIso8601String(),
      'friendUser': friendUser.toJson(),
    };
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final User fromUser;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    required this.fromUser,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? '',
      fromUserId: json['fromUserId']?.toString() ?? '',
      toUserId: json['toUserId']?.toString() ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      fromUser: User.fromJson(json['fromUser'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'fromUser': fromUser.toJson(),
    };
  }
}

class SocialFeedItem {
  final String id;
  final String userId;
  final String type; // 'verified_visit', 'rsvp', 'new_friend', 'wishlist_add'
  final DateTime createdAt;
  final User user;
  final Restaurant? restaurant;
  final double? rating;
  final String? photoUrl;
  final String? description;
  final String? rsvpDay; // Day of the week for RSVP (e.g., 'Monday', 'Friday')

  SocialFeedItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.createdAt,
    required this.user,
    this.restaurant,
    this.rating,
    this.photoUrl,
    this.description,
    this.rsvpDay,
  });

  factory SocialFeedItem.fromJson(Map<String, dynamic> json) {
    return SocialFeedItem(
      id: json['id'] ?? '',
      userId: json['userId']?.toString() ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      user: User.fromJson(json['user'] ?? {}),
      restaurant: json['restaurant'] != null ? Restaurant.fromJson(json['restaurant']) : null,
      rating: json['rating']?.toDouble(),
      photoUrl: json['photoUrl'],
      description: json['description'],
      rsvpDay: json['rsvpDay'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'user': user.toJson(),
      'restaurant': restaurant?.toJson(),
      'rating': rating,
      'photoUrl': photoUrl,
      'description': description,
      'rsvpDay': rsvpDay,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}