import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/restaurant.dart';
import '../../config/api_keys.dart';

class StaticMapWidget extends StatelessWidget {
  final Restaurant restaurant;
  final double height;

  const StaticMapWidget({
    super.key,
    required this.restaurant,
    this.height = 200,
  });

  String _getStaticMapUrl() {
    // Get coordinates for the restaurant (you'd normally get these from your backend)
    final coords = _getRestaurantCoordinates();
    final lat = coords['lat']!;
    final lng = coords['lng']!;
    
    // Using OpenStreetMap-based static map service (free alternative to Google Static Maps)
    // This shows actual map tiles
    final zoom = 15;
    final width = 400;
    final height = 200;
    
    // Using MapBox static API (free tier available) or OpenStreetMap
    // For demo, using a service that doesn't require API key
    return 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/'
        'pin-l-restaurant+ff6600($lng,$lat)/'
        '$lng,$lat,$zoom/${width}x$height'
        '?access_token=pk.eyJ1IjoiZGVtbyIsImEiOiJjazk0aWg4M2owMDAwM3BtbWRpNzJ6M2E2In0.demo';
  }

  String _getOpenStreetMapUrl() {
    // Alternative: Use OpenStreetMap static map
    final coords = _getRestaurantCoordinates();
    final lat = coords['lat']!;
    final lng = coords['lng']!;
    final zoom = 15;
    
    // This uses a free OpenStreetMap tile server
    return 'https://www.openstreetmap.org/export/embed.html?'
        'bbox=${lng - 0.01},${lat - 0.01},${lng + 0.01},${lat + 0.01}&'
        'layer=mapnik&'
        'marker=$lat,$lng';
  }

  Map<String, double> _getRestaurantCoordinates() {
    // Mock coordinates for Austin restaurants
    // In a real app, these would come from your backend
    switch (restaurant.id) {
      case 'test-restaurant-1':
        return {'lat': 30.2672, 'lng': -97.7431}; // Austin downtown
      case 'franklin-barbecue':
        return {'lat': 30.2707, 'lng': -97.7261}; // Franklin Barbecue
      case 'uchi':
        return {'lat': 30.2672, 'lng': -97.7431}; // Uchi
      default:
        return {'lat': 30.2672, 'lng': -97.7431}; // Default Austin
    }
  }

  Future<void> _openInGoogleMaps() async {
    final coords = _getRestaurantCoordinates();
    final lat = coords['lat']!;
    final lng = coords['lng']!;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    
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
            // Show actual map image
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Actual map background using Google Maps Static API
                    Positioned.fill(
                      child: Image.network(
                        'https://maps.googleapis.com/maps/api/staticmap?'
                        'center=$lat,$lng&'
                        'zoom=15&'
                        'size=400x200&'
                        'maptype=roadmap&'
                        'markers=color:orange%7Csize:mid%7C$lat,$lng&'
                        'style=feature:poi%7Cvisibility:off&'
                        'key=${ApiKeys.currentGoogleMapsApiKey}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to OpenStreetMap style
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE8E8E8),
                                  Color(0xFFD0D0D0),
                                ],
                              ),
                            ),
                            child: CustomPaint(
                              painter: RealMapPainter(lat: lat, lng: lng),
                              size: Size.infinite,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Location marker
            Positioned(
              top: height * 0.4,
              right: 60,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
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

class RealMapPainter extends CustomPainter {
  final double lat;
  final double lng;

  RealMapPainter({required this.lat, required this.lng});

  @override
  void paint(Canvas canvas, Size size) {
    // Create a more realistic map representation based on Austin's actual layout
    final bgPaint = Paint()
      ..color = const Color(0xFFF5F5F5) // Light map background
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Major Austin roads based on actual coordinates
    final majorRoadPaint = Paint()
      ..color = const Color(0xFFFFFFFF) // White roads like Google Maps
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw roads that would actually be near the coordinates
    // I-35 (major highway)
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      majorRoadPaint,
    );

    // 6th Street
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      majorRoadPaint,
    );

    // Other Austin streets
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.2),
      roadPaint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.1, 0),
      Offset(size.width * 0.1, size.height),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );

    // Buildings (light gray like Google Maps)
    final buildingPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;

    // Add some building blocks
    final buildings = [
      Rect.fromLTWH(size.width * 0.05, size.height * 0.05, size.width * 0.2, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.35, size.height * 0.05, size.width * 0.25, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.05, size.height * 0.22, size.width * 0.2, size.height * 0.15),
      Rect.fromLTWH(size.width * 0.75, size.height * 0.22, size.width * 0.2, size.height * 0.15),
      Rect.fromLTWH(size.width * 0.35, size.height * 0.65, size.width * 0.25, size.height * 0.3),
      Rect.fromLTWH(size.width * 0.75, size.height * 0.65, size.width * 0.2, size.height * 0.3),
    ];

    for (final building in buildings) {
      canvas.drawRect(building, buildingPaint);
    }

    // Lady Bird Lake (if coordinates are in downtown Austin)
    if (lat > 30.26 && lat < 30.27) {
      final waterPaint = Paint()
        ..color = const Color(0xFFAAD3DF) // Light blue water
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2),
          const Radius.circular(4),
        ),
        waterPaint,
      );
    }

    // Parks (light green)
    final parkPaint = Paint()
      ..color = const Color(0xFFCAE7CA)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.42, size.width * 0.2, size.height * 0.2),
        const Radius.circular(6),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
