// Common Widgets Usage Examples
// This file demonstrates how to use all the common widgets

import 'package:flutter/material.dart';
import 'custom_button.dart';
import 'restaurant_card.dart';
import 'star_rating.dart';
import 'loading_shimmer.dart';
import 'error_view.dart';
import 'custom_text_field.dart';
import 'photo_viewer.dart';
import '../../models/restaurant.dart';

class CommonWidgetsExample extends StatefulWidget {
  const CommonWidgetsExample({super.key});

  @override
  State<CommonWidgetsExample> createState() => _CommonWidgetsExampleState();
}

class _CommonWidgetsExampleState extends State<CommonWidgetsExample> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Common Widgets Examples'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Buttons Section
            _buildSectionTitle('Custom Buttons'),
            _buildCustomButtonsSection(),
            
            const SizedBox(height: 32),
            
            // Restaurant Cards Section
            _buildSectionTitle('Restaurant Cards'),
            _buildRestaurantCardsSection(),
            
            const SizedBox(height: 32),
            
            // Star Rating Section
            _buildSectionTitle('Star Ratings'),
            _buildStarRatingSection(),
            
            const SizedBox(height: 32),
            
            // Loading Shimmer Section
            _buildSectionTitle('Loading Shimmer'),
            _buildLoadingShimmerSection(),
            
            const SizedBox(height: 32),
            
            // Error Views Section
            _buildSectionTitle('Error Views'),
            _buildErrorViewsSection(),
            
            const SizedBox(height: 32),
            
            // Custom Text Fields Section
            _buildSectionTitle('Custom Text Fields'),
            _buildCustomTextFieldsSection(),
            
            const SizedBox(height: 32),
            
            // Photo Viewer Section
            _buildSectionTitle('Photo Viewer'),
            _buildPhotoViewerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  // Custom Buttons Section
  Widget _buildCustomButtonsSection() {
    return Column(
      children: [
        // Button sizes
        Row(
          children: [
            CustomButtonVariants.primary(
              text: 'Small',
              size: ButtonSize.small,
              onPressed: () => _showSnackBar('Small button pressed'),
            ),
            const SizedBox(width: 8),
            CustomButtonVariants.primary(
              text: 'Medium',
              size: ButtonSize.medium,
              onPressed: () => _showSnackBar('Medium button pressed'),
            ),
            const SizedBox(width: 8),
            CustomButtonVariants.primary(
              text: 'Large',
              size: ButtonSize.large,
              onPressed: () => _showSnackBar('Large button pressed'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Button types
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CustomButtonVariants.primary(
              text: 'Primary',
              onPressed: () => _showSnackBar('Primary pressed'),
            ),
            CustomButtonVariants.secondary(
              text: 'Secondary',
              onPressed: () => _showSnackBar('Secondary pressed'),
            ),
            CustomButtonVariants.outline(
              text: 'Outline',
              onPressed: () => _showSnackBar('Outline pressed'),
            ),
            CustomButtonVariants.text(
              text: 'Text',
              onPressed: () => _showSnackBar('Text pressed'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Button with icon
        CustomButton(
          text: 'With Icon',
          icon: Icons.favorite,
          onPressed: () => _showSnackBar('Icon button pressed'),
        ),
        
        const SizedBox(height: 16),
        
        // Loading button
        CustomButton(
          text: 'Loading',
          isLoading: true,
          onPressed: null,
        ),
        
        const SizedBox(height: 16),
        
        // Gradient button
        CustomButtonVariants.gradient(
          text: 'Gradient',
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: () => _showSnackBar('Gradient button pressed'),
        ),
      ],
    );
  }

  // Restaurant Cards Section
  Widget _buildRestaurantCardsSection() {
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

    return Column(
      children: [
        // Compact card
        RestaurantCardVariants.compact(
          restaurant: restaurant,
          onTap: () => _showSnackBar('Compact card tapped'),
          onWishlistToggle: () => _showSnackBar('Wishlist toggled'),
        ),
        
        const SizedBox(height: 16),
        
        // Featured card
        RestaurantCardVariants.featured(
          restaurant: restaurant,
          onTap: () => _showSnackBar('Featured card tapped'),
          onWishlistToggle: () => _showSnackBar('Wishlist toggled'),
        ),
        
        const SizedBox(height: 16),
        
        // Grid card
        RestaurantCardVariants.grid(
          restaurant: restaurant,
          onTap: () => _showSnackBar('Grid card tapped'),
          onWishlistToggle: () => _showSnackBar('Wishlist toggled'),
        ),
      ],
    );
  }

  // Star Rating Section
  Widget _buildStarRatingSection() {
    return Column(
      children: [
        // Small rating
        StarRatingVariants.small(
          rating: 4.5,
          readOnly: true,
        ),
        
        const SizedBox(height: 16),
        
        // Medium rating
        StarRatingVariants.medium(
          rating: 4.5,
          readOnly: true,
        ),
        
        const SizedBox(height: 16),
        
        // Large rating
        StarRatingVariants.large(
          rating: 4.5,
          readOnly: true,
        ),
        
        const SizedBox(height: 16),
        
        // Interactive rating
        StarRatingVariants.interactive(
          rating: 0,
          onRatingChanged: (rating) => _showSnackBar('Rating: $rating'),
        ),
        
        const SizedBox(height: 16),
        
        // Rating with text
        StarRatingVariants.withText(
          rating: 4.5,
          text: '4.5 (123 reviews)',
        ),
      ],
    );
  }

  // Loading Shimmer Section
  Widget _buildLoadingShimmerSection() {
    return Column(
      children: [
        // Text shimmer
        ShimmerContainer(
          child: ShimmerSkeleton.text(width: 200, height: 20),
        ),
        
        const SizedBox(height: 16),
        
        // Circle shimmer
        ShimmerContainer(
          child: ShimmerSkeleton.circle(size: 60),
        ),
        
        const SizedBox(height: 16),
        
        // Rectangle shimmer
        ShimmerContainer(
          child: ShimmerSkeleton.rectangle(
            width: 200,
            height: 100,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Card shimmer
        ShimmerContainer(
          child: ShimmerSkeleton.card(
            width: 200,
            height: 150,
          ),
        ),
      ],
    );
  }

  // Error Views Section
  Widget _buildErrorViewsSection() {
    return Column(
      children: [
        // Network error
        ErrorViewVariants.network(
          onRetry: () => _showSnackBar('Retry network'),
        ),
        
        const SizedBox(height: 16),
        
        // Server error
        ErrorViewVariants.server(
          onRetry: () => _showSnackBar('Retry server'),
        ),
        
        const SizedBox(height: 16),
        
        // Custom error
        ErrorViewVariants.custom(
          title: 'Custom Error',
          message: 'This is a custom error message',
          icon: Icons.warning,
          onRetry: () => _showSnackBar('Retry custom'),
        ),
      ],
    );
  }

  // Custom Text Fields Section
  Widget _buildCustomTextFieldsSection() {
    return Column(
      children: [
        // Email field
        CustomTextFieldVariants.email(
          controller: _emailController,
          onChanged: (value) => print('Email: $value'),
        ),
        
        const SizedBox(height: 16),
        
        // Password field
        CustomTextFieldVariants.password(
          controller: _passwordController,
          onChanged: (value) => print('Password: $value'),
        ),
        
        const SizedBox(height: 16),
        
        // Phone field
        CustomTextFieldVariants.phone(
          controller: _phoneController,
          onChanged: (value) => print('Phone: $value'),
        ),
        
        const SizedBox(height: 16),
        
        // Search field
        CustomTextFieldVariants.search(
          controller: _searchController,
          onChanged: (value) => print('Search: $value'),
          onClear: () => _searchController.clear(),
        ),
        
        const SizedBox(height: 16),
        
        // Multiline field
        CustomTextFieldVariants.multiline(
          label: 'Message',
          hint: 'Enter your message here...',
          maxLength: 500,
          onChanged: (value) => print('Message: $value'),
        ),
      ],
    );
  }

  // Photo Viewer Section
  Widget _buildPhotoViewerSection() {
    return Column(
      children: [
        // Photo viewer button
        CustomButton(
          text: 'Open Photo Viewer',
          icon: Icons.photo,
          onPressed: () => _openPhotoViewer(),
        ),
        
        const SizedBox(height: 16),
        
        // Photo grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openPhotoViewer(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Helper methods
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _openPhotoViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewerVariants.simple(
          imageUrl: 'https://picsum.photos/800/600',
          heroTag: 'photo_1',
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

// Individual widget examples
class CustomButtonExample extends StatelessWidget {
  const CustomButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Button Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Basic usage
            CustomButton(
              text: 'Basic Button',
              onPressed: () => print('Pressed'),
            ),
            
            const SizedBox(height: 16),
            
            // With icon
            CustomButton(
              text: 'With Icon',
              icon: Icons.favorite,
              onPressed: () => print('Pressed'),
            ),
            
            const SizedBox(height: 16),
            
            // Loading state
            CustomButton(
              text: 'Loading',
              isLoading: true,
              onPressed: null,
            ),
            
            const SizedBox(height: 16),
            
            // Disabled state
            CustomButton(
              text: 'Disabled',
              isDisabled: true,
              onPressed: () => print('Pressed'),
            ),
            
            const SizedBox(height: 16),
            
            // Gradient
            CustomButton(
              text: 'Gradient',
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue],
              ),
              onPressed: () => print('Pressed'),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantCardExample extends StatelessWidget {
  const RestaurantCardExample({super.key});

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

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Card Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Basic card
            RestaurantCard(
              restaurant: restaurant,
              onTap: () => print('Tapped'),
              onWishlistToggle: () => print('Wishlist toggled'),
            ),
            
            const SizedBox(height: 16),
            
            // Card without wishlist button
            RestaurantCard(
              restaurant: restaurant,
              onTap: () => print('Tapped'),
              showWishlistButton: false,
            ),
            
            const SizedBox(height: 16),
            
            // Card without rating
            RestaurantCard(
              restaurant: restaurant,
              onTap: () => print('Tapped'),
              showRating: false,
            ),
          ],
        ),
      ),
    );
  }
}

class StarRatingExample extends StatefulWidget {
  const StarRatingExample({super.key});

  @override
  State<StarRatingExample> createState() => _StarRatingExampleState();
}

class _StarRatingExampleState extends State<StarRatingExample> {
  double _rating = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Star Rating Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Interactive rating
            StarRating(
              rating: _rating,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Display rating
            StarRating(
              rating: 4.5,
              readOnly: true,
            ),
            
            const SizedBox(height: 16),
            
            // Half star rating
            StarRating(
              rating: 3.5,
              allowHalfStars: true,
              readOnly: true,
            ),
            
            const SizedBox(height: 16),
            
            // Custom colors
            StarRating(
              rating: 4.0,
              readOnly: true,
              filledColor: Colors.purple,
              emptyColor: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

