import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReliableMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String restaurantName;
  final String address;

  const ReliableMapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.restaurantName,
    required this.address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Google Maps Static API for reliable display
    final staticMapUrl = _buildStaticMapUrl();
    
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Static map image
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              staticMapUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[900],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.orange,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildMapFallback();
              },
            ),
          ),
          // Restaurant name overlay (top)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    restaurantName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tap to open overlay (bottom)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openInGoogleMaps,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.open_in_new,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Open in Maps',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildStaticMapUrl() {
    const apiKey = 'AIzaSyA6pcXA40sTWfiNL5lWA-pZZJsFJv0f5xQ';
    final encodedAddress = Uri.encodeComponent(address);
    
    // Use address-based positioning for maximum accuracy
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$encodedAddress&'
        'zoom=16&'
        'size=600x300&'
        'scale=2&'
        'maptype=roadmap&'
        'markers=color:red%7Csize:large%7Clabel:S%7C$encodedAddress&'
        'style=feature:poi%7Cvisibility:simplified&'
        'style=feature:poi.business%7Cvisibility:off&'
        'style=feature:transit%7Cvisibility:off&'
        'key=$apiKey';
  }

  Widget _buildMapFallback() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            restaurantName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              address,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openInGoogleMaps,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in Google Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _openInGoogleMaps() async {
    final query = Uri.encodeComponent('$restaurantName, $address');
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
    }
  }
}
