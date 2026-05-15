import 'package:bookmyservice/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Add this to your pubspec.yaml

class MapAddressSelectorScreen extends StatefulWidget {
  @override
  _MapAddressSelectorScreenState createState() =>
      _MapAddressSelectorScreenState();
}

class _MapAddressSelectorScreenState extends State<MapAddressSelectorScreen> {
  GoogleMapController? mapController;
  LatLng? _pickedLocation;
  TextEditingController _addressController = TextEditingController();
  AddressModel selectedAddress = AddressModel.getDefaultAddress();

  // Initial camera position (e.g., a default city or user's current location)
  static const LatLng _initialCameraPosition =
      LatLng(20.2961, 85.8245); // Bhubaneswar

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    Position? position = await getCurrentPosition();
    if (position != null) {
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
      });

      mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_pickedLocation!, 17));
      _onMapTap(_pickedLocation!); // Trigger address fetch on init
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTap(LatLng latLng) async {
    setState(() {
      _pickedLocation = latLng; // Store the picked coordinates
    });

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        debugPrint("Selected address: ${place.toJson()}");
        String address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
        setState(() {
          _addressController.text = address;
          selectedAddress = AddressModel(
            houseNumber: place.street ?? '',
            areaName: place.subLocality ?? '',
            landmark: '', // You can set a default or leave it empty
            city: place.locality ?? '',
            pinCode: place.postalCode ?? '',
            state: place.administrativeArea ?? '',
            country: place.country ?? '',
          );
        });
      } else {
        setState(() {
          _addressController.text = "No address found for this location.";
        });
      }
    } catch (e) {
      debugPrint("Error during geocoding: $e");
      setState(() {
        _addressController.text = "Error fetching address.";
      });
    }
  }

  void _saveAddress() {
    if (_pickedLocation != null && _addressController.text.isNotEmpty) {
      debugPrint("Address to save:");
      debugPrint(
          "Coordinates: ${_pickedLocation!.latitude}, ${_pickedLocation!.longitude}");
      debugPrint("Formatted Address: ${_addressController.text}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved (simulated)!')),
      );
      Navigator.pop(context, selectedAddress); // Optionally return the address
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a location on the map first.')),
      );
    }
  }

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get current location
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String?> getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name}, ${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
      }
    } catch (e) {
      print("Error in reverse geocoding: $e");
    }

    return null;
  }

  void fetchAndSaveCurrentAddress() async {
    try {
      Position? position = await getCurrentPosition();
      if (position != null) {
        String? address = await getAddressFromCoordinates(position);
        if (address != null) {
          debugPrint("Current Address: $address");
          // Save address to Firestore or your model
        }
      }
    } catch (e) {
      print("Error getting location/address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Address on Map'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _initialCameraPosition,
                zoom: 12.0,
              ),
              onTap: _onMapTap,
              markers: _pickedLocation == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('pickedLocation'),
                        position: _pickedLocation!,
                      ),
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  readOnly: true, // User shouldn't edit this directly
                  decoration: InputDecoration(
                    labelText: 'Selected Address',
                    border: const OutlineInputBorder(),
                    suffix: IconButton(
                      onPressed: _saveAddress,
                      icon: const Icon(
                        Icons.done,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(
                  height: 50,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
