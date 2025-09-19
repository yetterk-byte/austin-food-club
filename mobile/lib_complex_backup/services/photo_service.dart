import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../config/constants.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  final StreamController<double> _uploadProgressController = StreamController<double>.broadcast();
  
  // Cache management
  Directory? _cacheDirectory;
  final Map<String, String> _cacheMap = {};

  Stream<double> get uploadProgress => _uploadProgressController.stream;

  // Initialize photo service
  Future<void> initialize() async {
    await _initializeCache();
  }

  Future<void> _initializeCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory(path.join(appDir.path, 'photo_cache'));
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      print('Error initializing photo cache: $e');
    }
  }

  // Camera/Gallery Access
  Future<File?> takePicture() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      throw Exception('Failed to take picture: $e');
    }
  }

  Future<File?> pickFromGallery() async {
    try {
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) {
        throw Exception('Gallery permission denied');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick from gallery: $e');
    }
  }

  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  Future<bool> requestGalleryPermission() async {
    try {
      final status = await Permission.photos.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting gallery permission: $e');
      return false;
    }
  }

  // Image Processing
  Future<File> compressImage(File image, {int quality = 70}) async {
    try {
      final bytes = await image.readAsBytes();
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: 800,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) {
        throw Exception('Failed to compress image');
      }

      // Create temporary file for compressed image
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  Future<File> cropImage(File image) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square crop
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

      if (croppedFile == null) {
        throw Exception('Image cropping cancelled');
      }

      return File(croppedFile.path);
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }

  Future<String> convertToBase64(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  Future<File> fixImageOrientation(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final imageData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      
      if (imageData == null) {
        throw Exception('Failed to process image orientation');
      }

      // Create new file with corrected orientation
      final tempDir = await getTemporaryDirectory();
      final correctedFile = File(path.join(
        tempDir.path,
        'corrected_${DateTime.now().millisecondsSinceEpoch}.png',
      ));

      await correctedFile.writeAsBytes(imageData.buffer.asUint8List());
      return correctedFile;
    } catch (e) {
      // If orientation fix fails, return original file
      print('Warning: Could not fix image orientation: $e');
      return image;
    }
  }

  // Upload Functionality
  Future<String> uploadToSupabase(File image, String path) async {
    try {
      _uploadProgressController.add(0.1);

      final bytes = await image.readAsBytes();
      final fileName = _generateUniqueFileName(image.path);
      final fullPath = '$path/$fileName';

      _uploadProgressController.add(0.3);

      final response = await _supabase.storage
          .from('photos')
          .uploadBinary(fullPath, bytes);

      _uploadProgressController.add(0.8);

      final publicUrl = _supabase.storage
          .from('photos')
          .getPublicUrl(fullPath);

      _uploadProgressController.add(1.0);

      // Cache the uploaded image
      await _cacheImage(image, publicUrl);

      return publicUrl;
    } catch (e) {
      _uploadProgressController.add(0.0);
      throw Exception('Failed to upload to Supabase: $e');
    }
  }

  Future<String> uploadToServer(File image, String endpoint) async {
    try {
      _uploadProgressController.add(0.1);

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      _uploadProgressController.add(0.3);

      final response = await _supabase.functions.invoke(
        'upload-photo',
        body: {
          'image': base64Image,
          'endpoint': endpoint,
        },
      );

      _uploadProgressController.add(0.8);

      if (response.data == null || response.data['url'] == null) {
        throw Exception('Invalid response from server');
      }

      final photoUrl = response.data['url'] as String;
      
      _uploadProgressController.add(1.0);

      // Cache the uploaded image
      await _cacheImage(image, photoUrl);

      return photoUrl;
    } catch (e) {
      _uploadProgressController.add(0.0);
      throw Exception('Failed to upload to server: $e');
    }
  }

  // Image Caching
  Future<void> _cacheImage(File image, String url) async {
    try {
      if (_cacheDirectory == null) return;

      final cacheKey = _generateCacheKey(url);
      final cachedFile = File(path.join(_cacheDirectory!.path, cacheKey));
      
      await image.copy(cachedFile.path);
      _cacheMap[url] = cachedFile.path;
    } catch (e) {
      print('Error caching image: $e');
    }
  }

  Future<File?> getCachedImage(String url) async {
    try {
      if (_cacheDirectory == null) return null;

      final cacheKey = _generateCacheKey(url);
      final cachedFile = File(path.join(_cacheDirectory!.path, cacheKey));
      
      if (await cachedFile.exists()) {
        return cachedFile;
      }
    } catch (e) {
      print('Error getting cached image: $e');
    }
    return null;
  }

  Future<void> clearCache() async {
    try {
      if (_cacheDirectory == null) return;

      if (await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      }
      
      _cacheMap.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      if (_cacheDirectory == null) return 0;

      int totalSize = 0;
      await for (final entity in _cacheDirectory!.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('Error calculating cache size: $e');
      return 0;
    }
  }

  String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Watermark for Verified Visits
  Future<File> addWatermark(File image, {String? text}) async {
    try {
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the original image
      canvas.drawImage(uiImage, Offset.zero, Paint());

      // Add watermark text
      if (text != null && text.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Position watermark in bottom right
        final x = uiImage.width - textPainter.width - 20;
        final y = uiImage.height - textPainter.height - 20;

        textPainter.paint(canvas, Offset(x, y));
      }

      // Convert to image
      final picture = recorder.endRecording();
      final watermarkedImage = await picture.toImage(uiImage.width, uiImage.height);
      final byteData = await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to create watermarked image');
      }

      // Save watermarked image
      final tempDir = await getTemporaryDirectory();
      final watermarkedFile = File(path.join(
        tempDir.path,
        'watermarked_${DateTime.now().millisecondsSinceEpoch}.png',
      ));

      await watermarkedFile.writeAsBytes(byteData.buffer.asUint8List());
      return watermarkedFile;
    } catch (e) {
      print('Warning: Could not add watermark: $e');
      return image; // Return original if watermarking fails
    }
  }

  // Utility Methods
  String _generateUniqueFileName(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalPath);
    return '${timestamp}_${_generateHash(originalPath)}$extension';
  }

  String _generateCacheKey(String url) {
    return _generateHash(url);
  }

  String _generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // Cleanup
  void dispose() {
    _uploadProgressController.close();
  }
}