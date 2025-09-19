import 'restaurant.dart';

class RSVP {
  final String id;
  final String userId;
  final String restaurantId;
  final Restaurant? restaurant;
  final String dayOfWeek;
  final DateTime rsvpDate;
  final String status; // 'going', 'maybe', 'not_going'
  final bool isVerified;

  const RSVP({
    required this.id,
    required this.userId,
    required this.restaurantId,
    this.restaurant,
    required this.dayOfWeek,
    required this.rsvpDate,
    required this.status,
    this.isVerified = false,
  });

  factory RSVP.fromJson(Map<String, dynamic> json) {
    return RSVP(
      id: json['id'] as String,
      userId: json['userId'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurant: json['restaurant'] != null 
          ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
      dayOfWeek: json['dayOfWeek'] as String,
      rsvpDate: DateTime.parse(json['rsvpDate'] as String),
      status: json['status'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurant': restaurant?.toJson(),
      'dayOfWeek': dayOfWeek,
      'rsvpDate': rsvpDate.toIso8601String(),
      'status': status,
      'isVerified': isVerified,
    };
  }

  RSVP copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    Restaurant? restaurant,
    String? dayOfWeek,
    DateTime? rsvpDate,
    String? status,
    bool? isVerified,
  }) {
    return RSVP(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurant: restaurant ?? this.restaurant,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      rsvpDate: rsvpDate ?? this.rsvpDate,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // Helper methods
  bool get isGoing => status == 'going';
  bool get isMaybe => status == 'maybe';
  bool get isNotGoing => status == 'not_going';
  
  bool get canBeVerified {
    if (!isGoing) return false;
    final now = DateTime.now();
    final daysDifference = rsvpDate.difference(now).inDays;
    return daysDifference <= 0; // Can verify on or after the RSVP date
  }
  
  bool get isPastDue {
    final now = DateTime.now();
    return rsvpDate.isBefore(now);
  }
  
  String get statusDisplay {
    switch (status) {
      case 'going':
        return 'Going';
      case 'maybe':
        return 'Maybe';
      case 'not_going':
        return 'Not Going';
      default:
        return 'Unknown';
    }
  }
  
  String get dayDisplay {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return 'Monday';
      case 'tuesday':
        return 'Tuesday';
      case 'wednesday':
        return 'Wednesday';
      case 'thursday':
        return 'Thursday';
      case 'friday':
        return 'Friday';
      case 'saturday':
        return 'Saturday';
      case 'sunday':
        return 'Sunday';
      default:
        return dayOfWeek;
    }
  }
  
  String get formattedDate {
    return '${rsvpDate.day}/${rsvpDate.month}/${rsvpDate.year}';
  }
  
  String get timeUntilRsvp {
    final now = DateTime.now();
    final difference = rsvpDate.difference(now);
    
    if (difference.isNegative) {
      return 'Past due';
    }
    
    final days = difference.inDays;
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return 'Tomorrow';
    } else if (days < 7) {
      return 'In $days days';
    } else {
      final weeks = (days / 7).floor();
      return 'In $weeks week${weeks > 1 ? 's' : ''}';
    }
  }
  
  // Validation methods
  bool get isValidStatus {
    const validStatuses = ['going', 'maybe', 'not_going'];
    return validStatuses.contains(status);
  }
  
  bool get hasRestaurant => restaurant != null;
  
  // Status change methods
  RSVP markAsGoing() => copyWith(status: 'going');
  RSVP markAsMaybe() => copyWith(status: 'maybe');
  RSVP markAsNotGoing() => copyWith(status: 'not_going');
  RSVP markAsVerified() => copyWith(isVerified: true);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RSVP && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RSVP(id: $id, userId: $userId, restaurantId: $restaurantId, status: $status, dayOfWeek: $dayOfWeek)';
  }
}

