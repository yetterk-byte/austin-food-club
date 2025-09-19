import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../models/restaurant.dart';
import '../../utils/helpers.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final Map<String, int>? rsvpCounts;
  final Function(String dayOfWeek, String status)? onRsvpChanged;
  final bool isCompact;
  final VoidCallback? onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.rsvpCounts,
    this.onRsvpChanged,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Restaurant image
            _buildImage(),
            
            // Restaurant content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: AppTheme.restaurantNameStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        _buildRating(),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Cuisine and price
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.cuisine,
                          style: AppTheme.cuisineStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        restaurant.priceSymbols,
                        style: AppTheme.priceStyle,
                      ),
                    ],
                  ),
                  
                  if (!isCompact) ...[
                    const SizedBox(height: 8),
                    
                    // Address
                    Text(
                      restaurant.address,
                      style: AppTheme.addressStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      restaurant.shortDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (restaurant.hasHighlights) ...[
                      const SizedBox(height: 12),
                      _buildHighlights(),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // RSVP section
                    if (onRsvpChanged != null && rsvpCounts != null)
                      _buildRsvpSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: restaurant.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.surfaceColor,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppTheme.surfaceColor,
          child: const Center(
            child: Icon(
              Icons.restaurant,
              size: 48,
              color: AppTheme.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRating() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 16,
            color: AppTheme.ratingColor,
          ),
          const SizedBox(width: 4),
          Text(
            restaurant.ratingDisplay,
            style: AppTheme.ratingStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: restaurant.topHighlights.map((highlight) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            highlight,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRsvpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'See You There',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildDayButtons(),
        const SizedBox(height: 8),
        Text(
          'RSVP to one day per restaurant',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDayButtons() {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final count = rsvpCounts?[day] ?? 0;
        return _buildDayButton(day, count);
      }).toList(),
    );
  }

  Widget _buildDayButton(String day, int count) {
    final dayName = Helpers.capitalizeFirst(day);
    
    return InkWell(
      onTap: () => onRsvpChanged?.call(day, 'going'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.textTertiary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName.substring(0, 3),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

