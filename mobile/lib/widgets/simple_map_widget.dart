import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// The following imports are only used on web. They are ignored on other platforms.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// Web-only registry for HTML views
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui;

class SimpleMapWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? address;

  const SimpleMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.address,
  });

  // Default to Austin, TX coordinates if not provided
  static const double _defaultLat = 30.2672;
  static const double _defaultLng = -97.7431;

  void _openMap(BuildContext context) {
    final lat = latitude ?? _defaultLat;
    final lng = longitude ?? _defaultLng;
    
    // Create Google Maps URL
    final mapUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    
    // Show dialog with map information
    _showMapDialog(context, mapUrl, lat, lng);
  }

  void _showMapDialog(BuildContext context, String mapUrl, double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open in Maps'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${address ?? "Restaurant Location"}'),
            const SizedBox(height: 8),
            Text('Coordinates: $lat, $lng'),
            const SizedBox(height: 16),
            const Text(
              'Click the button below to open this location in Google Maps:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                mapUrl,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Map URL copied to clipboard!'),
                      const SizedBox(height: 4),
                      Text(
                        'URL: $mapUrl',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = latitude ?? _defaultLat;
    final lng = longitude ?? _defaultLng;
    
    // On web, render an embedded Google Map iframe (no API key required for basic embed)
    if (kIsWeb) {
      final viewId = 'map-iframe-$lat-$lng-${address ?? ''}';
      final embedUrl = 'https://www.google.com/maps?q=$lat,$lng&z=15&output=embed';
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(viewId, (int _) {
        final element = html.IFrameElement()
          ..src = embedUrl
          ..style.border = '0'
          ..allowFullscreen = false
          ..allow = 'geolocation'
          ..width = '100%'
          ..height = '100%';
        return element;
      });

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            children: [
              HtmlElementView(viewType: viewId),
              Positioned(
                bottom: 8,
                right: 8,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => _openMap(context),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open in Maps'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback (non-web) - tap-to-open placeholder
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade100,
            Colors.green.shade100,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openMap(context),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.blue.shade600),
                  const SizedBox(height: 8),
                  Text('Tap to open in Maps', style: TextStyle(color: Colors.blue.shade700, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
