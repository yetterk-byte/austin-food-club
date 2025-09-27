class User {
  final String id;
  final String email;
  final String? phone;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isVerified;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    required this.email,
    this.phone,
    required this.name,
    this.avatar,
    required this.createdAt,
    this.lastLoginAt,
    this.isVerified = false,
    this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      name: json['name'] ?? '',
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
      isVerified: json['isVerified'] ?? false,
      preferences: json['preferences'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isVerified': isVerified,
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? name,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      preferences: preferences ?? this.preferences,
    );
  }

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  String get memberSince {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays < 30) {
      return 'New member';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}