import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StarRating extends StatefulWidget {
  final double rating;
  final int maxRating;
  final bool readOnly;
  final bool allowHalfStars;
  final double starSize;
  final Color filledColor;
  final Color emptyColor;
  final Color? selectedColor;
  final double spacing;
  final ValueChanged<double>? onRatingChanged;
  final String? semanticLabel;
  final bool enableHapticFeedback;

  const StarRating({
    super.key,
    this.rating = 0.0,
    this.maxRating = 5,
    this.readOnly = false,
    this.allowHalfStars = false,
    this.starSize = 24.0,
    this.filledColor = Colors.orange,
    this.emptyColor = Colors.grey,
    this.selectedColor,
    this.spacing = 4.0,
    this.onRatingChanged,
    this.semanticLabel,
    this.enableHapticFeedback = true,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  
  double _currentRating = 0.0;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(StarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? 'Star rating',
      value: '${_currentRating.toStringAsFixed(widget.allowHalfStars ? 1 : 0)} out of ${widget.maxRating}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.maxRating, (index) {
          return _buildStar(index);
        }),
      ),
    );
  }

  Widget _buildStar(int index) {
    final starIndex = index + 1;
    final isFilled = starIndex <= _currentRating;
    final isHalfFilled = widget.allowHalfStars && 
        starIndex - 0.5 <= _currentRating && 
        starIndex > _currentRating;

    return GestureDetector(
      onTap: widget.readOnly ? null : () => _handleStarTap(starIndex),
      onTapDown: widget.readOnly ? null : (_) => _onTapDown(),
      onTapUp: widget.readOnly ? null : (_) => _onTapUp(),
      onTapCancel: widget.readOnly ? null : () => _onTapCancel(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isHovering && starIndex <= _currentRating 
                ? _scaleAnimation.value 
                : 1.0,
            child: Container(
              margin: EdgeInsets.only(
                right: index < widget.maxRating - 1 ? widget.spacing : 0,
              ),
              child: _buildStarIcon(
                isFilled: isFilled,
                isHalfFilled: isHalfFilled,
                starIndex: starIndex,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStarIcon({
    required bool isFilled,
    required bool isHalfFilled,
    required int starIndex,
  }) {
    Color starColor;
    
    if (isFilled) {
      starColor = widget.selectedColor ?? widget.filledColor;
    } else if (isHalfFilled) {
      starColor = widget.selectedColor ?? widget.filledColor;
    } else {
      starColor = widget.emptyColor;
    }

    if (isHalfFilled) {
      return Stack(
        children: [
          Icon(
            Icons.star_border,
            size: widget.starSize,
            color: widget.emptyColor,
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Icon(
                Icons.star,
                size: widget.starSize,
                color: starColor,
              ),
            ),
          ),
        ],
      );
    }

    return Icon(
      isFilled ? Icons.star : Icons.star_border,
      size: widget.starSize,
      color: starColor,
    );
  }

  void _handleStarTap(int starIndex) {
    if (widget.readOnly) return;

    double newRating;
    
    if (widget.allowHalfStars) {
      // For half stars, tap cycles through: empty -> half -> full -> empty
      if (_currentRating == starIndex - 0.5) {
        newRating = starIndex.toDouble();
      } else if (_currentRating == starIndex.toDouble()) {
        newRating = 0.0;
      } else {
        newRating = starIndex - 0.5;
      }
    } else {
      // For full stars, tap cycles through: empty -> full -> empty
      if (_currentRating == starIndex.toDouble()) {
        newRating = 0.0;
      } else {
        newRating = starIndex.toDouble();
      }
    }

    setState(() {
      _currentRating = newRating;
    });

    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    widget.onRatingChanged?.call(newRating);
    _triggerAnimation();
  }

  void _onTapDown() {
    setState(() {
      _isHovering = true;
    });
  }

  void _onTapUp() {
    setState(() {
      _isHovering = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _isHovering = false;
    });
  }

  void _triggerAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }
}

// Star rating variants
class StarRatingVariants {
  static Widget small({
    double rating = 0.0,
    bool readOnly = true,
    ValueChanged<double>? onRatingChanged,
  }) {
    return StarRating(
      rating: rating,
      readOnly: readOnly,
      onRatingChanged: onRatingChanged,
      starSize: 16.0,
      spacing: 2.0,
    );
  }

  static Widget medium({
    double rating = 0.0,
    bool readOnly = true,
    ValueChanged<double>? onRatingChanged,
  }) {
    return StarRating(
      rating: rating,
      readOnly: readOnly,
      onRatingChanged: onRatingChanged,
      starSize: 24.0,
      spacing: 4.0,
    );
  }

  static Widget large({
    double rating = 0.0,
    bool readOnly = true,
    ValueChanged<double>? onRatingChanged,
  }) {
    return StarRating(
      rating: rating,
      readOnly: readOnly,
      onRatingChanged: onRatingChanged,
      starSize: 32.0,
      spacing: 6.0,
    );
  }

  static Widget interactive({
    double rating = 0.0,
    ValueChanged<double>? onRatingChanged,
    bool allowHalfStars = false,
    double starSize = 24.0,
  }) {
    return StarRating(
      rating: rating,
      readOnly: false,
      allowHalfStars: allowHalfStars,
      onRatingChanged: onRatingChanged,
      starSize: starSize,
      filledColor: Colors.orange,
      emptyColor: Colors.grey.shade300,
    );
  }

  static Widget display({
    double rating = 0.0,
    double starSize = 20.0,
    Color filledColor = Colors.orange,
    Color emptyColor = Colors.grey,
  }) {
    return StarRating(
      rating: rating,
      readOnly: true,
      starSize: starSize,
      filledColor: filledColor,
      emptyColor: emptyColor,
    );
  }

  static Widget withText({
    required double rating,
    required String text,
    bool readOnly = true,
    ValueChanged<double>? onRatingChanged,
    double starSize = 20.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(
          rating: rating,
          readOnly: readOnly,
          onRatingChanged: onRatingChanged,
          starSize: starSize,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: starSize * 0.6,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

