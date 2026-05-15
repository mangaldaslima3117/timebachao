import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveTrackingMap extends StatefulWidget {
  final String bookingId;
  final LatLng destination; // Customer location

  const LiveTrackingMap({
    super.key,
    required this.bookingId,
    required this.destination,
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  GoogleMapController? mapController;
  LatLng? maidLocation;
  Set<Polyline> polylines = {};

  void _fitMarkers(LatLng maid, LatLng destination) {
    LatLngBounds bounds;

    // Calculate bounds based on coordinates
    double southWestLat = maid.latitude < destination.latitude
        ? maid.latitude
        : destination.latitude;
    double southWestLng = maid.longitude < destination.longitude
        ? maid.longitude
        : destination.longitude;
    double northEastLat = maid.latitude > destination.latitude
        ? maid.latitude
        : destination.latitude;
    double northEastLng = maid.longitude > destination.longitude
        ? maid.longitude
        : destination.longitude;

    bounds = LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80), // 80px padding around edges
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("liveTracking")
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Waiting for location..."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          maidLocation = LatLng(data["latitude"], data["longitude"]);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updatePolyline();
          });

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: maidLocation!,
              zoom: 14, // Initial zoom can be normal, will adjust dynamically
            ),
            onMapCreated: (controller) {
              mapController = controller;

              Future.delayed(const Duration(milliseconds: 500), () {
                _fitMarkers(maidLocation!, widget.destination);
              });
            },
            markers: {
              Marker(
                markerId: const MarkerId("maid"),
                position: maidLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'Maid'),
              ),
              Marker(
                markerId: const MarkerId("destination"),
                position: widget.destination,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
                infoWindow: const InfoWindow(title: 'You'),
              ),
            },
            polylines: polylines,
            myLocationButtonEnabled: false,
          );
        },
      ),
    );
  }

  void _updatePolyline() {
    if (maidLocation == null) return;

    final route = Polyline(
      polylineId: const PolylineId("route"),
      color: Colors.orange,
      width: 3,
      points: [
        maidLocation!,
        widget.destination,
      ],
    );

    setState(() {
      polylines = {route};
    });
  }
}
