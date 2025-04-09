import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:math' as math;
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../widgets/map_widget.dart';
import '../widgets/location_button.dart';
import '../services/map_service.dart';
import '../services/directions_service.dart';
import 'dart:async';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  MapboxMap? _mapboxMap;
  bool _isMapInitialized = false;
  String? _routeId;
  String? _originMarkerId;
  String? _destinationMarkerId;
  String? _driverMarkerId;
  Timer? _locationUpdateTimer;
  double _driverProgress = 0.0;

  // Route data
  Position? _originPosition;
  Position? _destinationPosition;
  String? _fromAddress;
  String? _toAddress;

  // Driver data
  Map<String, dynamic> _driverData = {};
  Position? _driverPosition;
  List<Position> _routeCoordinates = [];
  // Mock ETA data
  int _estimatedTimeInMinutes = 10;
  double _estimatedDistanceInKm = 5.2;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments from navigator
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (args.containsKey('from')) {
        _fromAddress = args['from'];
      }

      if (args.containsKey('to')) {
        _toAddress = args['to'];
      }

      if (args.containsKey('originPosition')) {
        _originPosition = args['originPosition'];
      }

      if (args.containsKey('destinationPosition')) {
        _destinationPosition = args['destinationPosition'];
      }

      if (args.containsKey('driver')) {
        _driverData = args['driver'];
        if (_driverData.containsKey('time')) {
          // Parse time string like "10 min" to get the number
          final timeString = _driverData['time'] as String;
          _estimatedTimeInMinutes =
              int.tryParse(timeString.split(' ')[0]) ?? 10;
        }
      }
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    setState(() {
      _isMapInitialized = true;
    });

    // Draw route if we have both positions
    if (_originPosition != null && _destinationPosition != null) {
      _drawRouteAndMarkers();
      // Start simulating driver movement
      _startDriverSimulation();
    }
  }

  Future<void> _drawRouteAndMarkers() async {
    if (_mapboxMap == null ||
        _originPosition == null ||
        _destinationPosition == null) {
      return;
    }

    try {
      // Add origin marker
      _originMarkerId = await DirectionsService.addMarker(
        _mapboxMap!,
        _originPosition!,
        Colors.green,
        markerId: 'origin-marker',
      );

      // Add destination marker
      _destinationMarkerId = await DirectionsService.addMarker(
        _mapboxMap!,
        _destinationPosition!,
        Colors.red,
        markerId: 'destination-marker',
      );

      // Get route
      final route = await DirectionsService.getRoute(
        _originPosition!,
        _destinationPosition!,
      );

      // Store route coordinates for simulation
      if (route.containsKey('routes') &&
          route['routes'] is List &&
          route['routes'].isNotEmpty) {
        final routeGeometry = route['routes'][0]['geometry'];
        if (routeGeometry != null &&
            routeGeometry['coordinates'] != null &&
            routeGeometry['coordinates'] is List) {
          final coordinates = routeGeometry['coordinates'] as List;
          _routeCoordinates =
              coordinates.map((coord) {
                if (coord is List && coord.length >= 2) {
                  return Position(coord[0], coord[1]);
                }
                return Position(0, 0);
              }).toList();
        }
      }

      // Draw route
      _routeId = await DirectionsService.drawRoute(
        _mapboxMap!,
        route['geometry'],
      );

      // Set initial driver position at the origin
      _driverPosition = _originPosition;

      // Add driver marker
      _driverMarkerId = await DirectionsService.addMarker(
        _mapboxMap!,
        _driverPosition!,
        AppTheme.primaryColor,
      );

      // Fit bounds to show the entire route
      _fitMapToRoute();
    } catch (e) {
      print('Error drawing route and markers: $e');
    }
  }

  void _fitMapToRoute() {
    if (_mapboxMap == null ||
        _originPosition == null ||
        _destinationPosition == null) {
      return;
    }

    try {
      // Calculate center point
      final centerLng = (_originPosition!.lng + _destinationPosition!.lng) / 2;
      final centerLat = (_originPosition!.lat + _destinationPosition!.lat) / 2;

      // Set camera to center point with animation
      _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(centerLng, centerLat)),
          zoom: 12.0,
        ),
      );
    } catch (e) {
      print('Error fitting bounds: $e');
    }
  }

  void _startDriverSimulation() {
    if (_routeCoordinates.isEmpty) {
      return;
    }

    // Calculate how many steps we need for the simulation
    // We'll update every second and want to complete in the estimated time
    final totalSteps = _estimatedTimeInMinutes * 60;
    final stepSize = _routeCoordinates.length / totalSteps;

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _driverProgress += stepSize;

        // Ensure we don't go past the end of the route
        if (_driverProgress >= _routeCoordinates.length - 1) {
          _driverProgress = _routeCoordinates.length - 1;
          timer.cancel();
        }

        // Get the current position along the route
        final index = _driverProgress.floor();
        if (index < _routeCoordinates.length) {
          _driverPosition = _routeCoordinates[index];
          _updateDriverMarker();
        }

        // Update estimated time based on progress
        final progressPercent =
            _driverProgress / (_routeCoordinates.length - 1);
        _estimatedTimeInMinutes =
            (_estimatedTimeInMinutes * (1 - progressPercent)).round();
      });
    });
  }

  Future<void> _updateDriverMarker() async {
    if (_mapboxMap == null ||
        _driverPosition == null ||
        _driverMarkerId == null) {
      return;
    }

    try {
      // Remove the old marker
      await DirectionsService.removeSource(_mapboxMap!, _driverMarkerId!);

      // Add a new marker at the updated position
      _driverMarkerId = await DirectionsService.addMarker(
        _mapboxMap!,
        _driverPosition!,
        AppTheme.primaryColor,
      );
    } catch (e) {
      print('Error updating driver marker: $e');
    }
  }

  void _handleLocationButtonPress() async {
    try {
      if (_mapboxMap != null) {
        await MapService.animateCameraToCurrentLocation(_mapboxMap!);
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _trackDriver() async {
    try {
      if (_mapboxMap != null && _driverPosition != null) {
        _mapboxMap!.setCamera(
          CameraOptions(
            center: Point(coordinates: _driverPosition!),
            zoom: 15.0,
          ),
        );
      }
    } catch (e) {
      print('Error tracking driver: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String arrivalTime = "${_estimatedTimeInMinutes.toString()} mins";

    return Scaffold(
      body: Stack(
        children: [
          // Map background
          RydeMapWidget(showUserLocation: true, onMapCreated: _onMapCreated),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Track Your Ride',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Empty space to center title
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Arrival time badge
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Arriving in ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        arrivalTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Track driver button
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: _trackDriver,
                    icon: const Icon(
                      Icons.location_searching,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Track Driver',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Driver and route info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Driver info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Driver image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/person.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Driver info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _driverData['name'] ?? 'Jane Cooper',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _driverData['rating']?.toString() ??
                                            '4.9',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Text(
                                        ' | ',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        '${_driverData['seats']?.toString() ?? '4'} seats',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Call button
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor,
                                radius: 20,
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Route details
                      // From
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _fromAddress ?? 'From location',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                      ),

                      // To
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _toAddress ?? 'To location',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Back Home button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.home,
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Location button
          if (_isMapInitialized)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.40,
              child: LocationButton(
                mapboxMap: _mapboxMap,
                onLocationButtonPressed: _handleLocationButtonPress,
              ),
            ),
        ],
      ),
    );
  }
}
