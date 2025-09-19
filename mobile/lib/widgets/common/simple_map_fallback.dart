import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant.dart';

class SimpleMapFallback extends StatelessWidget {
  final Restaurant restaurant;
  final double height;

  const SimpleMapFallback({
    super.key,
    required this.restaurant,
    this.height = 200,
  });

  Future<void> _openInGoogleMaps() async {
    // Create a Google Maps search URL using the restaurant address
    final query = Uri.encodeComponent(restaurant.address);
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
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openInGoogleMaps,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Fallback background color in case CustomPaint doesn't work
            color: const Color(0xFF2A2A2A),
          ),
          child: Stack(
            children: [
              // Background pattern to simulate map
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: MapPatternPainter(),
                    size: Size.infinite,
                  ),
                ),
              ),
              // Simple location marker without text overlay
              Positioned(
                top: height * 0.4,
                right: 60,
                child: Container(
                  padding: const EdgeInsets.all(6),
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
                    size: 18,
                  ),
                ),
              ),
              // Subtle hover indicator
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Much lighter background - like Google Maps light mode
    final bgPaint = Paint()
      ..color = const Color(0xFF4A4A4A) // Much lighter background
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Major highways - very bright like real maps
    final highwayPaint = Paint()
      ..color = const Color(0xFFAAAAAA) // Very light grey - highly visible
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    
    // Horizontal major highways
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      highwayPaint,
    );
    
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      highwayPaint,
    );
    
    // Vertical major highways
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      highwayPaint,
    );
    
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      highwayPaint,
    );

    // Secondary roads - bright and visible
    final roadPaint = Paint()
      ..color = const Color(0xFF888888) // Bright grey for roads
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    // Create a proper street grid
    final horizontalStreets = [0.1, 0.4, 0.5, 0.6, 0.9];
    final verticalStreets = [0.1, 0.4, 0.5, 0.6, 0.9];
    
    for (final y in horizontalStreets) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        roadPaint,
      );
    }
    
    for (final x in verticalStreets) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        roadPaint,
      );
    }

    // Building blocks - much darker for high contrast
    final buildingPaint = Paint()
      ..color = const Color(0xFF1A1A1A) // Very dark buildings
      ..style = PaintingStyle.fill;
    
    // More realistic building layout
    final buildings = [
      // Top row buildings
      Rect.fromLTWH(size.width * 0.02, size.height * 0.02, size.width * 0.06, size.height * 0.06),
      Rect.fromLTWH(size.width * 0.12, size.height * 0.02, size.width * 0.1, size.height * 0.06),
      Rect.fromLTWH(size.width * 0.27, size.height * 0.02, size.width * 0.15, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.45, size.height * 0.02, size.width * 0.12, size.height * 0.06),
      Rect.fromLTWH(size.width * 0.6, size.height * 0.02, size.width * 0.12, size.height * 0.2),
      
      // Middle row buildings  
      Rect.fromLTWH(size.width * 0.02, size.height * 0.27, size.width * 0.2, size.height * 0.15),
      Rect.fromLTWH(size.width * 0.45, size.height * 0.27, size.width * 0.12, size.height * 0.15),
      Rect.fromLTWH(size.width * 0.77, size.height * 0.27, size.width * 0.2, size.height * 0.15),
      
      // Bottom row buildings
      Rect.fromLTWH(size.width * 0.27, size.height * 0.52, size.width * 0.15, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.45, size.height * 0.62, size.width * 0.12, size.height * 0.15),
      Rect.fromLTWH(size.width * 0.6, size.height * 0.52, size.width * 0.12, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.77, size.height * 0.77, size.width * 0.2, size.height * 0.15),
    ];

    for (final building in buildings) {
      canvas.drawRect(building, buildingPaint);
    }

    // Water/park areas - bright green like Google Maps
    final parkPaint = Paint()
      ..color = const Color(0xFF4CAF50) // Bright Material Design green
      ..style = PaintingStyle.fill;
    
    // Park in bottom left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.02, size.height * 0.77, size.width * 0.2, size.height * 0.2),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    
    // Small park in middle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.77, size.height * 0.45, size.width * 0.15, size.height * 0.1),
        const Radius.circular(6),
      ),
      parkPaint,
    );

    // Water feature - blue like real maps
    final waterPaint = Paint()
      ..color = const Color(0xFF2196F3) // Material Design blue
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.02, size.height * 0.45, size.width * 0.2, size.height * 0.08),
        const Radius.circular(4),
      ),
      waterPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
