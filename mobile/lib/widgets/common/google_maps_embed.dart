import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import '../../models/restaurant.dart';

class GoogleMapsEmbed extends StatefulWidget {
  final Restaurant restaurant;
  final double height;

  const GoogleMapsEmbed({
    super.key,
    required this.restaurant,
    this.height = 200,
  });

  @override
  State<GoogleMapsEmbed> createState() => _GoogleMapsEmbedState();
}

class _GoogleMapsEmbedState extends State<GoogleMapsEmbed> {
  late String viewId;
  
  @override
  void initState() {
    super.initState();
    viewId = 'google-maps-${widget.restaurant.id}';
    _createMapIframe();
  }

  void _createMapIframe() {
    // Create the iframe element for Google Maps
    final mapUrl = _buildMapUrl();
    
    final iframe = html.IFrameElement()
      ..src = mapUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = '12px';

    // Register the iframe with the platform view
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) => iframe,
    );
  }

  String _buildMapUrl() {
    // Use Google Maps embed API (no API key required for basic embeds)
    final address = Uri.encodeComponent(widget.restaurant.address);
    final restaurantName = Uri.encodeComponent(widget.restaurant.name);
    
    // Google Maps embed URL - this works without API key for basic functionality
    return 'https://www.google.com/maps/embed/v1/place?key=&q=$address&zoom=15&maptype=roadmap';
  }

  String _buildStaticMapUrl() {
    // Fallback: Google Static Maps API URL
    // This would need an API key for production, but shows the concept
    final address = Uri.encodeComponent(widget.restaurant.address);
    final width = 400;
    final height = 200;
    final zoom = 15;
    
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$address&'
        'zoom=$zoom&'
        'size=${width}x$height&'
        'maptype=roadmap&'
        'markers=color:orange%7C$address&'
        'key=YOUR_API_KEY_HERE';
  }

  Future<void> _openInGoogleMaps() async {
    final address = Uri.encodeComponent(widget.restaurant.address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$address';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
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
            // Try to show actual Google Maps embed
            Positioned.fill(
              child: HtmlElementView(
                viewType: viewId,
              ),
            ),
            // Clickable overlay to open in Google Maps
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
            // Small indicator that it's clickable
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
