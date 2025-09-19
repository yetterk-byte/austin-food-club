import 'package:flutter/material.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final EdgeInsets? padding;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.padding,
    this.showZero = false,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    if (_shouldShowBadge(widget.count)) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.count != widget.count) {
      if (_shouldShowBadge(widget.count) && !_shouldShowBadge(_previousCount)) {
        // Badge appearing
        _animationController.forward();
      } else if (!_shouldShowBadge(widget.count) && _shouldShowBadge(_previousCount)) {
        // Badge disappearing
        _animationController.reverse();
      } else if (_shouldShowBadge(widget.count) && widget.count > _previousCount) {
        // Badge count increased - bounce animation
        _animationController.forward().then((_) {
          _animationController.reverse().then((_) {
            _animationController.forward();
          });
        });
      }
      _previousCount = widget.count;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_shouldShowBadge(widget.count))
          Positioned(
            right: -6,
            top: -6,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value * _bounceAnimation.value,
                  child: Container(
                    padding: widget.padding ?? 
                        EdgeInsets.all(widget.count > 99 ? 4 : 6),
                    decoration: BoxDecoration(
                      color: widget.badgeColor ?? Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.badgeColor ?? Colors.red).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: widget.badgeSize ?? 20,
                      minHeight: widget.badgeSize ?? 20,
                    ),
                    child: Center(
                      child: Text(
                        _getBadgeText(),
                        style: TextStyle(
                          color: widget.textColor ?? Colors.white,
                          fontSize: widget.count > 99 ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  bool _shouldShowBadge(int count) {
    return count > 0 || (widget.showZero && count == 0);
  }

  String _getBadgeText() {
    if (widget.count > 99) {
      return '99+';
    }
    return widget.count.toString();
  }
}

// Predefined badge variants
class NotificationBadgeVariants {
  static Widget red({
    required Widget child,
    required int count,
    bool showZero = false,
  }) {
    return NotificationBadge(
      count: count,
      badgeColor: Colors.red,
      textColor: Colors.white,
      showZero: showZero,
      child: child,
    );
  }

  static Widget orange({
    required Widget child,
    required int count,
    bool showZero = false,
  }) {
    return NotificationBadge(
      count: count,
      badgeColor: Colors.orange,
      textColor: Colors.white,
      showZero: showZero,
      child: child,
    );
  }

  static Widget green({
    required Widget child,
    required int count,
    bool showZero = false,
  }) {
    return NotificationBadge(
      count: count,
      badgeColor: Colors.green,
      textColor: Colors.white,
      showZero: showZero,
      child: child,
    );
  }

  static Widget small({
    required Widget child,
    required int count,
    Color? badgeColor,
    bool showZero = false,
  }) {
    return NotificationBadge(
      count: count,
      badgeColor: badgeColor ?? Colors.red,
      textColor: Colors.white,
      badgeSize: 16,
      padding: const EdgeInsets.all(4),
      showZero: showZero,
      child: child,
    );
  }

  static Widget large({
    required Widget child,
    required int count,
    Color? badgeColor,
    bool showZero = false,
  }) {
    return NotificationBadge(
      count: count,
      badgeColor: badgeColor ?? Colors.red,
      textColor: Colors.white,
      badgeSize: 28,
      padding: const EdgeInsets.all(8),
      showZero: showZero,
      child: child,
    );
  }
}

