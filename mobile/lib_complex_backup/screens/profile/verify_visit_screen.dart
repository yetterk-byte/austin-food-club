import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';

import '../../providers/app_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/verification/photo_capture_step.dart';
import '../../widgets/verification/photo_editing_step.dart';
import '../../widgets/verification/rating_review_step.dart';
import '../../widgets/verification/confirmation_step.dart';
import '../../widgets/verification/progress_indicator.dart';
import '../../models/restaurant.dart';

class VerifyVisitScreen extends StatefulWidget {
  final String rsvpId;
  final String restaurantName;
  final DateTime visitDate;

  const VerifyVisitScreen({
    super.key,
    required this.rsvpId,
    required this.restaurantName,
    required this.visitDate,
  });

  @override
  State<VerifyVisitScreen> createState() => _VerifyVisitScreenState();
}

class _VerifyVisitScreenState extends State<VerifyVisitScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step data
  File? _capturedPhoto;
  File? _editedPhoto;
  int _rating = 0;
  String _review = '';
  bool _isSubmitting = false;
  bool _hasUnsavedChanges = false;

  // Draft data
  Map<String, dynamic>? _draftData;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _successController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeInOut,
    ));
    
    _loadDraftData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Progress indicator
            VerificationProgressIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              onStepTap: _goToStep,
            ),
            
            // Main content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (step) {
                  setState(() {
                    _currentStep = step;
                  });
                },
                children: [
                  // Step 1: Photo Capture
                  PhotoCaptureStep(
                    onPhotoCaptured: _onPhotoCaptured,
                    initialPhoto: _capturedPhoto,
                  ),
                  
                  // Step 2: Photo Editing
                  PhotoEditingStep(
                    photo: _capturedPhoto,
                    onPhotoEdited: _onPhotoEdited,
                    onSkip: _skipPhotoEditing,
                  ),
                  
                  // Step 3: Rating & Review
                  RatingReviewStep(
                    restaurant: widget.restaurant,
                    initialRating: _rating,
                    initialReview: _review,
                    onRatingChanged: _onRatingChanged,
                    onReviewChanged: _onReviewChanged,
                  ),
                  
                  // Step 4: Confirmation
                  ConfirmationStep(
                    restaurant: widget.restaurant,
                    visitDate: widget.visitDate,
                    photo: _editedPhoto ?? _capturedPhoto,
                    rating: _rating,
                    review: _review,
                    isSubmitting: _isSubmitting,
                    onSubmit: _submitVerification,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: _onBackPressed,
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Text(
        'Verify Visit',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (_hasUnsavedChanges)
          IconButton(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Draft',
          ),
        IconButton(
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline, color: Colors.white),
          tooltip: 'Help',
        ),
      ],
    );
  }

  // Step navigation methods
  void _goToStep(int step) {
    if (step < _currentStep || _canGoToStep(step)) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canGoToStep(int step) {
    switch (step) {
      case 0:
        return true; // Photo capture - always accessible
      case 1:
        return _capturedPhoto != null; // Photo editing - need photo first
      case 2:
        return _capturedPhoto != null; // Rating - need photo first
      case 3:
        return _capturedPhoto != null && _rating > 0; // Confirmation - need photo and rating
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  // Step callbacks
  void _onPhotoCaptured(File photo) {
    setState(() {
      _capturedPhoto = photo;
      _hasUnsavedChanges = true;
    });
    _nextStep();
  }

  void _onPhotoEdited(File editedPhoto) {
    setState(() {
      _editedPhoto = editedPhoto;
      _hasUnsavedChanges = true;
    });
    _nextStep();
  }

  void _skipPhotoEditing() {
    _nextStep();
  }

  void _onRatingChanged(int rating) {
    setState(() {
      _rating = rating;
      _hasUnsavedChanges = true;
    });
  }

  void _onReviewChanged(String review) {
    setState(() {
      _review = review;
      _hasUnsavedChanges = true;
    });
  }

  // Submission
  Future<void> _submitVerification() async {
    if (_capturedPhoto == null || _rating == 0) {
      _showErrorSnackBar('Please complete all required steps');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Upload photo and submit verification
      await userProvider.submitVerification(
        restaurantId: widget.restaurant.id,
        photoUrl: _capturedPhoto!.path, // In real app, upload to server first
        rating: _rating,
        review: _review.isNotEmpty ? _review : null,
        visitDate: widget.visitDate,
      );

      // Show success animation
      await _showSuccessAnimation();
      
      // Clear draft data
      _clearDraftData();
      
      // Navigate back
      Navigator.of(context).pop(true);
      
    } catch (e) {
      _showErrorSnackBar('Failed to submit verification: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Draft functionality
  void _loadDraftData() {
    // Load draft data from local storage
    // This would typically use SharedPreferences or similar
    setState(() {
      _draftData = null; // Implement draft loading
    });
  }

  void _saveDraft() {
    final draftData = {
      'photoPath': _capturedPhoto?.path,
      'editedPhotoPath': _editedPhoto?.path,
      'rating': _rating,
      'review': _review,
      'step': _currentStep,
    };
    
    // Save draft data to local storage
    // This would typically use SharedPreferences or similar
    
    setState(() {
      _hasUnsavedChanges = false;
    });
    
    _showSuccessSnackBar('Draft saved');
  }

  void _clearDraftData() {
    // Clear draft data from local storage
    setState(() {
      _hasUnsavedChanges = false;
      _draftData = null;
    });
  }

  // Navigation handling
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      return await _showExitConfirmation();
    }
    return true;
  }

  void _onBackPressed() {
    if (_currentStep > 0) {
      _previousStep();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Verification'),
        content: const Text(
          'You have unsaved changes. Do you want to save as draft or discard changes?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              _saveDraft();
              Navigator.of(context).pop(true);
            },
            child: const Text('Save Draft'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Success animation
  Future<void> _showSuccessAnimation() async {
    await _successController.forward();
    await Future.delayed(const Duration(seconds: 2));
    await _successController.reverse();
  }

  // Help dialog
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Step 1: Take a photo of your visit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Use the camera to take a photo\n• Switch between front/back camera\n• Use flash if needed'),
              
              SizedBox(height: 16),
              Text(
                'Step 2: Edit your photo (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Crop the photo to your liking\n• Adjust brightness and contrast\n• Add filters if desired'),
              
              SizedBox(height: 16),
              Text(
                'Step 3: Rate and review',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tap stars to rate your experience\n• Write a review (optional)\n• Use suggested prompts for inspiration'),
              
              SizedBox(height: 16),
              Text(
                'Step 4: Confirm and submit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Review your verification details\n• Submit to complete verification\n• Your visit will be added to your profile'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
