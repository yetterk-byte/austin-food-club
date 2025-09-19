import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final bool enabled;

  const LoadingShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(LoadingShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? Colors.grey.shade300,
                widget.highlightColor ?? Colors.grey.shade100,
                widget.baseColor ?? Colors.grey.shade300,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Shimmer skeleton widgets
class ShimmerSkeleton {
  static Widget text({
    double? width,
    double height = 16,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }

  static Widget circle({
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget rectangle({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  static Widget card({
    double? width,
    double height = 200,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    );
  }
}

// Predefined shimmer layouts
class ShimmerLayouts {
  static Widget restaurantCard({
    double? width,
    double height = 200,
  }) {
    return LoadingShimmer(
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static Widget restaurantList({
    int itemCount = 5,
  }) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ShimmerSkeleton.circle(size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerSkeleton.text(width: double.infinity, height: 20),
                    const SizedBox(height: 8),
                    ShimmerSkeleton.text(width: 150, height: 16),
                    const SizedBox(height: 4),
                    ShimmerSkeleton.text(width: 100, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget profileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerSkeleton.circle(size: 80),
          const SizedBox(height: 16),
          ShimmerSkeleton.text(width: 150, height: 24),
          const SizedBox(height: 8),
          ShimmerSkeleton.text(width: 100, height: 16),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  ShimmerSkeleton.text(width: 40, height: 20),
                  const SizedBox(height: 4),
                  ShimmerSkeleton.text(width: 60, height: 14),
                ],
              ),
              Column(
                children: [
                  ShimmerSkeleton.text(width: 40, height: 20),
                  const SizedBox(height: 4),
                  ShimmerSkeleton.text(width: 60, height: 14),
                ],
              ),
              Column(
                children: [
                  ShimmerSkeleton.text(width: 40, height: 20),
                  const SizedBox(height: 4),
                  ShimmerSkeleton.text(width: 60, height: 14),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget verifiedVisitsGrid({
    int itemCount = 6,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LoadingShimmer(
          child: ShimmerSkeleton.card(
            height: 150,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  static Widget rsvpList({
    int itemCount = 3,
  }) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ShimmerSkeleton.rectangle(
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerSkeleton.text(width: double.infinity, height: 18),
                      const SizedBox(height: 8),
                      ShimmerSkeleton.text(width: 120, height: 14),
                      const SizedBox(height: 4),
                      ShimmerSkeleton.text(width: 80, height: 12),
                    ],
                  ),
                ),
                ShimmerSkeleton.rectangle(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget currentRestaurant() {
    return Column(
      children: [
        // Hero image
        LoadingShimmer(
          child: ShimmerSkeleton.rectangle(
            width: double.infinity,
            height: 300,
            borderRadius: BorderRadius.circular(0),
          ),
        ),
        
        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerSkeleton.text(width: double.infinity, height: 28),
              const SizedBox(height: 8),
              ShimmerSkeleton.text(width: 200, height: 16),
              const SizedBox(height: 16),
              Row(
                children: [
                  ShimmerSkeleton.text(width: 100, height: 20),
                  const SizedBox(width: 16),
                  ShimmerSkeleton.text(width: 80, height: 20),
                ],
              ),
              const SizedBox(height: 16),
              ShimmerSkeleton.text(width: double.infinity, height: 16),
              const SizedBox(height: 4),
              ShimmerSkeleton.text(width: double.infinity, height: 16),
              const SizedBox(height: 4),
              ShimmerSkeleton.text(width: 200, height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// Shimmer container for custom layouts
class ShimmerContainer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final bool enabled;

  const ShimmerContainer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
      enabled: enabled,
      child: child,
    );
  }
}