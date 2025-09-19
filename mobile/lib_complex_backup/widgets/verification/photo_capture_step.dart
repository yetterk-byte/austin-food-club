import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PhotoCaptureStep extends StatefulWidget {
  final Function(File) onPhotoCaptured;
  final File? initialPhoto;

  const PhotoCaptureStep({
    super.key,
    required this.onPhotoCaptured,
    this.initialPhoto,
  });

  @override
  State<PhotoCaptureStep> createState() => _PhotoCaptureStepState();
}

class _PhotoCaptureStepState extends State<PhotoCaptureStep>
    with TickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  
  late AnimationController _captureController;
  late AnimationController _flashController;
  late Animation<double> _captureAnimation;
  late Animation<double> _flashAnimation;

  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  bool _showGrid = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _captureController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _captureAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _captureController,
      curve: Curves.easeInOut,
    ));

    _flashAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _captureController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Camera preview placeholder
          _buildCameraPreview(),
          
          // Grid overlay
          if (_showGrid) _buildGridOverlay(),
          
          // Flash effect
          if (_isFlashOn) _buildFlashEffect(),
          
          // Top controls
          _buildTopControls(),
          
          // Bottom controls
          _buildBottomControls(),
          
          // Photo preview (if photo exists)
          if (widget.initialPhoto != null) _buildPhotoPreview(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Camera Preview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              'In a real app, this would show the camera feed',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: GridPainter(),
      ),
    );
  }

  Widget _buildFlashEffect() {
    return AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white.withOpacity(_flashAnimation.value * 0.8),
        );
      },
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
              // Flash toggle
              GestureDetector(
                onTap: _toggleFlash,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              // Grid toggle
              GestureDetector(
                onTap: _toggleGrid,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _showGrid 
                        ? Colors.orange.withOpacity(0.8)
                        : Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.grid_on,
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
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              // Capture button
              GestureDetector(
                onTap: _capturePhoto,
                child: AnimatedBuilder(
                  animation: _captureAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _captureAnimation.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange,
                            width: 4,
                          ),
                        ),
                        child: _isCapturing
                            ? const CircularProgressIndicator(
                                color: Colors.orange,
                                strokeWidth: 3,
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.orange,
                                size: 32,
                              ),
                      ),
                    );
                  },
                ),
              ),
              
              // Camera switch button
              GestureDetector(
                onTap: _switchCamera,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.cameraswitch,
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

  Widget _buildPhotoPreview() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Photo
            Center(
              child: Image.file(
                widget.initialPhoto!,
                fit: BoxFit.contain,
              ),
            ),
            
            // Retake button
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _retakePhoto,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Control methods
  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    
    if (_isFlashOn) {
      _flashController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _flashController.reverse();
        });
      });
    }
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  void _switchCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    _captureController.forward().then((_) {
      _captureController.reverse();
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: _isFrontCamera 
            ? CameraDevice.front 
            : CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final File photo = File(image.path);
        widget.onPhotoCaptured(photo);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture photo: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final File photo = File(image.path);
        widget.onPhotoCaptured(photo);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick photo: $e');
    }
  }

  void _retakePhoto() {
    setState(() {
      // Reset photo state
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

