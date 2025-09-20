import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class InteractiveMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String restaurantName;
  final String address;

  const InteractiveMapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.restaurantName,
    required this.address,
  }) : super(key: key);

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  late GoogleMapController mapController;
  late final LatLng restaurantLocation;
  late final Set<Marker> markers;

  @override
  void initState() {
    super.initState();
    restaurantLocation = LatLng(widget.latitude, widget.longitude);
    markers = {
      Marker(
        markerId: MarkerId('restaurant'),
        position: restaurantLocation,
        infoWindow: InfoWindow(
          title: widget.restaurantName,
          snippet: widget.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Optional: Apply custom map style for dark theme
    // controller.setMapStyle('''[{"elementType": "geometry", "stylers": [{"color": "#242f3e"}]}]''');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildMapWidget(),
    );
  }

  Widget _buildMapWidget() {
    try {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: restaurantLocation,
          zoom: 15.0,
        ),
        markers: markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: true,
        compassEnabled: true,
        mapType: MapType.normal,
      );
    } catch (e) {
      // Fallback when Google Maps fails to load
      return _buildMapFallback();
    }
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
            Icons.map,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            widget.restaurantName,
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
              widget.address,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Open in Google Maps app/web
              final query = Uri.encodeComponent('${widget.restaurantName}, ${widget.address}');
              final url = 'https://www.google.com/maps/search/?api=1&query=$query';
              print('Opening Google Maps: $url');
              // TODO: Add url_launcher to open the URL
            },
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
}
