import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/restaurant.dart';

class RatingReviewStep extends StatefulWidget {
  final Restaurant restaurant;
  final int initialRating;
  final String initialReview;
  final Function(int) onRatingChanged;
  final Function(String) onReviewChanged;

  const RatingReviewStep({
    super.key,
    required this.restaurant,
    required this.initialRating,
    required this.initialReview,
    required this.onRatingChanged,
    required this.onReviewChanged,
  });

  @override
  State<RatingReviewStep> createState() => _RatingReviewStepState();
}

class _RatingReviewStepState extends State<RatingReviewStep>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _textController;
  late Animation<double> _starAnimation;
  late Animation<double> _textAnimation;

  int _rating = 0;
  String _review = '';
  final TextEditingController _reviewController = TextEditingController();
  final FocusNode _reviewFocusNode = FocusNode();

  final List<String> _suggestedPrompts = [
    'What was the best part of your meal?',
    'How was the service?',
    'Would you recommend this place?',
    'What made this visit special?',
    'Any standout dishes?',
  ];

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _review = widget.initialReview;
    _reviewController.text = _review;

    _starController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _starAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _textController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    _textController.dispose();
    _reviewController.dispose();
    _reviewFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: Column(
        children: [
          // Restaurant info
          _buildRestaurantInfo(),
          
          // Rating section
          _buildRatingSection(),
          
          // Review section
          _buildReviewSection(),
          
          // Suggested prompts
          _buildSuggestedPrompts(),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Restaurant name
          Text(
            widget.restaurant.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Restaurant address
          Text(
            widget.restaurant.address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Rating prompt
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _textAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _textAnimation.value)),
                  child: Text(
                    'How was your experience?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Star rating
          AnimatedBuilder(
            animation: _starAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _starAnimation.value),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => _setRating(index + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: index < _rating ? Colors.orange : Colors.grey.shade600,
                          size: 48,
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Rating labels
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _textAnimation.value,
                child: Text(
                  _getRatingLabel(_rating),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review label
          Text(
            'Write a review (optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Review text field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _reviewFocusNode.hasFocus 
                    ? Colors.orange 
                    : Colors.grey.shade600,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _reviewController,
              focusNode: _reviewFocusNode,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Share your thoughts about this restaurant...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterStyle: TextStyle(color: Colors.grey.shade400),
              ),
              onChanged: (value) {
                setState(() {
                  _review = value;
                });
                widget.onReviewChanged(value);
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Character count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_review.length}/500 characters',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
              if (_review.length > 450)
                Text(
                  'Almost at limit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need inspiration?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedPrompts.map((prompt) {
              return GestureDetector(
                onTap: () => _usePrompt(prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  child: Text(
                    prompt,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Methods
  void _setRating(int rating) {
    setState(() {
      _rating = rating;
    });
    widget.onRatingChanged(rating);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Animate stars
    _starController.forward().then((_) {
      _starController.reverse();
    });
  }

  void _usePrompt(String prompt) {
    _reviewController.text = prompt;
    _reviewFocusNode.requestFocus();
    setState(() {
      _review = prompt;
    });
    widget.onReviewChanged(prompt);
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }
}

