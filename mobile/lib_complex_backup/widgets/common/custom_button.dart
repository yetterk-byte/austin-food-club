import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ButtonSize { small, medium, large }
enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final ButtonType type;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Widget? customIcon;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool fullWidth;
  final bool enableHapticFeedback;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.customIcon,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.fullWidth = false,
    this.enableHapticFeedback = true,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

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

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
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
    final isEnabled = widget.onPressed != null && !widget.isLoading && !widget.isDisabled;
    
    return GestureDetector(
      onTapDown: isEnabled ? _onTapDown : null,
      onTapUp: isEnabled ? _onTapUp : null,
      onTapCancel: isEnabled ? _onTapCancel : null,
      onTap: isEnabled ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: _buildButton(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    return Container(
      width: widget.fullWidth ? double.infinity : widget.width,
      height: widget.height ?? _getButtonHeight(),
      decoration: _getButtonDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null, // Handled by GestureDetector
          borderRadius: _getBorderRadius(),
          child: Container(
            padding: widget.padding ?? _getButtonPadding(),
            child: _buildButtonContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return _buildLoadingContent();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null || widget.customIcon != null) ...[
          widget.customIcon ?? Icon(
            widget.icon,
            size: _getIconSize(),
            color: _getTextColor(),
          ),
          SizedBox(width: _getIconSpacing()),
        ],
        Flexible(
          child: Text(
            widget.text,
            style: _getTextStyle(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _getLoadingSize(),
          height: _getLoadingSize(),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
          ),
        ),
        if (widget.text.isNotEmpty) ...[
          SizedBox(width: _getIconSpacing()),
          Flexible(
            child: Text(
              widget.text,
              style: _getTextStyle(),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _getButtonDecoration() {
    final isEnabled = widget.onPressed != null && !widget.isLoading && !widget.isDisabled;
    
    switch (widget.type) {
      case ButtonType.primary:
        return BoxDecoration(
          gradient: widget.gradient ?? (isEnabled 
              ? const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null),
          color: widget.gradient == null 
              ? (isEnabled ? widget.backgroundColor ?? Colors.orange : Colors.grey.shade600)
              : null,
          borderRadius: _getBorderRadius(),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        );
      
      case ButtonType.secondary:
        return BoxDecoration(
          color: isEnabled 
              ? (widget.backgroundColor ?? Colors.grey.shade800)
              : Colors.grey.shade700,
          borderRadius: _getBorderRadius(),
        );
      
      case ButtonType.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: _getBorderRadius(),
          border: Border.all(
            color: isEnabled 
                ? (widget.borderColor ?? Colors.orange)
                : Colors.grey.shade600,
            width: 2,
          ),
        );
      
      case ButtonType.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: _getBorderRadius(),
        );
    }
  }

  TextStyle _getTextStyle() {
    final isEnabled = widget.onPressed != null && !widget.isLoading && !widget.isDisabled;
    
    return TextStyle(
      color: isEnabled 
          ? (widget.textColor ?? _getDefaultTextColor())
          : Colors.grey.shade400,
      fontSize: _getFontSize(),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  Color _getDefaultTextColor() {
    switch (widget.type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return Colors.white;
      case ButtonType.outline:
        return Colors.orange;
      case ButtonType.text:
        return Colors.orange;
    }
  }

  Color _getTextColor() {
    final isEnabled = widget.onPressed != null && !widget.isLoading && !widget.isDisabled;
    return isEnabled 
        ? (widget.textColor ?? _getDefaultTextColor())
        : Colors.grey.shade400;
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getButtonPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getIconSpacing() {
    switch (widget.size) {
      case ButtonSize.small:
        return 6;
      case ButtonSize.medium:
        return 8;
      case ButtonSize.large:
        return 12;
    }
  }

  double _getLoadingSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  BorderRadius _getBorderRadius() {
    return widget.borderRadius ?? BorderRadius.circular(
      widget.size == ButtonSize.small ? 8 : 12,
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
    widget.onPressed?.call();
  }
}

// Predefined button variants
class CustomButtonVariants {
  static Widget primary({
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      size: size,
      type: ButtonType.primary,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  static Widget secondary({
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      size: size,
      type: ButtonType.secondary,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  static Widget outline({
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      size: size,
      type: ButtonType.outline,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  static Widget text({
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      size: size,
      type: ButtonType.text,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  static Widget gradient({
    required String text,
    required Gradient gradient,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    bool fullWidth = false,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      size: size,
      type: ButtonType.primary,
      gradient: gradient,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }
}