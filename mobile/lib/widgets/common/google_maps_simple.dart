import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant.dart';
import '../../config/api_keys.dart';

class GoogleMapsSimple extends StatelessWidget {
  final Restaurant restaurant;
  final double height;

  const GoogleMapsSimple({
    super.key,
    required this.restaurant,
    this.height = 200,
  });

  Map<String, double> _getRestaurantCoordinates() {
    // Precise coordinates for Austin restaurants
    switch (restaurant.id) {
      case 'test-restaurant-1':
        // Suerte - 1800 E 6th St, Austin, TX 78702 (more precise coordinates)
        return {'lat': 30.2658, 'lng': -97.7235}; // Suerte precise location
      case 'franklin-barbecue':
        return {'lat': 30.2707, 'lng': -97.7261}; // Franklin Barbecue
      case 'uchi':
        return {'lat': 30.2649, 'lng': -97.7430}; // Uchi actual location
      default:
        return {'lat': 30.2672, 'lng': -97.7431}; // Default Austin downtown
    }
  }

  Future<void> _openInGoogleMaps() async {
    final coords = _getRestaurantCoordinates();
    final lat = coords['lat']!;
    final lng = coords['lng']!;
    
    // Use restaurant name and address for more accurate search
    final query = Uri.encodeComponent('${restaurant.name} ${restaurant.address}');
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coords = _getRestaurantCoordinates();
    final lat = coords['lat']!;
    final lng = coords['lng']!;
    
    // Create Google Maps Static API URL using address for better accuracy
    final encodedAddress = Uri.encodeComponent(restaurant.address);
    final mapUrl = 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$encodedAddress&'
        'zoom=16&'
        'size=400x200&'
        'maptype=roadmap&'
        'markers=color:orange%7Csize:mid%7C$encodedAddress&'
        'style=feature:poi%7Cvisibility:simplified&'
        'key=${ApiKeys.currentGoogleMapsApiKey}';

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Google Maps Static Image
            Positioned.fill(
              child: Image.network(
                mapUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.orange),
                          SizedBox(height: 16),
                          Text('Loading map...'),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Google Maps Static API Error: $error');
                  // Show error message and fallback
                  return Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Enable Maps Static API',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Go to Google Cloud Console\nand enable Maps Static API',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Open Google Maps',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Clickable overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openInGoogleMaps,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Open indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.launch,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Open',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
