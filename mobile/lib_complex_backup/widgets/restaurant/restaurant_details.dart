import 'package:flutter/material.dart';
import '../../models/restaurant.dart';

class RestaurantDetails extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onReadMore;

  const RestaurantDetails({
    super.key,
    required this.restaurant,
    this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Section
          _buildDescriptionSection(context),
          
          const SizedBox(height: 24),
          
          // Specialties Section
          _buildSpecialtiesSection(context),
          
          const SizedBox(height: 24),
          
          // Additional Info
          _buildAdditionalInfo(context),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    final description = restaurant.description ?? 
        'Experience the finest dining in Austin with our carefully crafted menu featuring fresh, locally-sourced ingredients and innovative culinary techniques. Our restaurant offers a warm, inviting atmosphere perfect for any occasion.';
    
    final isLongDescription = description.length > 150;
    final displayText = isLongDescription 
        ? '${description.substring(0, 150)}...'
        : description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          displayText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
        if (isLongDescription) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onReadMore,
            child: Text(
              'Read more',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecialtiesSection(BuildContext context) {
    final specialties = restaurant.specialties ?? [
      'Signature Tacos',
      'Fresh Seafood',
      'Craft Cocktails',
      'Local Ingredients',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialties',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specialties.map((specialty) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Text(
                specialty,
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Price Range
        _buildInfoRow(
          context,
          icon: Icons.attach_money,
          label: 'Price Range',
          value: '\$' * restaurant.price,
        ),
        
        const SizedBox(height: 8),
        
        // Area
        _buildInfoRow(
          context,
          icon: Icons.location_on,
          label: 'Area',
          value: restaurant.area,
        ),
        
        const SizedBox(height: 8),
        
        // Cuisine Type
        if (restaurant.cuisineType != null)
          _buildInfoRow(
            context,
            icon: Icons.restaurant,
            label: 'Cuisine',
            value: restaurant.cuisineType!,
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

