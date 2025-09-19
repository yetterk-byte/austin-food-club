import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class PhotoViewer extends StatefulWidget {
  final String imageUrl;
  final File? imageFile;
  final String? heroTag;
  final double? minScale;
  final double? maxScale;
  final bool enablePinchToZoom;
  final bool enableDoubleTapToZoom;
  final bool enableSwipeToDismiss;
  final bool showShareButton;
  final VoidCallback? onShare;
  final VoidCallback? onDismiss;
  final Color? backgroundColor;
  final bool enableHapticFeedback;

  const PhotoViewer({
    super.key,
    this.imageUrl = '',
    this.imageFile,
    this.heroTag,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.enablePinchToZoom = true,
    this.enableDoubleTapToZoom = true,
    this.enableSwipeToDismiss = true,
    this.showShareButton = true,
    this.onShare,
    this.onDismiss,
    this.backgroundColor,
    this.enableHapticFeedback = true,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;
  
  bool _isVisible = true;
  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.black,
      body: Stack(
        children: [
          // Photo viewer
          _buildPhotoViewer(),
          
          // Top controls
          _buildTopControls(),
          
          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildPhotoViewer() {
    return Center(
      child: Hero(
        tag: widget.heroTag ?? 'photo_viewer',
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: widget.minScale!,
          maxScale: widget.maxScale!,
          onInteractionStart: _onInteractionStart,
          onInteractionUpdate: _onInteractionUpdate,
          onInteractionEnd: _onInteractionEnd,
          child: GestureDetector(
            onTap: _onTap,
            onDoubleTap: widget.enableDoubleTapToZoom ? _onDoubleTap : null,
            onPanUpdate: widget.enableSwipeToDismiss ? _onPanUpdate : null,
            onPanEnd: widget.enableSwipeToDismiss ? _onPanEnd : null,
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageFile != null) {
      return Image.file(
        widget.imageFile!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else if (widget.imageUrl.isNotEmpty) {
      return Image.network(
        widget.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load image',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              GestureDetector(
                onTap: _onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              // Share button
              if (widget.showShareButton)
                GestureDetector(
                  onTap: _onShare,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Zoom controls
              _buildZoomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom out
          GestureDetector(
            onTap: _zoomOut,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.zoom_out,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Reset zoom
          GestureDetector(
            onTap: _resetZoom,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.center_focus_strong,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Zoom in
          GestureDetector(
            onTap: _zoomIn,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gesture handlers
  void _onTap() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  void _onDoubleTap() {
    if (!widget.enableDoubleTapToZoom) return;

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = currentScale > 1.0 ? 1.0 : 2.0;

    _animateToScale(targetScale);
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipeToDismiss) return;

    final delta = details.delta.dy;
    if (delta > 0) {
      setState(() {
        _currentOffset = Offset(0, _currentOffset.dy + delta);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableSwipeToDismiss) return;

    final velocity = details.velocity.pixelsPerSecond.dy;
    if (velocity > 500 || _currentOffset.dy > 100) {
      _onDismiss();
    } else {
      setState(() {
        _currentOffset = Offset.zero;
      });
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    setState(() {
      _currentScale = details.scale;
    });
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // Snap to bounds if needed
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < widget.minScale!) {
      _animateToScale(widget.minScale!);
    } else if (currentScale > widget.maxScale!) {
      _animateToScale(widget.maxScale!);
    }
  }

  // Control methods
  void _onClose() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onDismiss?.call();
    Navigator.of(context).pop();
  }

  void _onShare() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onShare?.call();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * 1.5).clamp(widget.minScale!, widget.maxScale!);
    _animateToScale(targetScale);
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = (currentScale / 1.5).clamp(widget.minScale!, widget.maxScale!);
    _animateToScale(targetScale);
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _resetZoom() {
    _animateToScale(1.0);
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _animateToScale(double targetScale) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetMatrix = Matrix4.identity()..scale(targetScale);
    
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((_) {
      _animationController.reset();
    });

    _animation.addListener(() {
      _transformationController.value = _animation.value;
    });
  }
}

// Photo viewer variants
class PhotoViewerVariants {
  static Widget simple({
    required String imageUrl,
    String? heroTag,
    VoidCallback? onDismiss,
  }) {
    return PhotoViewer(
      imageUrl: imageUrl,
      heroTag: heroTag,
      onDismiss: onDismiss,
      showShareButton: false,
      enableSwipeToDismiss: true,
    );
  }

  static Widget withControls({
    required String imageUrl,
    String? heroTag,
    VoidCallback? onShare,
    VoidCallback? onDismiss,
  }) {
    return PhotoViewer(
      imageUrl: imageUrl,
      heroTag: heroTag,
      onShare: onShare,
      onDismiss: onDismiss,
      showShareButton: true,
      enableSwipeToDismiss: true,
      enableDoubleTapToZoom: true,
    );
  }

  static Widget fullScreen({
    required String imageUrl,
    String? heroTag,
    VoidCallback? onDismiss,
  }) {
    return PhotoViewer(
      imageUrl: imageUrl,
      heroTag: heroTag,
      onDismiss: onDismiss,
      showShareButton: false,
      enableSwipeToDismiss: true,
      enableDoubleTapToZoom: true,
      enablePinchToZoom: true,
    );
  }

  static Widget fromFile({
    required File imageFile,
    String? heroTag,
    VoidCallback? onShare,
    VoidCallback? onDismiss,
  }) {
    return PhotoViewer(
      imageFile: imageFile,
      heroTag: heroTag,
      onShare: onShare,
      onDismiss: onDismiss,
      showShareButton: true,
      enableSwipeToDismiss: true,
      enableDoubleTapToZoom: true,
    );
  }
}

// Photo viewer dialog
class PhotoViewerDialog extends StatelessWidget {
  final String imageUrl;
  final File? imageFile;
  final String? heroTag;
  final VoidCallback? onShare;

  const PhotoViewerDialog({
    super.key,
    required this.imageUrl,
    this.imageFile,
    this.heroTag,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PhotoViewer(
        imageUrl: imageUrl,
        imageFile: imageFile,
        heroTag: heroTag,
        onShare: onShare,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  static void show({
    required BuildContext context,
    required String imageUrl,
    File? imageFile,
    String? heroTag,
    VoidCallback? onShare,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PhotoViewerDialog(
        imageUrl: imageUrl,
        imageFile: imageFile,
        heroTag: heroTag,
        onShare: onShare,
      ),
    );
  }
}

