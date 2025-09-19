import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/friend.dart';
import '../../widgets/common/star_rating.dart';
import '../../services/navigation_service.dart';

class SocialFeedItemWidget extends StatefulWidget {
  final SocialFeedItem item;
  final VoidCallback? onLike;
  final VoidCallback? onUnlike;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  const SocialFeedItemWidget({
    super.key,
    required this.item,
    this.onLike,
    this.onUnlike,
    this.onTap,
    this.onShare,
  });

  @override
  State<SocialFeedItemWidget> createState() => _SocialFeedItemWidgetState();
}

class _SocialFeedItemWidgetState extends State<SocialFeedItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));

    _likeOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            
            // Content
            _buildContent(),
            
            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade600,
            backgroundImage: widget.item.userProfileImage != null
                ? NetworkImage(widget.item.userProfileImage!)
                : null,
            child: widget.item.userProfileImage == null
                ? Icon(
                    Icons.person,
                    color: Colors.grey.shade400,
                    size: 20,
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getActivityText(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Time
          Text(
            _formatTime(widget.item.createdAt),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.item.type) {
      case SocialFeedItemType.verifiedVisit:
        return _buildVerifiedVisitContent();
      case SocialFeedItemType.achievement:
        return _buildAchievementContent();
      case SocialFeedItemType.newFriend:
        return _buildNewFriendContent();
      case SocialFeedItemType.milestone:
        return _buildMilestoneContent();
    }
  }

  Widget _buildVerifiedVisitContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Restaurant image
        if (widget.item.visitPhotoUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
              right: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                widget.item.visitPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade700,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant name
              if (widget.item.restaurantName != null)
                Text(
                  widget.item.restaurantName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Rating
              if (widget.item.rating != null)
                Row(
                  children: [
                    StarRatingVariants.small(
                      rating: widget.item.rating!,
                      readOnly: true,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.item.rating!.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              
              // Review text
              if (widget.item.reviewText != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.item.reviewText!,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.2),
              Colors.deepOrange.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.orange,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievement Unlocked!',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Earned a new badge for their food adventures',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewFriendContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.people,
              color: Colors.blue,
              size: 24,
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Text(
                'Joined Austin Food Club! Welcome to the community.',
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.2),
              Colors.indigo.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.purple.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.purple,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Milestone Reached!',
                    style: TextStyle(
                      color: Colors.purple.shade300,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hit a major milestone in their food journey',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Like button
          AnimatedBuilder(
            animation: _likeAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _likeScaleAnimation.value,
                child: GestureDetector(
                  onTap: _handleLikeTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.item.isLikedByCurrentUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.item.isLikedByCurrentUser
                            ? Colors.red
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.item.likesCount.toString(),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(width: 24),
          
          // Share button
          GestureDetector(
            onTap: widget.onShare,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.share,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Share',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Restaurant link (for verified visits)
          if (widget.item.type == SocialFeedItemType.verifiedVisit &&
              widget.item.restaurantId != null)
            GestureDetector(
              onTap: () => NavigationService.goToRestaurantDetails(
                restaurantId: widget.item.restaurantId!,
              ),
              child: Text(
                'View Restaurant',
                style: TextStyle(
                  color: Colors.orange.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleLikeTap() {
    HapticFeedback.lightImpact();
    
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    if (widget.item.isLikedByCurrentUser) {
      widget.onUnlike?.call();
    } else {
      widget.onLike?.call();
    }
  }

  String _getActivityText() {
    switch (widget.item.type) {
      case SocialFeedItemType.verifiedVisit:
        return 'verified a visit';
      case SocialFeedItemType.achievement:
        return 'unlocked an achievement';
      case SocialFeedItemType.newFriend:
        return 'joined Austin Food Club';
      case SocialFeedItemType.milestone:
        return 'reached a milestone';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

