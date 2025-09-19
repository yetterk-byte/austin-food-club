// Verify Visit Screen Usage Examples
// This file demonstrates how to use the VerifyVisitScreen and its components

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'verify_visit_screen.dart';
import '../../providers/app_provider.dart';
import '../../widgets/verification/progress_indicator.dart';
import '../../widgets/verification/photo_capture_step.dart';
import '../../widgets/verification/photo_editing_step.dart';
import '../../widgets/verification/rating_review_step.dart';
import '../../widgets/verification/confirmation_step.dart';
import '../../models/restaurant.dart';

class VerifyVisitScreenExamples {
  // Example 1: Basic Verify Visit Screen Usage
  static Widget buildBasicExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return VerifyVisitScreen(
      restaurant: restaurant,
      visitDate: DateTime.now(),
    );
  }

  // Example 2: Verify Visit Screen with Custom App Bar
  static Widget buildCustomAppBarExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Visit'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: VerifyVisitScreen(
        restaurant: restaurant,
        visitDate: DateTime.now(),
      ),
    );
  }

  // Example 3: Progress Indicator Widget Usage
  static Widget buildProgressIndicatorExample() {
    return Scaffold(
      body: Column(
        children: [
          VerificationProgressIndicator(
            currentStep: 2,
            totalSteps: 4,
            onStepTap: (step) {
              print('Step tapped: $step');
            },
          ),
          const Expanded(
            child: Center(
              child: Text('Content goes here'),
            ),
          ),
        ],
      ),
    );
  }

  // Example 4: Photo Capture Step Widget Usage
  static Widget buildPhotoCaptureStepExample() {
    return Scaffold(
      body: PhotoCaptureStep(
        onPhotoCaptured: (photo) {
          print('Photo captured: ${photo.path}');
        },
      ),
    );
  }

  // Example 5: Photo Editing Step Widget Usage
  static Widget buildPhotoEditingStepExample() {
    // Mock photo file
    final photo = null; // In real app, this would be a File object

    return Scaffold(
      body: PhotoEditingStep(
        photo: photo,
        onPhotoEdited: (editedPhoto) {
          print('Photo edited: ${editedPhoto.path}');
        },
        onSkip: () {
          print('Photo editing skipped');
        },
      ),
    );
  }

  // Example 6: Rating Review Step Widget Usage
  static Widget buildRatingReviewStepExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      body: RatingReviewStep(
        restaurant: restaurant,
        initialRating: 0,
        initialReview: '',
        onRatingChanged: (rating) {
          print('Rating changed: $rating');
        },
        onReviewChanged: (review) {
          print('Review changed: $review');
        },
      ),
    );
  }

  // Example 7: Confirmation Step Widget Usage
  static Widget buildConfirmationStepExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      body: ConfirmationStep(
        restaurant: restaurant,
        visitDate: DateTime.now(),
        photo: null, // In real app, this would be a File object
        rating: 5,
        review: 'Amazing barbecue! The brisket was perfectly cooked and the service was excellent.',
        isSubmitting: false,
        onSubmit: () {
          print('Verification submitted');
        },
      ),
    );
  }

  // Example 8: Complete Verify Visit Flow with Provider
  static Widget buildCompleteExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Verify Visit Example',
            theme: ThemeData(
              primarySwatch: Colors.orange,
              useMaterial3: true,
            ),
            home: VerifyVisitScreen(
              restaurant: restaurant,
              visitDate: DateTime.now(),
            ),
            builder: (context, child) {
              // Initialize providers when app starts
              WidgetsBinding.instance.addPostFrameCallback((_) {
                appProvider.initialize();
              });
              return child!;
            },
          );
        },
      ),
    );
  }

  // Example 9: Verify Visit Screen with Navigation
  static Widget buildWithNavigationExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Scaffold(
      body: VerifyVisitScreen(
        restaurant: restaurant,
        visitDate: DateTime.now(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Profile tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Current',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Example 10: Verify Visit Screen with Custom Theme
  static Widget buildWithCustomThemeExample() {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return MaterialApp(
      title: 'Verify Visit with Custom Theme',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      home: VerifyVisitScreen(
        restaurant: restaurant,
        visitDate: DateTime.now(),
      ),
    );
  }
}

// Example App
class VerifyVisitScreenExampleApp extends StatelessWidget {
  const VerifyVisitScreenExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final restaurant = Restaurant(
      id: '1',
      name: 'Franklin Barbecue',
      address: '900 E 11th St, Austin, TX 78702',
      area: 'East Austin',
      price: 3,
      weekOf: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return MaterialApp(
      title: 'Verify Visit Screen Examples',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: VerifyVisitScreen(
        restaurant: restaurant,
        visitDate: DateTime.now(),
      ),
    );
  }
}

