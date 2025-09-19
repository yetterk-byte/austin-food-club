import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/photo_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/photo_picker_widget.dart';

class PhotoVerificationScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final DateTime visitDate;

  const PhotoVerificationScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.visitDate,
  });

  @override
  State<PhotoVerificationScreen> createState() => _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState extends State<PhotoVerificationScreen> {
  final PhotoService _photoService = PhotoService();
  final AuthService _authService = AuthService();
  
  File? _selectedPhoto;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _photoService.uploadProgress.listen((progress) {
      setState(() {
        _uploadProgress = progress;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Visit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurantName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visit Date: ${_formatDate(widget.visitDate)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Photo Upload Section
            Text(
              'Upload a photo of your visit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Photo Picker
            Center(
              child: PhotoPickerWidget(
                onPhotoSelected: _onPhotoSelected,
                showWatermark: true,
                watermarkText: 'Verified Visit',
                width: 300,
                height: 300,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Upload Progress
            if (_isUploading) ...[
              Text(
                'Uploading photo...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 16),
            ],
            
            // Uploaded Photo URL
            if (_uploadedPhotoUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Photo uploaded successfully!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const Spacer(),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isUploading ? null : _uploadPhoto,
                    child: const Text('Upload Photo'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _uploadedPhotoUrl != null ? _submitVerification : null,
                    child: const Text('Submit Verification'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onPhotoSelected(File photo) {
    setState(() {
      _selectedPhoto = photo;
      _uploadedPhotoUrl = null;
    });
  }

  Future<void> _uploadPhoto() async {
    if (_selectedPhoto == null) return;

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload to Supabase
      final photoUrl = await _photoService.uploadToSupabase(
        _selectedPhoto!,
        'verified-visits/${widget.restaurantId}',
      );

      setState(() {
        _uploadedPhotoUrl = photoUrl;
        _isUploading = false;
      });

      _showSuccessSnackBar('Photo uploaded successfully!');
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Failed to upload photo: $e');
    }
  }

  Future<void> _submitVerification() async {
    if (_uploadedPhotoUrl == null) return;

    try {
      // Here you would typically submit the verification to your backend
      // For now, we'll just show a success message
      _showSuccessSnackBar('Visit verification submitted!');
      
      // Navigate back or to next screen
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Failed to submit verification: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _photoService.dispose();
    super.dispose();
  }
}

