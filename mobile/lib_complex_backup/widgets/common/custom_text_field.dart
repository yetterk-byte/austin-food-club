import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TextFieldType {
  text,
  email,
  password,
  phone,
  number,
  multiline,
}

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextFieldType type;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final String? helperText;
  final bool showClearButton;
  final bool showCharacterCount;
  final EdgeInsets? contentPadding;
  final BorderRadius? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final double? borderWidth;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool enableHapticFeedback;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.type = TextFieldType.text,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onClear,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.helperText,
    this.showClearButton = false,
    this.showCharacterCount = false,
    this.contentPadding,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderWidth,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enableHapticFeedback = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isFocused = false;
  bool _isObscured = false;
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _isObscured = widget.obscureText;
    _currentValue = widget.initialValue ?? '';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade600,
      end: Colors.orange,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller = widget.controller ?? _controller;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode = widget.focusNode ?? _focusNode;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              if (widget.label != null) _buildLabel(),
              
              // Text field
              _buildTextField(),
              
              // Helper text and character count
              _buildHelperText(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        widget.label!,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _isFocused ? Colors.orange : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: _isObscured,
      maxLines: _getMaxLines(),
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      validator: widget.validator,
      onChanged: _onTextChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      textInputAction: _getTextInputAction(),
      textCapitalization: _getTextCapitalization(),
      inputFormatters: _getInputFormatters(),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.grey.shade800,
      ),
      decoration: InputDecoration(
        hintText: widget.hint ?? _getDefaultHint(),
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
        prefixIcon: widget.prefixIcon ?? _getPrefixIcon(),
        suffixIcon: _buildSuffixIcon(),
        filled: true,
        fillColor: widget.fillColor ?? Colors.grey.shade50,
        contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _buildBorder(),
        enabledBorder: _buildBorder(),
        focusedBorder: _buildFocusedBorder(),
        errorBorder: _buildErrorBorder(),
        focusedErrorBorder: _buildErrorBorder(),
        disabledBorder: _buildDisabledBorder(),
        errorText: widget.errorText,
        counterText: widget.showCharacterCount ? null : '',
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon!;
    }

    if (widget.type == TextFieldType.password) {
      return IconButton(
        onPressed: _toggleObscureText,
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey.shade600,
        ),
      );
    }

    if (widget.showClearButton && _currentValue.isNotEmpty) {
      return IconButton(
        onPressed: _clearText,
        icon: Icon(
          Icons.clear,
          color: Colors.grey.shade600,
        ),
      );
    }

    return null;
  }

  Widget _buildHelperText() {
    if (widget.helperText == null && !widget.showCharacterCount) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.helperText != null)
            Expanded(
              child: Text(
                widget.helperText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          if (widget.showCharacterCount && widget.maxLength != null)
            Text(
              '${_currentValue.length}/${widget.maxLength}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _currentValue.length > widget.maxLength! * 0.9
                    ? Colors.orange
                    : Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  InputBorder _buildBorder() {
    return OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      borderSide: BorderSide(
        color: widget.borderColor ?? Colors.grey.shade300,
        width: widget.borderWidth ?? 1,
      ),
    );
  }

  InputBorder _buildFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      borderSide: BorderSide(
        color: widget.focusedBorderColor ?? Colors.orange,
        width: (widget.borderWidth ?? 1) + 1,
      ),
    );
  }

  InputBorder _buildErrorBorder() {
    return OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      borderSide: BorderSide(
        color: widget.errorBorderColor ?? Colors.red,
        width: (widget.borderWidth ?? 1) + 1,
      ),
    );
  }

  InputBorder _buildDisabledBorder() {
    return OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.grey.shade200,
        width: widget.borderWidth ?? 1,
      ),
    );
  }

  Widget? _getPrefixIcon() {
    switch (widget.type) {
      case TextFieldType.email:
        return const Icon(Icons.email_outlined);
      case TextFieldType.password:
        return const Icon(Icons.lock_outline);
      case TextFieldType.phone:
        return const Icon(Icons.phone_outlined);
      case TextFieldType.number:
        return const Icon(Icons.numbers);
      default:
        return null;
    }
  }

  String _getDefaultHint() {
    switch (widget.type) {
      case TextFieldType.email:
        return 'Enter your email';
      case TextFieldType.password:
        return 'Enter your password';
      case TextFieldType.phone:
        return 'Enter your phone number';
      case TextFieldType.number:
        return 'Enter a number';
      case TextFieldType.multiline:
        return 'Enter your message';
      default:
        return 'Enter text';
    }
  }

  int? _getMaxLines() {
    if (widget.maxLines != null) return widget.maxLines;
    switch (widget.type) {
      case TextFieldType.multiline:
        return 4;
      default:
        return 1;
    }
  }

  TextInputAction _getTextInputAction() {
    if (widget.textInputAction != null) return widget.textInputAction!;
    switch (widget.type) {
      case TextFieldType.multiline:
        return TextInputAction.newline;
      case TextFieldType.email:
        return TextInputAction.next;
      case TextFieldType.password:
        return TextInputAction.done;
      default:
        return TextInputAction.next;
    }
  }

  TextCapitalization _getTextCapitalization() {
    if (widget.textCapitalization != TextCapitalization.none) {
      return widget.textCapitalization;
    }
    switch (widget.type) {
      case TextFieldType.email:
        return TextCapitalization.none;
      case TextFieldType.password:
        return TextCapitalization.none;
      case TextFieldType.phone:
        return TextCapitalization.none;
      case TextFieldType.number:
        return TextCapitalization.none;
      default:
        return TextCapitalization.sentences;
    }
  }

  List<TextInputFormatter>? _getInputFormatters() {
    if (widget.inputFormatters != null) return widget.inputFormatters;
    
    switch (widget.type) {
      case TextFieldType.phone:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15),
        ];
      case TextFieldType.number:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ];
      case TextFieldType.email:
        return [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
        ];
      default:
        return null;
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTextChange() {
    setState(() {
      _currentValue = _controller.text;
    });
  }

  void _onTextChanged(String value) {
    if (widget.enableHapticFeedback && value.length > _currentValue.length) {
      HapticFeedback.selectionClick();
    }
    widget.onChanged?.call(value);
  }

  void _toggleObscureText() {
    setState(() {
      _isObscured = !_isObscured;
    });
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _clearText() {
    _controller.clear();
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onClear?.call();
  }
}

// Text field variants
class CustomTextFieldVariants {
  static Widget email({
    String? label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return CustomTextField(
      type: TextFieldType.email,
      label: label ?? 'Email',
      hint: hint,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
    );
  }

  static Widget password({
    String? label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return CustomTextField(
      type: TextFieldType.password,
      label: label ?? 'Password',
      hint: hint,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
    );
  }

  static Widget phone({
    String? label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return CustomTextField(
      type: TextFieldType.phone,
      label: label ?? 'Phone Number',
      hint: hint,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
    );
  }

  static Widget multiline({
    String? label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int? maxLength,
  }) {
    return CustomTextField(
      type: TextFieldType.multiline,
      label: label,
      hint: hint,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      maxLength: maxLength,
      showCharacterCount: true,
    );
  }

  static Widget search({
    String? hint,
    TextEditingController? controller,
    void Function(String)? onChanged,
    VoidCallback? onClear,
  }) {
    return CustomTextField(
      hint: hint ?? 'Search...',
      controller: controller,
      onChanged: onChanged,
      onClear: onClear,
      prefixIcon: const Icon(Icons.search),
      showClearButton: true,
    );
  }
}