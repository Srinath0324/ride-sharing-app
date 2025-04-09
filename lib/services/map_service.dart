import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

class MapService {
  static final MapService _instance = MapService._internal();
  static String? _accessToken;
  static String? _styleUrl;

  factory MapService() {
    return _instance;
  }

  MapService._internal();

  static Future<void> initialize() async {
    _accessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    _styleUrl = dotenv.env['MAPBOX_STYLE_URL'];

    // Initialize MapBox options with access token
    if (_accessToken != null) {
      try {
        // Using setAccessToken if it's available
        MapboxOptions.setAccessToken(_accessToken!);
      } catch (e) {
        print('Warning: Could not set Mapbox access token: $e');
        print('Using fallback method to configure MapBox token...');
      }
    } else {
      throw Exception('MapBox access token not found in .env file');
    }
  }

  static String? get styleUrl => _styleUrl;

  static String? get accessToken => _accessToken;

  // Request location permission and return position
  static Future<geo.Position> getCurrentLocation() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return Future.error('Location services are disabled.');
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        // Permissions are denied
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can continue
    return await geo.Geolocator.getCurrentPosition();
  }

  // Get camera options centered on current location
  static Future<CameraOptions> getInitialCameraOptions() async {
    try {
      geo.Position position = await getCurrentLocation();
      return CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 15.0,
      );
    } catch (e) {
      // Default to a central location in case of error
      return CameraOptions(
        center: Point(
          coordinates: Position(77.63, 22.55), // Default center of India
        ),
        zoom: 5.0,
      );
    }
  }

  // Set up enhanced location puck on the map
  static void setupLocationPuck(MapboxMap mapboxMap) {
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        showAccuracyRing: true,
        accuracyRingColor: Colors.blue.withOpacity(0.2).value,
        accuracyRingBorderColor: Colors.blue.value,
        pulsingEnabled: true,
        pulsingColor: Colors.blue.value,
        pulsingMaxRadius: 100,
        locationPuck: LocationPuck(
          locationPuck2D: LocationPuck2D(
            topImage: null, // Using default
            bearingImage: null, // Using default
            shadowImage: null, // Using default
            scaleExpression:
                [
                  'interpolate',
                  ['linear'],
                  ['zoom'],
                  0,
                  0.6,
                  20,
                  1.0,
                ].toString(),
          ),
        ),
      ),
    );
  }

  // Move camera to current location
  static Future<void> animateCameraToCurrentLocation(
    MapboxMap mapboxMap,
  ) async {
    try {
      final position = await getCurrentLocation();

      final cameraOptions = CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 16.0,
        bearing: 0,
        pitch: 0,
      );

      mapboxMap.flyTo(
        cameraOptions,
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (e) {
      print('Error moving camera to current location: $e');
    }
  }

  // Convert a LatLng to Point for MapBox
  static Map<String, dynamic> latLngToPoint(double lat, double lng) {
    return Point(coordinates: Position(lng, lat)).toJson();
  }
}
