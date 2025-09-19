// Photo Service Usage Examples
// This file demonstrates how to use the PhotoService class

import 'dart:io';
import 'package:flutter/material.dart';
import 'photo_service.dart';

class PhotoServiceExamples {
  final PhotoService _photoService = PhotoService();

  // Example 1: Basic Camera Access
  Future<void> takePictureExample() async {
    try {
      // Request camera permission
      final hasPermission = await _photoService.requestCameraPermission();
      if (!hasPermission) {
        print('Camera permission denied');
        return;
      }

      // Take picture
      final File? image = await _photoService.takePicture();
      if (image != null) {
        print('Picture taken: ${image.path}');
        // Process the image...
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  // Example 2: Gallery Access
  Future<void> pickFromGalleryExample() async {
    try {
      // Request gallery permission
      final hasPermission = await _photoService.requestGalleryPermission();
      if (!hasPermission) {
        print('Gallery permission denied');
        return;
      }

      // Pick from gallery
      final File? image = await _photoService.pickFromGallery();
      if (image != null) {
        print('Image selected: ${image.path}');
        // Process the image...
      }
    } catch (e) {
      print('Error picking from gallery: $e');
    }
  }

  // Example 3: Image Processing Pipeline
  Future<File?> processImageExample(File originalImage) async {
    try {
      // Step 1: Fix orientation
      final orientedImage = await _photoService.fixImageOrientation(originalImage);
      print('Orientation fixed');

      // Step 2: Compress image
      final compressedImage = await _photoService.compressImage(
        orientedImage,
        quality: 80, // 80% quality
      );
      print('Image compressed');

      // Step 3: Crop image (optional)
      final croppedImage = await _photoService.cropImage(compressedImage);
      print('Image cropped');

      // Step 4: Add watermark (optional)
      final watermarkedImage = await _photoService.addWatermark(
        croppedImage,
        text: 'Verified Visit',
      );
      print('Watermark added');

      return watermarkedImage;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  // Example 4: Upload to Supabase
  Future<String?> uploadToSupabaseExample(File image) async {
    try {
      // Listen to upload progress
      _photoService.uploadProgress.listen((progress) {
        print('Upload progress: ${(progress * 100).toInt()}%');
      });

      // Upload to Supabase
      final photoUrl = await _photoService.uploadToSupabase(
        image,
        'verified-visits/restaurant-123', // Path in Supabase storage
      );

      print('Photo uploaded: $photoUrl');
      return photoUrl;
    } catch (e) {
      print('Error uploading to Supabase: $e');
      return null;
    }
  }

  // Example 5: Upload to Server
  Future<String?> uploadToServerExample(File image) async {
    try {
      // Listen to upload progress
      _photoService.uploadProgress.listen((progress) {
        print('Upload progress: ${(progress * 100).toInt()}%');
      });

      // Upload to server
      final photoUrl = await _photoService.uploadToServer(
        image,
        '/api/upload-photo', // Server endpoint
      );

      print('Photo uploaded: $photoUrl');
      return photoUrl;
    } catch (e) {
      print('Error uploading to server: $e');
      return null;
    }
  }

  // Example 6: Convert to Base64
  Future<String?> convertToBase64Example(File image) async {
    try {
      final base64String = await _photoService.convertToBase64(image);
      print('Base64 string length: ${base64String.length}');
      return base64String;
    } catch (e) {
      print('Error converting to base64: $e');
      return null;
    }
  }

  // Example 7: Cache Management
  Future<void> cacheManagementExample() async {
    try {
      // Get cache size
      final cacheSize = await _photoService.getCacheSize();
      final formattedSize = _photoService.formatCacheSize(cacheSize);
      print('Cache size: $formattedSize');

      // Get cached image
      final cachedImage = await _photoService.getCachedImage(
        'https://example.com/photo.jpg',
      );
      if (cachedImage != null) {
        print('Cached image found: ${cachedImage.path}');
      } else {
        print('No cached image found');
      }

      // Clear cache
      await _photoService.clearCache();
      print('Cache cleared');
    } catch (e) {
      print('Error managing cache: $e');
    }
  }

  // Example 8: Complete Verification Flow
  Future<void> completeVerificationFlowExample() async {
    try {
      // Step 1: Take or pick photo
      final File? originalImage = await _photoService.takePicture();
      if (originalImage == null) return;

      // Step 2: Process image
      final processedImage = await processImageExample(originalImage);
      if (processedImage == null) return;

      // Step 3: Upload to Supabase
      final photoUrl = await uploadToSupabaseExample(processedImage);
      if (photoUrl == null) return;

      // Step 4: Convert to base64 for API submission
      final base64Image = await convertToBase64Example(processedImage);
      if (base64Image == null) return;

      // Step 5: Submit verification data to your API
      // await submitVerificationData(photoUrl, base64Image);

      print('Verification flow completed successfully!');
    } catch (e) {
      print('Error in verification flow: $e');
    }
  }

  // Example 9: Widget Integration
  Widget buildPhotoPickerExample() {
    return PhotoPickerWidget(
      onPhotoSelected: (File photo) {
        print('Photo selected: ${photo.path}');
        // Handle photo selection
      },
      showWatermark: true,
      watermarkText: 'Verified Visit',
      width: 200,
      height: 200,
    );
  }

  // Example 10: Permission Handling
  Future<void> permissionHandlingExample() async {
    // Check camera permission
    final cameraPermission = await _photoService.requestCameraPermission();
    print('Camera permission: $cameraPermission');

    // Check gallery permission
    final galleryPermission = await _photoService.requestGalleryPermission();
    print('Gallery permission: $galleryPermission');

    // If permissions are denied, show dialog
    if (!cameraPermission || !galleryPermission) {
      // Show permission dialog
      print('Please grant camera and gallery permissions');
    }
  }

  // Example 11: Error Handling
  Future<void> errorHandlingExample() async {
    try {
      final image = await _photoService.takePicture();
      if (image != null) {
        // Process image
        final compressed = await _photoService.compressImage(image);
        final uploaded = await _photoService.uploadToSupabase(compressed, 'test');
        print('Success: $uploaded');
      }
    } on PermissionException catch (e) {
      print('Permission error: ${e.message}');
      // Handle permission error
    } on CameraException catch (e) {
      print('Camera error: ${e.description}');
      // Handle camera error
    } on Exception catch (e) {
      print('General error: $e');
      // Handle general error
    }
  }

  // Example 12: Batch Processing
  Future<void> batchProcessingExample(List<File> images) async {
    try {
      final List<String> uploadedUrls = [];

      for (int i = 0; i < images.length; i++) {
        print('Processing image ${i + 1}/${images.length}');
        
        // Process each image
        final compressed = await _photoService.compressImage(images[i]);
        final watermarked = await _photoService.addWatermark(
          compressed,
          text: 'Batch ${i + 1}',
        );
        
        // Upload each image
        final url = await _photoService.uploadToSupabase(
          watermarked,
          'batch/${DateTime.now().millisecondsSinceEpoch}_$i',
        );
        
        uploadedUrls.add(url);
      }

      print('Batch processing completed: ${uploadedUrls.length} images uploaded');
    } catch (e) {
      print('Error in batch processing: $e');
    }
  }

  // Cleanup
  void dispose() {
    _photoService.dispose();
  }
}

// Custom Exceptions for better error handling
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
}

class CameraException implements Exception {
  final String description;
  CameraException(this.description);
}

