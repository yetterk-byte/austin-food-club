class RSVP {
  final String id;
  final String userId;
  final String restaurantId;
  final String day;
  final DateTime createdAt;
  final String status; // 'going', 'maybe', 'not_going'

  RSVP({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.day,
    required this.createdAt,
    required this.status,
  });

  factory RSVP.fromJson(Map<String, dynamic> json) {
    return RSVP(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      day: json['day'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'going',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'day': day,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}