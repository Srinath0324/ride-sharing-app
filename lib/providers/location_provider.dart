import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/location_permission_service.dart';
import '../services/map_service.dart';
import '../services/places_service.dart';

/// Provider for handling location-related state and functions
class LocationProvider extends ChangeNotifier {
  geo.Position? _currentPosition;
  String? _currentAddress;
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = false;
  bool _isLoadingLocation = false;

  // Getters
  geo.Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get isLoadingLocation => _isLoadingLocation;

  // Constructor initializes state
  LocationProvider() {
    _checkLocationPermission();
  }

  // Initialize location services and check permission status
  Future<void> _checkLocationPermission() async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      // Check if location services are enabled
      _isLocationServiceEnabled =
          await LocationPermissionService.isLocationServiceEnabled();

      // Check if we have permission
      _hasLocationPermission =
          await LocationPermissionService.hasLocationPermission();

      // Set the permission status in MapService
      MapService.setLocationPermissionStatus(_hasLocationPermission);

      // If we have permission and services are enabled, get current location
      if (_hasLocationPermission && _isLocationServiceEnabled) {
        await _updateCurrentLocation();
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission(BuildContext context) async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      final bool result =
          await LocationPermissionService.checkAndRequestLocationPermission(
            context,
          );
      _hasLocationPermission = result;

      // Set the permission status in MapService
      MapService.setLocationPermissionStatus(_hasLocationPermission);

      // If we got permission, update location
      if (_hasLocationPermission) {
        await _updateCurrentLocation();
      }

      return result;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Update current location and address
  Future<void> _updateCurrentLocation() async {
    if (!_hasLocationPermission || !_isLocationServiceEnabled) {
      return;
    }

    _isLoadingLocation = true;
    notifyListeners();

    try {
      // Get current location
      final position = await geo.Geolocator.getCurrentPosition();
      _currentPosition = position;

      // Get address from geocoding
      final addressData = await PlacesService.getCurrentLocationAddress();
      _currentAddress = addressData['placeName'];
    } catch (e) {
      debugPrint('Error updating current location: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Manually refresh current location
  Future<void> refreshLocation() async {
    if (_isLoadingLocation) {
      return; // Prevent multiple concurrent requests
    }

    await _updateCurrentLocation();
  }

  // Get coordinates as a MapBox Position object
  Position? get currentMapPosition {
    if (_currentPosition == null) {
      return null;
    }

    return Position(_currentPosition!.longitude, _currentPosition!.latitude);
  }
}
