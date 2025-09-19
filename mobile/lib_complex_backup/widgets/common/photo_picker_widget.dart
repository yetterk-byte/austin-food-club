import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/photo_service.dart';

class PhotoPickerWidget extends StatefulWidget {
  final Function(File) onPhotoSelected;
  final String? initialImagePath;
  final bool showWatermark;
  final String? watermarkText;
  final double? width;
  final double? height;

  const PhotoPickerWidget({
    super.key,
    required this.onPhotoSelected,
    this.initialImagePath,
    this.showWatermark = false,
    this.watermarkText,
    this.width,
    this.height,
  });

  @override
  State<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends State<PhotoPickerWidget> {
  final PhotoService _photoService = PhotoService();
  File? _selectedImage;
  bool _isProcessing = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _selectedImage = File(widget.initialImagePath!);
    }
    _photoService.uploadProgress.listen((progress) {
      setState(() {
        _uploadProgress = progress;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _selectedImage == null
          ? _buildEmptyState()
          : _buildImagePreview(),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Add Photo',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onTap: _takePicture,
            ),
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: _pickFromGallery,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (_isProcessing)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploadProgress > 0 ? 'Uploading...' : 'Processing...',
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_uploadProgress > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _cropImage,
                icon: const Icon(Icons.crop, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _removeImage,
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final image = await _photoService.takePicture();
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take picture: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final image = await _photoService.pickFromGallery();
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick from gallery: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processImage(File image) async {
    try {
      // Fix orientation
      final orientedImage = await _photoService.fixImageOrientation(image);
      
      // Compress image
      final compressedImage = await _photoService.compressImage(orientedImage, quality: 80);
      
      // Add watermark if requested
      File finalImage = compressedImage;
      if (widget.showWatermark && widget.watermarkText != null) {
        finalImage = await _photoService.addWatermark(
          compressedImage,
          text: widget.watermarkText,
        );
      }

      setState(() {
        _selectedImage = finalImage;
      });

      widget.onPhotoSelected(finalImage);
    } catch (e) {
      _showErrorSnackBar('Failed to process image: $e');
    }
  }

  Future<void> _cropImage() async {
    if (_selectedImage == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final croppedImage = await _photoService.cropImage(_selectedImage!);
      
      setState(() {
        _selectedImage = croppedImage;
      });

      widget.onPhotoSelected(croppedImage);
    } catch (e) {
      _showErrorSnackBar('Failed to crop image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _photoService.dispose();
    super.dispose();
  }
}

