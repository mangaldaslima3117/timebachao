import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class AddressMapView extends StatefulWidget {
  final String address;

  const AddressMapView({super.key, required this.address});

  @override
  State<AddressMapView> createState() => _AddressMapViewState();
}

class _AddressMapViewState extends State<AddressMapView> {
  LatLng? targetLocation;
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddress();
  }

  Future<void> _getCoordinatesFromAddress() async {
    try {
      List<Location> locations = await locationFromAddress(widget.address);
      if (locations.isNotEmpty) {
        setState(() {
          targetLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error converting address: $e');
    }
  }

  void _openInGoogleMaps(LatLng location) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch Google Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: targetLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: targetLocation!,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('addressMarker'),
                  position: targetLocation!,
                  infoWindow: InfoWindow(title: widget.address),
                )
              },
            ),
      floatingActionButton: targetLocation == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openInGoogleMaps(targetLocation!),
              label: const Text('Open in Maps'),
              icon: const Icon(Icons.map),
            ),
    );
  }
}
