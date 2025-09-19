import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../models/restaurant.dart';

class RestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistToggle;
  final bool isInWishlist;
  final bool showWishlistButton;
  final bool showRating;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool enableHapticFeedback;
  final String? heroTag;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.onWishlistToggle,
    this.isInWishlist = false,
    this.showWishlistButton = true,
    this.showRating = true,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
    this.padding,
    this.enableHapticFeedback = true,
    this.heroTag,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 200,
              margin: widget.margin ?? const EdgeInsets.all(8),
              child: Material(
                elevation: _elevationAnimation.value,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                  child: _buildCardContent(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent() {
    return Stack(
      children: [
        // Background image
        _buildBackgroundImage(),
        
        // Gradient overlay
        _buildGradientOverlay(),
        
        // Content overlay
        _buildContentOverlay(),
        
        // Wishlist button
        if (widget.showWishlistButton) _buildWishlistButton(),
        
        // Rating badge
        if (widget.showRating) _buildRatingBadge(),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: widget.restaurant.imageUrl != null
          ? Image.network(
              widget.restaurant.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContentOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Restaurant name
            Text(
              widget.restaurant.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Restaurant area
            Text(
              widget.restaurant.area,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Price range
            _buildPriceRange(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRange() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '\$' * widget.restaurant.price,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWishlistButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: _handleWishlistToggle,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.isInWishlist ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(widget.isInWishlist),
              color: widget.isInWishlist ? Colors.red : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    // Mock rating for demonstration
    final rating = 4.5;
    
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              color: Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              rating.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleWishlistToggle() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onWishlistToggle?.call();
  }
}

// Restaurant card variants
class RestaurantCardVariants {
  static Widget compact({
    required Restaurant restaurant,
    VoidCallback? onTap,
    VoidCallback? onWishlistToggle,
    bool isInWishlist = false,
  }) {
    return RestaurantCard(
      restaurant: restaurant,
      onTap: onTap,
      onWishlistToggle: onWishlistToggle,
      isInWishlist: isInWishlist,
      height: 120,
      showRating: false,
    );
  }

  static Widget featured({
    required Restaurant restaurant,
    VoidCallback? onTap,
    VoidCallback? onWishlistToggle,
    bool isInWishlist = false,
  }) {
    return RestaurantCard(
      restaurant: restaurant,
      onTap: onTap,
      onWishlistToggle: onWishlistToggle,
      isInWishlist: isInWishlist,
      height: 250,
      showRating: true,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  static Widget grid({
    required Restaurant restaurant,
    VoidCallback? onTap,
    VoidCallback? onWishlistToggle,
    bool isInWishlist = false,
  }) {
    return RestaurantCard(
      restaurant: restaurant,
      onTap: onTap,
      onWishlistToggle: onWishlistToggle,
      isInWishlist: isInWishlist,
      height: 180,
      showRating: true,
      margin: const EdgeInsets.all(4),
    );
  }
}

