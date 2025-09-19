import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

class PhotoEditingStep extends StatefulWidget {
  final File? photo;
  final Function(File) onPhotoEdited;
  final VoidCallback onSkip;

  const PhotoEditingStep({
    super.key,
    required this.photo,
    required this.onPhotoEdited,
    required this.onSkip,
  });

  @override
  State<PhotoEditingStep> createState() => _PhotoEditingStepState();
}

class _PhotoEditingStepState extends State<PhotoEditingStep>
    with TickerProviderStateMixin {
  late AnimationController _brightnessController;
  late AnimationController _contrastController;
  late Animation<double> _brightnessAnimation;
  late Animation<double> _contrastAnimation;

  double _brightness = 0.0;
  double _contrast = 1.0;
  double _rotation = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _brightnessController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _contrastController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _brightnessAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _brightnessController,
      curve: Curves.easeInOut,
    ));

    _contrastAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contrastController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _brightnessController.dispose();
    _contrastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photo == null) {
      return _buildNoPhotoState();
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Photo preview
          Expanded(
            child: _buildPhotoPreview(),
          ),
          
          // Editing controls
          _buildEditingControls(),
        ],
      ),
    );
  }

  Widget _buildNoPhotoState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Photo to Edit',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please take a photo first',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onSkip,
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Photo with filters
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_brightnessAnimation, _contrastAnimation]),
              builder: (context, child) {
                return ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    _contrast, 0, 0, 0, _brightness * 255,
                    0, _contrast, 0, 0, _brightness * 255,
                    0, 0, _contrast, 0, _brightness * 255,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Transform.rotate(
                    angle: _rotation * 3.14159 / 180,
                    child: Image.file(
                      widget.photo!,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditingControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brightness control
          _buildBrightnessControl(),
          
          const SizedBox(height: 16),
          
          // Contrast control
          _buildContrastControl(),
          
          const SizedBox(height: 16),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildBrightnessControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.brightness_6, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Brightness',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              '${(_brightness * 100).round()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        Slider(
          value: _brightness,
          min: -1.0,
          max: 1.0,
          divisions: 100,
          activeColor: Colors.orange,
          inactiveColor: Colors.grey.shade600,
          onChanged: (value) {
            setState(() {
              _brightness = value;
            });
            _brightnessController.forward().then((_) {
              _brightnessController.reverse();
            });
          },
        ),
      ],
    );
  }

  Widget _buildContrastControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.contrast, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Contrast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              '${(_contrast * 100).round()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        Slider(
          value: _contrast,
          min: 0.0,
          max: 2.0,
          divisions: 100,
          activeColor: Colors.orange,
          inactiveColor: Colors.grey.shade600,
          onChanged: (value) {
            setState(() {
              _contrast = value;
            });
            _contrastController.forward().then((_) {
              _contrastController.reverse();
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Rotate button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _rotatePhoto,
            icon: const Icon(Icons.rotate_90_degrees_cw),
            label: const Text('Rotate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Crop button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _cropPhoto,
            icon: const Icon(Icons.crop),
            label: const Text('Crop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Skip button
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onSkip,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Text('Skip'),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Done button
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _applyEdits,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Done'),
          ),
        ),
      ],
    );
  }

  // Editing methods
  void _rotatePhoto() {
    setState(() {
      _rotation = (_rotation + 90) % 360;
    });
  }

  Future<void> _cropPhoto() async {
    if (widget.photo == null) return;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.photo!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Colors.orange,
            cropFrameColor: Colors.orange,
            cropGridColor: Colors.orange.withOpacity(0.5),
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            minimumAspectRatio: 1.0,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        widget.onPhotoEdited(File(croppedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to crop photo: $e');
    }
  }

  Future<void> _applyEdits() async {
    if (widget.photo == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // In a real app, you would apply the brightness, contrast, and rotation
      // to the actual image file here
      // For now, we'll just pass the original photo
      await Future.delayed(const Duration(seconds: 1)); // Simulate processing
      
      widget.onPhotoEdited(widget.photo!);
    } catch (e) {
      _showErrorSnackBar('Failed to apply edits: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
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

