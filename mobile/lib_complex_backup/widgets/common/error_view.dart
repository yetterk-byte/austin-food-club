import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ErrorType {
  network,
  server,
  notFound,
  unauthorized,
  forbidden,
  validation,
  unknown,
}

class ErrorView extends StatelessWidget {
  final String? title;
  final String? message;
  final ErrorType errorType;
  final VoidCallback? onRetry;
  final String? retryText;
  final Widget? customIcon;
  final Color? iconColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final bool showRetryButton;
  final bool enableHapticFeedback;

  const ErrorView({
    super.key,
    this.title,
    this.message,
    this.errorType = ErrorType.unknown,
    this.onRetry,
    this.retryText,
    this.customIcon,
    this.iconColor,
    this.textColor,
    this.padding,
    this.showRetryButton = true,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error icon
          _buildErrorIcon(context),
          
          const SizedBox(height: 24),
          
          // Error title
          _buildErrorTitle(context),
          
          const SizedBox(height: 12),
          
          // Error message
          _buildErrorMessage(context),
          
          const SizedBox(height: 32),
          
          // Retry button
          if (showRetryButton) _buildRetryButton(context),
        ],
      ),
    );
  }

  Widget _buildErrorIcon(BuildContext context) {
    if (customIcon != null) {
      return customIcon!;
    }

    final iconData = _getErrorIcon();
    final size = _getIconSize();
    final color = iconColor ?? _getIconColor();

    return Container(
      width: size + 40,
      height: size + 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: size,
        color: color,
      ),
    );
  }

  Widget _buildErrorTitle(BuildContext context) {
    final titleText = title ?? _getDefaultTitle();
    final color = textColor ?? Colors.grey.shade800;

    return Text(
      titleText,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final messageText = message ?? _getDefaultMessage();
    final color = textColor ?? Colors.grey.shade600;

    return Text(
      messageText,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: color,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _handleRetry,
      icon: const Icon(Icons.refresh),
      label: Text(retryText ?? 'Try Again'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.unauthorized:
        return Icons.lock_outline;
      case ErrorType.forbidden:
        return Icons.block;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  double _getIconSize() {
    switch (errorType) {
      case ErrorType.network:
        return 48;
      case ErrorType.server:
        return 48;
      case ErrorType.notFound:
        return 48;
      case ErrorType.unauthorized:
        return 48;
      case ErrorType.forbidden:
        return 48;
      case ErrorType.validation:
        return 48;
      case ErrorType.unknown:
        return 48;
    }
  }

  Color _getIconColor() {
    switch (errorType) {
      case ErrorType.network:
        return Colors.blue;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.orange;
      case ErrorType.unauthorized:
        return Colors.amber;
      case ErrorType.forbidden:
        return Colors.red;
      case ErrorType.validation:
        return Colors.orange;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  String _getDefaultTitle() {
    switch (errorType) {
      case ErrorType.network:
        return 'No Internet Connection';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.unauthorized:
        return 'Unauthorized';
      case ErrorType.forbidden:
        return 'Access Denied';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.unknown:
        return 'Something Went Wrong';
    }
  }

  String _getDefaultMessage() {
    switch (errorType) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.server:
        return 'We\'re experiencing technical difficulties. Please try again later.';
      case ErrorType.notFound:
        return 'The requested resource could not be found.';
      case ErrorType.unauthorized:
        return 'You need to sign in to access this content.';
      case ErrorType.forbidden:
        return 'You don\'t have permission to access this content.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  void _handleRetry() {
    if (enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    onRetry?.call();
  }
}

// Error view variants
class ErrorViewVariants {
  static Widget network({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return ErrorView(
      errorType: ErrorType.network,
      onRetry: onRetry,
      message: customMessage,
    );
  }

  static Widget server({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return ErrorView(
      errorType: ErrorType.server,
      onRetry: onRetry,
      message: customMessage,
    );
  }

  static Widget notFound({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return ErrorView(
      errorType: ErrorType.notFound,
      onRetry: onRetry,
      message: customMessage,
    );
  }

  static Widget unauthorized({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return ErrorView(
      errorType: ErrorType.unauthorized,
      onRetry: onRetry,
      message: customMessage,
    );
  }

  static Widget forbidden({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return ErrorView(
      errorType: ErrorType.forbidden,
      onRetry: onRetry,
      message: customMessage,
    );
  }

  static Widget validation({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return ErrorView(
      errorType: ErrorType.validation,
      onRetry: onRetry,
      message: customMessage,
    );
  }

  static Widget custom({
    required String title,
    required String message,
    required IconData icon,
    VoidCallback? onRetry,
    String? retryText,
    Color? iconColor,
    Color? textColor,
  }) {
    return ErrorView(
      title: title,
      message: message,
      customIcon: Icon(
        icon,
        size: 48,
        color: iconColor ?? Colors.grey,
      ),
      onRetry: onRetry,
      retryText: retryText,
      iconColor: iconColor,
      textColor: textColor,
    );
  }

  static Widget withAction({
    required String title,
    required String message,
    required IconData icon,
    required String actionText,
    required VoidCallback onAction,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return ErrorView(
      title: title,
      message: message,
      customIcon: Icon(
        icon,
        size: 48,
        color: Colors.orange,
      ),
      onRetry: onAction,
      retryText: actionText,
      showRetryButton: true,
    );
  }
}

// Error state widget for lists
class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final ErrorType errorType;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.onRetry,
    this.errorType = ErrorType.unknown,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ErrorView(
        message: message,
        onRetry: onRetry,
        errorType: errorType,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}

// Error banner for top of screens
class ErrorBanner extends StatelessWidget {
  final String message;
  final ErrorType errorType;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.errorType = ErrorType.unknown,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBannerColor().withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _getBannerColor().withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getErrorIcon(),
            color: _getBannerColor(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getBannerColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 20,
            ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.unauthorized:
        return Icons.lock_outline;
      case ErrorType.forbidden:
        return Icons.block;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  Color _getBannerColor() {
    switch (errorType) {
      case ErrorType.network:
        return Colors.blue;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.orange;
      case ErrorType.unauthorized:
        return Colors.amber;
      case ErrorType.forbidden:
        return Colors.red;
      case ErrorType.validation:
        return Colors.orange;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }
}

