import 'rsvp.dart';
import 'verified_visit.dart';

class User {
  final String id;
  final String? phoneNumber;
  final String? email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;
  final List<RSVP> rsvps;
  final List<VerifiedVisit> verifiedVisits;
  final int totalVisits;
  final double averageRating;

  const User({
    required this.id,
    this.phoneNumber,
    this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
    this.rsvps = const [],
    this.verifiedVisits = const [],
    this.totalVisits = 0,
    this.averageRating = 0.0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rsvps: (json['rsvps'] as List<dynamic>?)
          ?.map((e) => RSVP.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      verifiedVisits: (json['verifiedVisits'] as List<dynamic>?)
          ?.map((e) => VerifiedVisit.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      totalVisits: json['totalVisits'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'rsvps': rsvps.map((e) => e.toJson()).toList(),
      'verifiedVisits': verifiedVisits.map((e) => e.toJson()).toList(),
      'totalVisits': totalVisits,
      'averageRating': averageRating,
    };
  }

  User copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    List<RSVP>? rsvps,
    List<VerifiedVisit>? verifiedVisits,
    int? totalVisits,
    double? averageRating,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      rsvps: rsvps ?? this.rsvps,
      verifiedVisits: verifiedVisits ?? this.verifiedVisits,
      totalVisits: totalVisits ?? this.totalVisits,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  // Helper methods
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasPhoneNumber => phoneNumber != null && phoneNumber!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
  
  String get displayName => name.isNotEmpty ? name : 'User';
  
  String get initials {
    if (name.isEmpty) return 'U';
    final names = name.split(' ');
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[1][0]}'.toUpperCase();
  }

  List<RSVP> get activeRsvps => rsvps.where((rsvp) => rsvp.status == 'going').toList();
  List<RSVP> get pendingRsvps => rsvps.where((rsvp) => rsvp.status == 'maybe').toList();
  
  List<VerifiedVisit> get recentVisits {
    final sortedVisits = List<VerifiedVisit>.from(verifiedVisits);
    sortedVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    return sortedVisits.take(5).toList();
  }

  double get calculatedAverageRating {
    if (verifiedVisits.isEmpty) return 0.0;
    final total = verifiedVisits.fold(0.0, (sum, visit) => sum + visit.rating);
    return total / verifiedVisits.length;
  }

  int get thisMonthVisits {
    final now = DateTime.now();
    return verifiedVisits.where((visit) {
      return visit.visitDate.year == now.year && 
             visit.visitDate.month == now.month;
    }).length;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, totalVisits: $totalVisits)';
  }
}