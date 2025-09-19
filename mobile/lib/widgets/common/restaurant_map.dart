import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant.dart';
import 'simple_map_fallback.dart';

class RestaurantMap extends StatefulWidget {
  final Restaurant restaurant;
  final double height;

  const RestaurantMap({
    super.key,
    required this.restaurant,
    this.height = 200,
  });

  @override
  State<RestaurantMap> createState() => _RestaurantMapState();
}

class _RestaurantMapState extends State<RestaurantMap> {
  GoogleMapController? _controller;
  late LatLng _restaurantLocation;
  Set<Marker> _markers = {};
  bool _mapLoadError = false;

  @override
  void initState() {
    super.initState();
    // For demo purposes, using Austin coordinates
    // In a real app, you'd geocode the address or store lat/lng
    _restaurantLocation = _getRestaurantCoordinates();
    _markers = {
      Marker(
        markerId: MarkerId(widget.restaurant.id),
        position: _restaurantLocation,
        infoWindow: InfoWindow(
          title: widget.restaurant.name,
          snippet: widget.restaurant.address,
        ),
        onTap: () => _openInGoogleMaps(),
      ),
    };
  }

  LatLng _getRestaurantCoordinates() {
    // Mock coordinates for Austin restaurants
    // In a real app, these would come from your backend or geocoding service
    switch (widget.restaurant.id) {
      case 'test-restaurant-1':
        return const LatLng(30.2672, -97.7431); // Austin downtown
      case 'franklin-barbecue':
        return const LatLng(30.2707, -97.7261); // Franklin Barbecue actual location
      case 'uchi':
        return const LatLng(30.2672, -97.7431); // Uchi actual location
      default:
        return const LatLng(30.2672, -97.7431); // Default Austin coordinates
    }
  }

  Future<void> _openInGoogleMaps() async {
    final lat = _restaurantLocation.latitude;
    final lng = _restaurantLocation.longitude;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    
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
    // For web, always use fallback since Google Maps API requires additional setup
    // For mobile, you can configure Google Maps properly
    if (kIsWeb || _mapLoadError) {
      return SimpleMapFallback(
        restaurant: widget.restaurant,
        height: widget.height,
      );
    }

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
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _restaurantLocation,
                zoom: 15.0,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              onTap: (_) => _openInGoogleMaps(),
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapType: MapType.normal,
            ),
            // Overlay with restaurant info and tap indicator
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.restaurant.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Tap to open in Google Maps',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.launch,
                            size: 12,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
