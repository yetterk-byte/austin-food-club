import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/friend.dart';

class AchievementCardWidget extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final bool showUnlockedDate;

  const AchievementCardWidget({
    super.key,
    required this.achievement,
    this.onTap,
    this.showUnlockedDate = false,
  });

  @override
  State<AchievementCardWidget> createState() => _AchievementCardWidgetState();
}

class _AchievementCardWidgetState extends State<AchievementCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.achievement.isUnlocked
                    ? Colors.grey.shade800
                    : Colors.grey.shade800.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.achievement.isUnlocked
                      ? _getBadgeColor().withOpacity(0.5)
                      : Colors.grey.shade600,
                  width: 2,
                ),
                gradient: widget.achievement.isUnlocked
                    ? LinearGradient(
                        colors: [
                          _getBadgeColor().withOpacity(0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Achievement icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.achievement.isUnlocked
                          ? _getBadgeColor().withOpacity(0.2)
                          : Colors.grey.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.achievement.isUnlocked
                          ? Text(
                              widget.achievement.iconUrl,
                              style: const TextStyle(fontSize: 24),
                            )
                          : Icon(
                              Icons.lock,
                              color: Colors.grey.shade500,
                              size: 24,
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Achievement info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.achievement.name,
                          style: TextStyle(
                            color: widget.achievement.isUnlocked
                                ? Colors.white
                                : Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          widget.achievement.description,
                          style: TextStyle(
                            color: widget.achievement.isUnlocked
                                ? Colors.grey.shade300
                                : Colors.grey.shade500,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Progress or unlocked date
                        if (widget.achievement.isUnlocked) ...[
                          if (widget.showUnlockedDate && widget.achievement.unlockedAt != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Unlocked ${_formatDate(widget.achievement.unlockedAt!)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getBadgeColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: _getBadgeColor(),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Unlocked',
                                    style: TextStyle(
                                      color: _getBadgeColor(),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ] else ...[
                          // Progress bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${widget.achievement.currentProgress}/${widget.achievement.targetValue}',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 4),
                              
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: widget.achievement.progressPercentage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBadgeColor() {
    // Parse hex color from achievement.badgeColor
    final hexColor = widget.achievement.badgeColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    return Colors.orange; // Fallback color
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

