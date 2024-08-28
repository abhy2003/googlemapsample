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
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
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

    // To keep track of the location in real-time
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
      print('Current Location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');

      final marker = Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'My Location'),
      );

      setState(() {
        _currentLocationMarker = marker;
      });

      // Force rebuild the map to ensure the marker is displayed
      setState(() {});
    } else {
      print('Current location is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition,
        markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
        trafficEnabled: true, // Enable traffic layer
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _animateCameraToCurrentLocation,
        label: const Text('To my location!'),
        icon: const Icon(Icons.my_location),
      ),
    );
  }
}
