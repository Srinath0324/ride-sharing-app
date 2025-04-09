import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../widgets/location_button.dart';
import '../widgets/map_widget.dart';
import '../services/map_service.dart';
import '../services/geocoding_service.dart';
import '../services/directions_service.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({Key? key}) : super(key: key);

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  MapboxMap? _mapboxMap;
  bool _isMapInitialized = false;
  String? _originMarkerId;
  String? _destinationMarkerId;
  String? _routeId;
  bool _isLoadingRoute = false;

  // Location data
  Position? _originPosition;
  Position? _destinationPosition;

  @override
  void initState() {
    super.initState();
    // Will be populated in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments from navigator
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('currentLocation')) {
      final currentLocation = args['currentLocation'];
      if (currentLocation != null && _fromController.text.isEmpty) {
        setState(() {
          _fromController.text = currentLocation;
        });
      }
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    setState(() {
      _isMapInitialized = true;
    });
  }

  Future<void> _setCurrentLocationAsFrom() async {
    try {
      // Get current location
      final position = await MapService.getCurrentLocation();

      // Get address from geocoding service
      final result = await GeocodingService.reverseGeocode(
        position.longitude,
        position.latitude,
      );

      // Update text field and position
      setState(() {
        _fromController.text = result['placeName'];
        _originPosition = Position(position.longitude, position.latitude);
      });

      // Add marker if map is initialized
      if (_isMapInitialized && _mapboxMap != null) {
        // Remove old marker if exists
        if (_originMarkerId != null) {
          await DirectionsService.removeSource(_mapboxMap!, _originMarkerId!);
        }

        // Add new marker
        _originMarkerId = await DirectionsService.addMarker(
          _mapboxMap!,
          _originPosition!,
          Colors.green,
          markerId: 'origin-marker',
        );

        // If we have destination, draw route
        if (_destinationPosition != null) {
          _drawRoute();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _processAddress(String query, bool isOrigin) async {
    if (query.isEmpty) return;

    try {
      // Get coordinates from geocoding service
      final result = await GeocodingService.geocode(query);
      final position = result['coordinates'] as Position;

      setState(() {
        if (isOrigin) {
          _originPosition = position;
        } else {
          _destinationPosition = position;
        }
      });

      // Add marker if map is initialized
      if (_isMapInitialized && _mapboxMap != null) {
        if (isOrigin) {
          // Remove old marker if exists
          if (_originMarkerId != null) {
            await DirectionsService.removeSource(_mapboxMap!, _originMarkerId!);
          }

          // Add new marker
          _originMarkerId = await DirectionsService.addMarker(
            _mapboxMap!,
            position,
            Colors.green,
            markerId: 'origin-marker',
          );
        } else {
          // Remove old marker if exists
          if (_destinationMarkerId != null) {
            await DirectionsService.removeSource(
              _mapboxMap!,
              _destinationMarkerId!,
            );
          }

          // Add new marker
          _destinationMarkerId = await DirectionsService.addMarker(
            _mapboxMap!,
            position,
            Colors.red,
            markerId: 'destination-marker',
          );
        }

        // If we have both origin and destination, draw route
        if (_originPosition != null && _destinationPosition != null) {
          _drawRoute();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not geocode address: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _drawRoute() async {
    if (_mapboxMap == null ||
        _originPosition == null ||
        _destinationPosition == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Get route
      final route = await DirectionsService.getRoute(
        _originPosition!,
        _destinationPosition!,
      );

      // Remove old route if exists
      if (_routeId != null) {
        await DirectionsService.removeSource(_mapboxMap!, _routeId!);
      }

      // Draw new route
      _routeId = await DirectionsService.drawRoute(
        _mapboxMap!,
        route['geometry'],
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get route: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _handleLocationButtonPress() {
    // Just call the current location function
    _setCurrentLocationAsFrom();
  }

  @override
  Widget build(BuildContext context) {
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
                            'Ride',
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

                const Spacer(),

                // From/To inputs container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // From field
                      Row(
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Location button
                          GestureDetector(
                            onTap: _setCurrentLocationAsFrom,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _fromController,
                                decoration: const InputDecoration(
                                  hintText: 'From location',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onSubmitted:
                                    (value) => _processAddress(value, true),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // To field
                      Row(
                        children: [
                          const Text(
                            'To',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Map button
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.map,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _toController,
                                decoration: const InputDecoration(
                                  hintText: 'To location',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onSubmitted:
                                    (value) => _processAddress(value, false),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Find now button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              _isLoadingRoute
                                  ? null
                                  : () {
                                    if (_fromController.text.isNotEmpty &&
                                        _toController.text.isNotEmpty) {
                                      // First process addresses if not already done
                                      if (_originPosition == null) {
                                        _processAddress(
                                          _fromController.text,
                                          true,
                                        );
                                      }

                                      if (_destinationPosition == null) {
                                        _processAddress(
                                          _toController.text,
                                          false,
                                        );
                                      }

                                      // Navigate to next screen
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.rideAvailableCars,
                                        arguments: {
                                          'from': _fromController.text,
                                          'to': _toController.text,
                                          'originPosition': _originPosition,
                                          'destinationPosition':
                                              _destinationPosition,
                                        },
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter both locations',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child:
                              _isLoadingRoute
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Find Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
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
              bottom: MediaQuery.of(context).size.height * 0.35 + 16,
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
