class Friend {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? profileImageUrl;
  final DateTime joinedDate;
  final int totalVisits;
  final double averageRating;
  final List<String> favoriteCuisines;
  final int currentStreak;
  final DateTime? lastVisitDate;

  const Friend({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.profileImageUrl,
    required this.joinedDate,
    this.totalVisits = 0,
    this.averageRating = 0.0,
    this.favoriteCuisines = const [],
    this.currentStreak = 0,
    this.lastVisitDate,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      totalVisits: json['totalVisits'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      favoriteCuisines: List<String>.from(json['favoriteCuisines'] as List? ?? []),
      currentStreak: json['currentStreak'] as int? ?? 0,
      lastVisitDate: json['lastVisitDate'] != null 
          ? DateTime.parse(json['lastVisitDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'joinedDate': joinedDate.toIso8601String(),
      'totalVisits': totalVisits,
      'averageRating': averageRating,
      'favoriteCuisines': favoriteCuisines,
      'currentStreak': currentStreak,
      'lastVisitDate': lastVisitDate?.toIso8601String(),
    };
  }

  Friend copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? profileImageUrl,
    DateTime? joinedDate,
    int? totalVisits,
    double? averageRating,
    List<String>? favoriteCuisines,
    int? currentStreak,
    DateTime? lastVisitDate,
  }) {
    return Friend(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      totalVisits: totalVisits ?? this.totalVisits,
      averageRating: averageRating ?? this.averageRating,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      currentStreak: currentStreak ?? this.currentStreak,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friend && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String? fromUserProfileImage;
  final String? fromUserPhone;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    this.fromUserProfileImage,
    this.fromUserPhone,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      fromUserProfileImage: json['fromUserProfileImage'] as String?,
      fromUserPhone: json['fromUserPhone'] as String?,
      status: FriendRequestStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'fromUserProfileImage': fromUserProfileImage,
      'fromUserPhone': fromUserPhone,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  FriendRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? fromUserProfileImage,
    String? fromUserPhone,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserProfileImage: fromUserProfileImage ?? this.fromUserProfileImage,
      fromUserPhone: fromUserPhone ?? this.fromUserPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

class SocialFeedItem {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final SocialFeedItemType type;
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantImageUrl;
  final double? rating;
  final String? reviewText;
  final String? visitPhotoUrl;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByCurrentUser;

  const SocialFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.type,
    this.restaurantId,
    this.restaurantName,
    this.restaurantImageUrl,
    this.rating,
    this.reviewText,
    this.visitPhotoUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.isLikedByCurrentUser = false,
  });

  factory SocialFeedItem.fromJson(Map<String, dynamic> json) {
    return SocialFeedItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userProfileImage: json['userProfileImage'] as String?,
      type: SocialFeedItemType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => SocialFeedItemType.verifiedVisit,
      ),
      restaurantId: json['restaurantId'] as String?,
      restaurantName: json['restaurantName'] as String?,
      restaurantImageUrl: json['restaurantImageUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewText: json['reviewText'] as String?,
      visitPhotoUrl: json['visitPhotoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likesCount: json['likesCount'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'type': type.name,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImageUrl': restaurantImageUrl,
      'rating': rating,
      'reviewText': reviewText,
      'visitPhotoUrl': visitPhotoUrl,
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
      'isLikedByCurrentUser': isLikedByCurrentUser,
    };
  }

  SocialFeedItem copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImage,
    SocialFeedItemType? type,
    String? restaurantId,
    String? restaurantName,
    String? restaurantImageUrl,
    double? rating,
    String? reviewText,
    String? visitPhotoUrl,
    DateTime? createdAt,
    int? likesCount,
    bool? isLikedByCurrentUser,
  }) {
    return SocialFeedItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      type: type ?? this.type,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      visitPhotoUrl: visitPhotoUrl ?? this.visitPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}

enum SocialFeedItemType {
  verifiedVisit,
  newFriend,
  achievement,
  milestone,
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final AchievementType type;
  final int targetValue;
  final String badgeColor;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.targetValue,
    required this.badgeColor,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      type: AchievementType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => AchievementType.visits,
      ),
      targetValue: json['targetValue'] as int,
      badgeColor: json['badgeColor'] as String,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      currentProgress: json['currentProgress'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'type': type.name,
      'targetValue': targetValue,
      'badgeColor': badgeColor,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'currentProgress': currentProgress,
    };
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    AchievementType? type,
    int? targetValue,
    String? badgeColor,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      badgeColor: badgeColor ?? this.badgeColor,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }
}

enum AchievementType {
  visits,
  cuisines,
  streak,
  rating,
  social,
}

class UserStats {
  final int totalVisits;
  final double averageRating;
  final int currentStreak;
  final int maxStreak;
  final List<String> cuisinesTried;
  final int friendsCount;
  final int achievementsUnlocked;
  final DateTime? lastVisitDate;
  final String? favoriteCuisine;
  final String? favoriteRestaurant;

  const UserStats({
    this.totalVisits = 0,
    this.averageRating = 0.0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.cuisinesTried = const [],
    this.friendsCount = 0,
    this.achievementsUnlocked = 0,
    this.lastVisitDate,
    this.favoriteCuisine,
    this.favoriteRestaurant,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalVisits: json['totalVisits'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? 0,
      cuisinesTried: List<String>.from(json['cuisinesTried'] as List? ?? []),
      friendsCount: json['friendsCount'] as int? ?? 0,
      achievementsUnlocked: json['achievementsUnlocked'] as int? ?? 0,
      lastVisitDate: json['lastVisitDate'] != null 
          ? DateTime.parse(json['lastVisitDate'] as String)
          : null,
      favoriteCuisine: json['favoriteCuisine'] as String?,
      favoriteRestaurant: json['favoriteRestaurant'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVisits': totalVisits,
      'averageRating': averageRating,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'cuisinesTried': cuisinesTried,
      'friendsCount': friendsCount,
      'achievementsUnlocked': achievementsUnlocked,
      'lastVisitDate': lastVisitDate?.toIso8601String(),
      'favoriteCuisine': favoriteCuisine,
      'favoriteRestaurant': favoriteRestaurant,
    };
  }

  UserStats copyWith({
    int? totalVisits,
    double? averageRating,
    int? currentStreak,
    int? maxStreak,
    List<String>? cuisinesTried,
    int? friendsCount,
    int? achievementsUnlocked,
    DateTime? lastVisitDate,
    String? favoriteCuisine,
    String? favoriteRestaurant,
  }) {
    return UserStats(
      totalVisits: totalVisits ?? this.totalVisits,
      averageRating: averageRating ?? this.averageRating,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      cuisinesTried: cuisinesTried ?? this.cuisinesTried,
      friendsCount: friendsCount ?? this.friendsCount,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      favoriteCuisine: favoriteCuisine ?? this.favoriteCuisine,
      favoriteRestaurant: favoriteRestaurant ?? this.favoriteRestaurant,
    );
  }
}

