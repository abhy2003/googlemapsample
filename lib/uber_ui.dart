import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LocationData? _currentLocation;
  Marker? _currentLocationMarker;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _currentLocation = await location.getLocation();
    if (_currentLocation != null) {
      _updateCurrentLocationMarker();
      _animateCameraToCurrentLocation();
    }

    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentLocation = currentLocation;
        _updateCurrentLocationMarker();
      });
      _animateCameraToCurrentLocation();
    });
  }

  Future<void> _animateCameraToCurrentLocation() async {
    if (_currentLocation != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 19.0,
          ),
        ),
      );
    }
  }

  void _updateCurrentLocationMarker() {
    if (_currentLocation != null) {
      final marker = Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'My Location'),
      );

      setState(() {
        _currentLocationMarker = marker;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
            trafficEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 50.0,
            left: 15.0,
            right: 15.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Where to?",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Ride Options", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(Icons.local_taxi, color: Colors.black),
                    ],
                  ),
                  SizedBox(height: 15.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRideOption(Icons.local_taxi, "UberX", "\$12"),
                      _buildRideOption(Icons.car_rental, "UberXL", "\$18"),
                      _buildRideOption(Icons.sports_motorsports, "UberBLACK", "\$25"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _animateCameraToCurrentLocation,
        label: const Text('To my location!'),
        icon: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildRideOption(IconData icon, String name, String price) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.black),
        SizedBox(height: 5),
        Text(name, style: TextStyle(fontSize: 14)),
        Text(price, style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
